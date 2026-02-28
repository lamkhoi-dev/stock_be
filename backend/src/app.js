/**
 * Express Application Setup
 * Configures middleware, routes, and error handlers
 */
import express from 'express';
import helmet from 'helmet';
import compression from 'compression';
import { setupCors } from './config/cors.js';
import { apiLimiter } from './middleware/rateLimiter.js';
import { notFoundHandler, errorHandler } from './middleware/errorHandler.js';
import logger from './utils/logger.js';

// Import routes
import authRoutes from './routes/auth.routes.js';
import stocksRoutes from './routes/stocks.routes.js';
import userRoutes from './routes/user.routes.js';
import watchlistRoutes from './routes/watchlist.routes.js';
import aiRoutes from './routes/ai.routes.js';
import adminRoutes from './routes/admin.routes.js';

const app = express();

// ─── Security ────────────────────────────────────────
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

// ─── CORS ────────────────────────────────────────────
setupCors(app);

// ─── Body Parsing ────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ─── Compression ─────────────────────────────────────
app.use(compression());

// ─── Rate Limiting ───────────────────────────────────
app.use('/api/', apiLimiter);

// ─── Request Logging (dev) ───────────────────────────
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    const logLevel = res.statusCode >= 400 ? 'warn' : 'debug';
    logger[logLevel](`${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`);
  });
  next();
});

// ─── Root route (Render default health check hits /) ─
app.get('/', (req, res) => {
  res.json({ status: 'ok', service: 'krx-stock-backend' });
});
app.head('/', (req, res) => {
  res.sendStatus(200);
});

// ─── Health Check ────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    data: {
      status: 'ok',
      service: 'krx-stock-backend',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      uptime: Math.floor(process.uptime()),
    },
  });
});

// ─── API Routes ──────────────────────────────────────
// Phase 1B: Authentication
app.use('/api/auth', authRoutes);

// Phase 2C: User management
app.use('/api/users', userRoutes);

// Phase 1E: Stock data
app.use('/api/stocks', stocksRoutes);

// Phase 2C: Watchlist
app.use('/api/watchlist', watchlistRoutes);

// Phase 2B: AI Analysis
app.use('/api/ai', aiRoutes);

// Phase 2D: Admin
app.use('/api/admin', adminRoutes);

// ─── Error Handling ──────────────────────────────────
app.use(notFoundHandler);
app.use(errorHandler);

export default app;
