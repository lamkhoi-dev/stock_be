/**
 * Stock Controller
 * Handles all stock-related API requests
 * Primary source: KIS  |  Fallback: Yahoo Finance
 */
import kisService from '../services/kis.service.js';
import yahooService from '../services/yahoo.service.js';
import indicatorsService from '../services/indicators.service.js';
import cacheService from '../services/cache.service.js';
import logger from '../utils/logger.js';

/**
 * Wrap async handler with KIS→Yahoo fallback
 */
function withFallback(kisFn, yahooFn) {
  return async (req, res, next) => {
    try {
      const result = await kisFn(req);
      return res.json({ success: true, ...result, source: 'kis' });
    } catch (kisErr) {
      if (!yahooFn) {
        logger.error(`KIS error (no fallback): ${kisErr.message}`);
        return next(kisErr);
      }
      logger.warn(`KIS failed, falling back to Yahoo: ${kisErr.message}`);
      try {
        const result = await yahooFn(req);
        return res.json({ success: true, ...result, source: 'yahoo' });
      } catch (yahooErr) {
        logger.error(`Both KIS and Yahoo failed: KIS=${kisErr.message}, Yahoo=${yahooErr.message}`);
        return next(kisErr); // Surface KIS error as primary
      }
    }
  };
}

// ═══════════════════════════════════════════════════════
//  HEALTH CHECKS
// ═══════════════════════════════════════════════════════

export const healthKis = async (req, res, next) => {
  try {
    const data = await kisService.health();
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
};

export const healthYahoo = async (req, res, next) => {
  try {
    const data = await yahooService.health();
    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
};

// ═══════════════════════════════════════════════════════
//  STOCK PRICE & QUOTE
// ═══════════════════════════════════════════════════════

/**
 * GET /api/stocks/price/:symbol
 * Current price with full details (KIS primary → Yahoo fallback)
 */
export const getPrice = withFallback(
  async (req) => kisService.getPrice(req.params.symbol),
  async (req) => {
    const sym = req.params.symbol;
    const yahoo = await yahooService.getQuote(sym.includes('.') ? sym : `${sym}.KS`);
    // Normalize Yahoo response to match KIS structure
    const d = yahoo.data;
    return {
      data: {
        symbol: sym,
        name: d.shortName || d.longName || sym,
        price: d.regularMarketPrice || 0,
        change: Math.round((d.regularMarketChange || 0) * 100) / 100,
        changePct: Math.round((d.regularMarketChangePercent || 0) * 100) / 100,
        open: d.regularMarketOpen || 0,
        high: d.regularMarketDayHigh || 0,
        low: d.regularMarketDayLow || 0,
        prevClose: d.regularMarketPreviousClose || 0,
        volume: d.regularMarketVolume || 0,
        high52w: d.fiftyTwoWeekHigh || 0,
        low52w: d.fiftyTwoWeekLow || 0,
      },
      cached: yahoo.cached,
    };
  },
);

// ═══════════════════════════════════════════════════════
//  CHART DATA
// ═══════════════════════════════════════════════════════

/**
 * GET /api/stocks/chart/:symbol
 * Daily OHLCV chart data
 * Query: period (D/W/M/Y), startDate, endDate
 */
export const getDailyChart = withFallback(
  async (req) => {
    const { period, startDate, endDate } = req.query;
    return kisService.getDailyChart(req.params.symbol, { period, startDate, endDate });
  },
  async (req) => {
    const periodMap = { D: '6m', W: '1y', M: '2y', Y: '5y' };
    const yahooP = periodMap[req.query.period] || '6m';
    const sym = req.params.symbol;
    return yahooService.getHistory(sym.includes('.') ? sym : `${sym}.KS`, { period: yahooP });
  },
);

/**
 * GET /api/stocks/minutechart/:symbol
 * Intraday minute candles (KIS only — Yahoo doesn't have KRX minute data)
 * Query: time, pages
 */
export const getMinuteChart = async (req, res, next) => {
  try {
    const { time, pages } = req.query;
    const result = await kisService.getMinuteChart(req.params.symbol, {
      time,
      maxPages: pages ? parseInt(pages) : 6,
    });
    res.json({ success: true, ...result, source: 'kis' });
  } catch (err) {
    next(err);
  }
};

// ═══════════════════════════════════════════════════════
//  TRADES
// ═══════════════════════════════════════════════════════

/**
 * GET /api/stocks/trades/:symbol
 * Recent trade executions (KIS only)
 */
export const getTrades = async (req, res, next) => {
  try {
    const result = await kisService.getTrades(req.params.symbol);
    res.json({ success: true, ...result, source: 'kis' });
  } catch (err) {
    next(err);
  }
};

// ═══════════════════════════════════════════════════════
//  RANKINGS
// ═══════════════════════════════════════════════════════

/**
 * GET /api/stocks/ranking/fluctuation
 * Top gainers/losers — Query: type (0=all, 1=up, 3=down)
 */
export const getFluctuationRanking = async (req, res, next) => {
  try {
    const result = await kisService.getFluctuationRanking(req.query.type || '0');
    res.json({ success: true, ...result, source: 'kis' });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/stocks/ranking/volume
 * Top volume stocks
 */
export const getVolumeRanking = async (req, res, next) => {
  try {
    const result = await kisService.getVolumeRanking();
    res.json({ success: true, ...result, source: 'kis' });
  } catch (err) {
    next(err);
  }
};

// ═══════════════════════════════════════════════════════
//  INVESTOR DATA
// ═══════════════════════════════════════════════════════

/**
 * GET /api/stocks/investor/:symbol
 * Investor group trading data (KIS only)
 */
export const getInvestor = async (req, res, next) => {
  try {
    const result = await kisService.getInvestor(req.params.symbol);
    res.json({ success: true, ...result, source: 'kis' });
  } catch (err) {
    next(err);
  }
};

// ═══════════════════════════════════════════════════════
//  MARKET INDEX
// ═══════════════════════════════════════════════════════

/**
 * GET /api/stocks/index
 * Market index (KOSPI / KOSDAQ) — Query: code (0001/1001)
 */
export const getIndex = async (req, res, next) => {
  try {
    const result = await kisService.getIndex(req.query.code || '0001');
    res.json({ success: true, ...result, source: 'kis' });
  } catch (err) {
    next(err);
  }
};

// ═══════════════════════════════════════════════════════
//  MARKET OVERVIEW
// ═══════════════════════════════════════════════════════

/**
 * GET /api/stocks/market
 * Market overview — batch top Korean stocks
 */
export const getMarketOverview = withFallback(
  async () => kisService.getMarketOverview(),
  async () => yahooService.getMarketOverview(),
);

// ═══════════════════════════════════════════════════════
//  SEARCH
// ═══════════════════════════════════════════════════════

/**
 * GET /api/stocks/search?q=samsung
 * Symbol search (Yahoo Finance — KIS has no search endpoint)
 */
export const searchStocks = async (req, res, next) => {
  try {
    const result = await yahooService.search(req.query.q);
    res.json({ success: true, ...result, source: 'yahoo' });
  } catch (err) {
    next(err);
  }
};

// ═══════════════════════════════════════════════════════
//  NEWS
// ═══════════════════════════════════════════════════════

/**
 * GET /api/stocks/news/:symbol
 * News for a symbol (Yahoo Finance)
 */
export const getNews = async (req, res, next) => {
  try {
    const result = await yahooService.getNews(req.params.symbol);
    res.json({ success: true, ...result, source: 'yahoo' });
  } catch (err) {
    next(err);
  }
};

// ═══════════════════════════════════════════════════════
//  TECHNICAL INDICATORS
// ═══════════════════════════════════════════════════════

/**
 * GET /api/stocks/indicators/:symbol
 * All technical indicators summary
 * Query: period (D/W/M)
 */
export const getIndicators = async (req, res, next) => {
  try {
    const result = await indicatorsService.getAll(req.params.symbol, {
      period: req.query.period || 'D',
    });
    res.json({ success: true, ...result, source: 'calculated' });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/stocks/indicators/:symbol/history
 * Indicator history (for chart overlays)
 * Query: period (D/W/M)
 */
export const getIndicatorHistory = async (req, res, next) => {
  try {
    const result = await indicatorsService.getHistory(req.params.symbol, {
      period: req.query.period || 'D',
    });
    res.json({ success: true, ...result, source: 'calculated' });
  } catch (err) {
    next(err);
  }
};

// ═══════════════════════════════════════════════════════
//  CACHE MANAGEMENT (admin/debug)
// ═══════════════════════════════════════════════════════

/**
 * GET /api/stocks/cache/stats
 */
export const getCacheStats = (req, res) => {
  res.json({ success: true, data: cacheService.getStats() });
};

/**
 * DELETE /api/stocks/cache
 */
export const clearCache = (req, res) => {
  cacheService.clear();
  res.json({ success: true, message: 'Cache cleared' });
};
