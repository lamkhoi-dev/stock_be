/**
 * Stock API Routes
 * All stock-related endpoints
 */
import { Router } from 'express';
import { optionalAuth, requireAdmin } from '../middleware/auth.middleware.js';
import {
  healthKis,
  healthYahoo,
  getPrice,
  getDailyChart,
  getMinuteChart,
  getTrades,
  getFluctuationRanking,
  getVolumeRanking,
  getStockList,
  getInvestor,
  getIndex,
  getMarketOverview,
  searchStocks,
  getNews,
  getIndicators,
  getIndicatorHistory,
  getCacheStats,
  clearCache,
} from '../controllers/stock.controller.js';

const router = Router();

// ─── Health Checks ───────────────────────────────────
router.get('/health/kis', healthKis);
router.get('/health/yahoo', healthYahoo);

// ─── Search ──────────────────────────────────────────
router.get('/search', optionalAuth, searchStocks);

// ─── Market Overview & Index ─────────────────────────
router.get('/market', optionalAuth, getMarketOverview);
router.get('/index', optionalAuth, getIndex);

// ─── Rankings ────────────────────────────────────────
router.get('/ranking/fluctuation', optionalAuth, getFluctuationRanking);
router.get('/ranking/volume', optionalAuth, getVolumeRanking);

// ─── Stock List (merged rankings) ────────────────────
router.get('/list', optionalAuth, getStockList);

// ─── Stock Detail ────────────────────────────────────
router.get('/price/:symbol', optionalAuth, getPrice);
router.get('/chart/:symbol', optionalAuth, getDailyChart);
router.get('/minutechart/:symbol', optionalAuth, getMinuteChart);
router.get('/trades/:symbol', optionalAuth, getTrades);
router.get('/investor/:symbol', optionalAuth, getInvestor);
router.get('/news/:symbol', optionalAuth, getNews);

// ─── Technical Indicators ────────────────────────────
router.get('/indicators/:symbol', optionalAuth, getIndicators);
router.get('/indicators/:symbol/history', optionalAuth, getIndicatorHistory);

// ─── Cache Management (admin only) ──────────────────
router.get('/cache/stats', requireAdmin, getCacheStats);
router.delete('/cache', requireAdmin, clearCache);

export default router;
