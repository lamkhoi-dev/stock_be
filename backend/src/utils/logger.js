/**
 * Winston Logger Configuration
 * Logs to console (dev), files (prod), and MongoDB SystemLog (always)
 */
import winston from 'winston';
import Transport from 'winston-transport';
import env from '../config/env.js';

const { combine, timestamp, printf, colorize, errors } = winston.format;

// Custom log format
const logFormat = printf(({ level, message, timestamp, stack, ...meta }) => {
  let log = `${timestamp} [${level}]: ${message}`;
  if (stack) log += `\n${stack}`;
  if (Object.keys(meta).length > 0) {
    log += `\n${JSON.stringify(meta, null, 2)}`;
  }
  return log;
});

// ─── MongoDB Transport ───────────────────────────────
// Writes logs to the SystemLog collection for the Admin Logs page.
// Import is deferred to avoid circular dependency (model needs mongoose connected).
class MongoDBTransport extends Transport {
  constructor(opts = {}) {
    super(opts);
    this._SystemLog = null;
    this._queue = [];      // buffer logs until model is ready
    this._ready = false;
    this._initPromise = null;
  }

  /** Lazy-load the SystemLog model (waits for mongoose connection) */
  async _ensureModel() {
    if (this._SystemLog) return this._SystemLog;
    if (this._initPromise) return this._initPromise;

    this._initPromise = (async () => {
      // Dynamic import so the model is only loaded after mongoose.connect()
      const mod = await import('../models/SystemLog.js');
      this._SystemLog = mod.default;
      this._ready = true;
      // Flush queued logs
      if (this._queue.length > 0) {
        const batch = this._queue.splice(0);
        try { await this._SystemLog.insertMany(batch, { ordered: false }); } catch { /* ignore flush errors */ }
      }
      return this._SystemLog;
    })();
    return this._initPromise;
  }

  log(info, callback) {
    setImmediate(() => this.emit('logged', info));

    const level = info.level?.replace(/\u001b\[\d+m/g, ''); // strip ANSI colors
    // Only persist warn/error/info (skip debug to avoid noise)
    if (level === 'debug') {
      callback();
      return;
    }

    const { message, stack, service, source, url, method, ip, userId, ...rest } = info;

    const doc = {
      level,
      source: source || service || 'backend',
      message: typeof message === 'string' ? message.slice(0, 2000) : String(message),
      stack: stack || null,
      meta: Object.keys(rest).length > 1 ? rest : {},  // >1 because timestamp is always present
      userId: userId || null,
      request: (url || method) ? { method, url, ip } : undefined,
    };

    if (!this._ready) {
      this._queue.push(doc);
      // Kick off model loading (non-blocking)
      this._ensureModel().catch(() => {});
      callback();
      return;
    }

    // Fire-and-forget write to MongoDB
    this._SystemLog.create(doc).catch(() => {});
    callback();
  }
}

// Create logger
const logger = winston.createLogger({
  level: env.isDev ? 'debug' : 'info',
  format: combine(
    errors({ stack: true }),
    timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    logFormat,
  ),
  defaultMeta: { service: 'krx-backend' },
  transports: [
    // Console (always)
    new winston.transports.Console({
      format: combine(
        colorize(),
        timestamp({ format: 'HH:mm:ss' }),
        logFormat,
      ),
    }),
    // MongoDB (always — persists logs for Admin panel)
    new MongoDBTransport({ level: 'info' }),
  ],
});

// File transports for production
if (env.isProd) {
  logger.add(new winston.transports.File({
    filename: 'logs/error.log',
    level: 'error',
    maxsize: 10 * 1024 * 1024, // 10MB
    maxFiles: 5,
  }));
  logger.add(new winston.transports.File({
    filename: 'logs/combined.log',
    maxsize: 10 * 1024 * 1024,
    maxFiles: 5,
  }));
}

export default logger;
