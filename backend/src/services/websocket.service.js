/**
 * WebSocket Service
 * Realtime price push via 'ws' package
 *
 * Flow:
 *  1. Client connects → sends JWT in first message for auth
 *  2. Client subscribes to symbols → server starts polling KIS
 *  3. Server polls KIS at interval (30s free / 10s pro)
 *  4. Server pushes price_update messages to subscribed clients
 *  5. Server broadcasts market_status (OPEN/CLOSED)
 *
 * Optimizations:
 *  - Group subscriptions → batch KIS API calls (300ms throttle)
 *  - Only poll during market hours (09:00-15:30 KST Mon-Fri)
 *  - If market CLOSED → poll every 5 minutes (for after-hours changes)
 *  - Deduplicate: one KIS call per symbol regardless of subscriber count
 */
import { WebSocketServer } from 'ws';
import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import kisService from './kis.service.js';
import env from '../config/env.js';
import { getMarketStatus } from '../utils/helpers.js';
import logger from '../utils/logger.js';

// ─── Constants ───────────────────────────────────────
const POLL_INTERVAL_FREE = 30_000;  // 30s for free users
const POLL_INTERVAL_PRO = 10_000;   // 10s for pro users
const POLL_INTERVAL_CLOSED = 5 * 60_000; // 5min when market closed
const MARKET_STATUS_INTERVAL = 60_000;   // Check market status every 60s
const MAX_SUBSCRIPTIONS_FREE = 5;
const MAX_SUBSCRIPTIONS_PRO = 20;
const HEARTBEAT_INTERVAL = 30_000;  // Ping every 30s to detect dead connections
const AUTH_TIMEOUT = 10_000;        // 10s to authenticate after connecting

// ─── State ───────────────────────────────────────────
/** @type {WebSocketServer} */
let wss = null;

/** Map<ws, ClientState> */
const clients = new Map();

/** Map<string, { price data }> — latest price per symbol */
const latestPrices = new Map();

/** Set<string> — all symbols currently subscribed across all clients */
function getAllSubscribedSymbols() {
  const symbols = new Set();
  for (const state of clients.values()) {
    if (state.authenticated) {
      for (const sym of state.subscriptions) {
        symbols.add(sym);
      }
    }
  }
  return symbols;
}

// ─── Client State ────────────────────────────────────
/**
 * @typedef {Object} ClientState
 * @property {boolean} authenticated
 * @property {Object|null} user
 * @property {Set<string>} subscriptions
 * @property {string} plan
 * @property {boolean} alive - for heartbeat
 * @property {NodeJS.Timeout|null} authTimer
 */
function createClientState() {
  return {
    authenticated: false,
    user: null,
    subscriptions: new Set(),
    plan: 'free',
    alive: true,
    authTimer: null,
  };
}

// ─── Helpers ─────────────────────────────────────────

/** Send JSON message to a client */
function send(ws, data) {
  if (ws.readyState === ws.OPEN) {
    try {
      ws.send(JSON.stringify(data));
    } catch (err) {
      logger.error('WS send error:', err.message);
    }
  }
}

/** Send error message to client */
function sendError(ws, message, code = 'ERROR') {
  send(ws, { type: 'error', code, message });
}

/** Broadcast to all authenticated clients */
function broadcast(data) {
  for (const [ws, state] of clients.entries()) {
    if (state.authenticated) {
      send(ws, data);
    }
  }
}

/** Broadcast to clients subscribed to a specific symbol */
function broadcastToSubscribers(symbol, data) {
  for (const [ws, state] of clients.entries()) {
    if (state.authenticated && state.subscriptions.has(symbol)) {
      send(ws, data);
    }
  }
}

// ─── Authentication ──────────────────────────────────

/**
 * Handle client authentication (first message must be JWT)
 */
async function handleAuth(ws, state, message) {
  try {
    const { token } = message;
    if (!token) {
      sendError(ws, 'Token required for authentication', 'AUTH_REQUIRED');
      ws.close(4001, 'Authentication required');
      return;
    }

    // Verify JWT
    const decoded = jwt.verify(token, env.JWT_SECRET);
    const user = await User.findById(decoded.userId);

    if (!user) {
      sendError(ws, 'User not found', 'AUTH_FAILED');
      ws.close(4001, 'User not found');
      return;
    }

    if (user.isBlocked) {
      sendError(ws, 'Account blocked', 'AUTH_BLOCKED');
      ws.close(4003, 'Account blocked');
      return;
    }

    // Success
    state.authenticated = true;
    state.user = { id: user._id.toString(), email: user.email, name: user.name };
    state.plan = user.subscription?.plan || 'free';

    // Clear auth timeout
    if (state.authTimer) {
      clearTimeout(state.authTimer);
      state.authTimer = null;
    }

    send(ws, {
      type: 'authenticated',
      user: { name: user.name, plan: state.plan },
      limits: {
        maxSubscriptions: state.plan === 'pro' ? MAX_SUBSCRIPTIONS_PRO : MAX_SUBSCRIPTIONS_FREE,
        pollInterval: state.plan === 'pro' ? POLL_INTERVAL_PRO : POLL_INTERVAL_FREE,
      },
    });

    // Send current market status
    const marketStatus = getMarketStatus();
    send(ws, { type: 'market_status', ...marketStatus });

    logger.info(`WS authenticated: ${user.email} (${state.plan})`);
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      sendError(ws, 'Token expired', 'TOKEN_EXPIRED');
    } else {
      sendError(ws, 'Authentication failed', 'AUTH_FAILED');
    }
    ws.close(4001, 'Authentication failed');
  }
}

// ─── Subscription Handling ───────────────────────────

function handleSubscribe(ws, state, message) {
  const { symbol } = message;
  if (!symbol || typeof symbol !== 'string') {
    return sendError(ws, 'Symbol required', 'INVALID_SYMBOL');
  }

  const cleanSymbol = symbol.replace(/\.(KS|KQ)$/i, '').trim().toUpperCase();
  if (!cleanSymbol || !/^\d{6}$/.test(cleanSymbol)) {
    return sendError(ws, 'Invalid Korean stock symbol (6 digits required)', 'INVALID_SYMBOL');
  }

  const maxSubs = state.plan === 'pro' ? MAX_SUBSCRIPTIONS_PRO : MAX_SUBSCRIPTIONS_FREE;
  if (state.subscriptions.size >= maxSubs) {
    return sendError(ws, `Maximum ${maxSubs} subscriptions (${state.plan} plan)`, 'LIMIT_EXCEEDED');
  }

  state.subscriptions.add(cleanSymbol);

  send(ws, {
    type: 'subscribed',
    symbol: cleanSymbol,
    subscriptions: [...state.subscriptions],
  });

  // If we have cached price data, send it immediately
  const cached = latestPrices.get(cleanSymbol);
  if (cached) {
    send(ws, { type: 'price_update', ...cached });
  }

  logger.debug(`WS subscribe: ${state.user?.email} → ${cleanSymbol}`);
}

function handleUnsubscribe(ws, state, message) {
  const { symbol } = message;
  if (!symbol) return sendError(ws, 'Symbol required', 'INVALID_SYMBOL');

  const cleanSymbol = symbol.replace(/\.(KS|KQ)$/i, '').trim().toUpperCase();
  state.subscriptions.delete(cleanSymbol);

  send(ws, {
    type: 'unsubscribed',
    symbol: cleanSymbol,
    subscriptions: [...state.subscriptions],
  });

  logger.debug(`WS unsubscribe: ${state.user?.email} → ${cleanSymbol}`);
}

// ─── Message Router ──────────────────────────────────

function handleMessage(ws, state, raw) {
  let message;
  try {
    message = JSON.parse(raw.toString());
  } catch {
    return sendError(ws, 'Invalid JSON', 'PARSE_ERROR');
  }

  // First message must be authentication
  if (!state.authenticated) {
    if (message.type === 'auth') {
      return handleAuth(ws, state, message);
    }
    return sendError(ws, 'Must authenticate first. Send: { type: "auth", token: "..." }', 'AUTH_REQUIRED');
  }

  // Authenticated message handling
  switch (message.type) {
    case 'subscribe':
      return handleSubscribe(ws, state, message);
    case 'unsubscribe':
      return handleUnsubscribe(ws, state, message);
    case 'ping':
      return send(ws, { type: 'pong', time: Date.now() });
    default:
      return sendError(ws, `Unknown message type: ${message.type}`, 'UNKNOWN_TYPE');
  }
}

// ─── Price Polling ───────────────────────────────────

let pollTimer = null;
let marketStatusTimer = null;

/**
 * Poll KIS for all subscribed symbols and push updates.
 * Batches calls respecting 300ms throttle.
 */
async function pollPrices() {
  const symbols = getAllSubscribedSymbols();
  if (symbols.size === 0) return;

  const marketStatus = getMarketStatus();

  for (const symbol of symbols) {
    try {
      const result = await kisService.getPrice(symbol);
      const priceData = result.data;

      const update = {
        symbol: priceData.symbol,
        name: priceData.name,
        price: priceData.price,
        change: priceData.change,
        changePct: priceData.changePct,
        changeSign: priceData.changeSign,
        volume: priceData.volume,
        high: priceData.high,
        low: priceData.low,
        open: priceData.open,
        time: Date.now(),
        marketStatus: marketStatus.status,
      };

      // Check if price actually changed
      const prev = latestPrices.get(symbol);
      const priceChanged = !prev || prev.price !== update.price || prev.volume !== update.volume;

      latestPrices.set(symbol, update);

      // Only broadcast if data actually changed (save bandwidth)
      if (priceChanged) {
        broadcastToSubscribers(symbol, { type: 'price_update', ...update });
      }
    } catch (err) {
      logger.warn(`WS poll error for ${symbol}: ${err.message}`);
    }
  }
}

/**
 * Start the polling loop with adaptive interval
 */
function startPolling() {
  if (pollTimer) return; // Already running

  async function pollLoop() {
    const marketStatus = getMarketStatus();
    const interval = marketStatus.isOpen ? getMinPollInterval() : POLL_INTERVAL_CLOSED;

    try {
      await pollPrices();
    } catch (err) {
      logger.error('WS pollPrices error:', err.message);
    }

    // Schedule next poll
    pollTimer = setTimeout(pollLoop, interval);
  }

  // Start first poll
  pollLoop();
  logger.info('WS price polling started');
}

function stopPolling() {
  if (pollTimer) {
    clearTimeout(pollTimer);
    pollTimer = null;
    logger.info('WS price polling stopped');
  }
}

/**
 * Get the minimum poll interval among all connected clients.
 * Pro users get faster updates (10s), free users 30s.
 */
function getMinPollInterval() {
  let minInterval = POLL_INTERVAL_FREE;
  for (const state of clients.values()) {
    if (state.authenticated && state.subscriptions.size > 0) {
      const interval = state.plan === 'pro' ? POLL_INTERVAL_PRO : POLL_INTERVAL_FREE;
      if (interval < minInterval) minInterval = interval;
    }
  }
  return minInterval;
}

/**
 * Broadcast market status periodically
 */
function startMarketStatusBroadcast() {
  marketStatusTimer = setInterval(() => {
    const status = getMarketStatus();
    broadcast({ type: 'market_status', ...status });
  }, MARKET_STATUS_INTERVAL);
}

// ─── Heartbeat ───────────────────────────────────────

let heartbeatTimer = null;

function startHeartbeat() {
  heartbeatTimer = setInterval(() => {
    for (const [ws, state] of clients.entries()) {
      if (!state.alive) {
        // Didn't respond to last ping → terminate
        logger.debug(`WS heartbeat timeout: ${state.user?.email || 'unauthenticated'}`);
        ws.terminate();
        continue;
      }
      state.alive = false;
      ws.ping();
    }
  }, HEARTBEAT_INTERVAL);
}

// ─── Setup ───────────────────────────────────────────

/**
 * Attach WebSocket server to the HTTP server
 * @param {import('http').Server} httpServer
 */
export function setupWebSocket(httpServer) {
  wss = new WebSocketServer({ server: httpServer, path: '/ws' });

  wss.on('connection', (ws, req) => {
    const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    logger.info(`WS new connection from ${clientIp}`);

    const state = createClientState();
    clients.set(ws, state);

    // Auth timeout — must authenticate within 10s
    state.authTimer = setTimeout(() => {
      if (!state.authenticated) {
        sendError(ws, 'Authentication timeout', 'AUTH_TIMEOUT');
        ws.close(4001, 'Authentication timeout');
      }
    }, AUTH_TIMEOUT);

    // Handle messages
    ws.on('message', (raw) => handleMessage(ws, state, raw));

    // Handle pong (heartbeat response)
    ws.on('pong', () => {
      state.alive = true;
    });

    // Handle close
    ws.on('close', (code, reason) => {
      logger.info(`WS disconnected: ${state.user?.email || 'unauthenticated'} (code: ${code})`);
      if (state.authTimer) clearTimeout(state.authTimer);
      clients.delete(ws);

      // Stop polling if no more subscribers
      const allSymbols = getAllSubscribedSymbols();
      if (allSymbols.size === 0) {
        stopPolling();
      }
    });

    // Handle errors
    ws.on('error', (err) => {
      logger.error(`WS error: ${err.message}`);
    });

    // Start polling if this is the first client
    if (clients.size === 1) {
      startPolling();
    }
  });

  // Start heartbeat and market status broadcast
  startHeartbeat();
  startMarketStatusBroadcast();

  logger.info(`🔌 WebSocket server started on /ws`);
  return wss;
}

/**
 * Get WebSocket stats (for admin / health check)
 */
export function getWSStats() {
  const authenticated = [...clients.values()].filter(s => s.authenticated).length;
  const subscriptions = getAllSubscribedSymbols();

  return {
    totalConnections: clients.size,
    authenticatedConnections: authenticated,
    uniqueSymbolsWatched: subscriptions.size,
    symbols: [...subscriptions],
    isPolling: pollTimer !== null,
    cachedPrices: latestPrices.size,
  };
}

/**
 * Graceful shutdown
 */
export function shutdownWebSocket() {
  if (heartbeatTimer) clearInterval(heartbeatTimer);
  if (marketStatusTimer) clearInterval(marketStatusTimer);
  stopPolling();

  for (const [ws] of clients.entries()) {
    ws.close(1001, 'Server shutting down');
  }
  clients.clear();
  latestPrices.clear();

  if (wss) {
    wss.close();
    logger.info('WebSocket server shut down');
  }
}

export default { setupWebSocket, getWSStats, shutdownWebSocket };
