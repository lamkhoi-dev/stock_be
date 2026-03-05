/**
 * Server Entry Point
 * Starts HTTP server + WebSocket + MongoDB connection
 */
import { createServer } from 'http';
import app from './app.js';
import env, { validateEnv } from './config/env.js';
import { connectDB } from './config/db.js';
import { setupWebSocket, shutdownWebSocket } from './services/websocket.service.js';
import stockMasterService from './services/stock-master.service.js';
import logger from './utils/logger.js';

// Validate environment variables
validateEnv();

// Create HTTP server (needed for WebSocket later)
const server = createServer(app);

// ─── Start Server ────────────────────────────────────
async function start() {
  try {
    // Start listening FIRST so Render/cloud sees the port open quickly
    server.listen(env.PORT, '0.0.0.0', () => {
      logger.info(`🚀 KRX Stock Backend running on port ${env.PORT} (${env.NODE_ENV})`);
      if (env.isProd) {
        logger.info(`📡 Health check: /api/health`);
      } else {
        logger.info(`📡 Health check: http://localhost:${env.PORT}/api/health`);
      }
    });

    // Phase 2A: Attach WebSocket server
    setupWebSocket(server);

    // Connect to MongoDB (after port is bound — non-blocking for deploy health)
    await connectDB();

    // Initialize stock master data (download KIS master files → ~2500 stocks)
    stockMasterService.init().catch((err) =>
      logger.warn('Stock master init deferred:', err.message),
    );

  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  logger.error('Unhandled Promise Rejection:', err);
  shutdownWebSocket();
  server.close(() => process.exit(1));
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  logger.error('Uncaught Exception:', err);
  process.exit(1);
});

// Graceful shutdown for Render / cloud
process.on('SIGTERM', () => {
  logger.info('SIGTERM received — shutting down gracefully');
  shutdownWebSocket();
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});

start();

export { server };
