/**
 * Watchlist Controller
 * CRUD for user's stock watchlist
 * Free: max 10 items, Pro: unlimited
 */
import Watchlist from '../models/Watchlist.js';
import User from '../models/User.js';
import kisService from '../services/kis.service.js';
import { ApiError } from '../middleware/errorHandler.js';
import { stripSymbolSuffix } from '../utils/helpers.js';
import logger from '../utils/logger.js';

const MAX_FREE_WATCHLIST = 10;

const watchlistController = {
  /**
   * GET /api/watchlist
   * Get user's watchlist with optional live price data
   * Query: ?withPrice=true
   */
  async getWatchlist(req, res, next) {
    try {
      const items = await Watchlist.getByUser(req.userId);
      const withPrice = req.query.withPrice === 'true';

      let result = items.map(item => item.toJSON());

      // Optionally enrich with live price data
      if (withPrice && result.length > 0) {
        const enriched = await Promise.allSettled(
          result.map(async (item) => {
            try {
              const priceResult = await kisService.getPrice(item.symbol);
              return {
                ...item,
                currentPrice: priceResult.data.price,
                change: priceResult.data.change,
                changePct: priceResult.data.changePct,
                volume: priceResult.data.volume,
              };
            } catch {
              return item; // Return without price if KIS fails
            }
          }),
        );
        result = enriched.map(r => r.status === 'fulfilled' ? r.value : r.reason);
      }

      res.json({
        success: true,
        data: {
          items: result,
          count: result.length,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * POST /api/watchlist
   * Add symbol to watchlist
   * Body: { symbol, name?, nameKo?, market? }
   */
  async addToWatchlist(req, res, next) {
    try {
      const { symbol, name, nameKo, market = 'KOSPI' } = req.body;
      if (!symbol) throw ApiError.badRequest('Symbol is required');

      const cleanSymbol = stripSymbolSuffix(symbol).toUpperCase();

      // Check if already in watchlist
      const exists = await Watchlist.isWatched(req.userId, cleanSymbol);
      if (exists) {
        throw ApiError.badRequest('Symbol already in watchlist');
      }

      // Check free tier limit
      const user = await User.findById(req.userId);
      const count = await Watchlist.countByUser(req.userId);
      const maxItems = user?.subscription?.plan === 'pro' ? Infinity : MAX_FREE_WATCHLIST;

      if (count >= maxItems) {
        throw ApiError.forbidden(
          `Watchlist limit reached (${maxItems} items). ${user?.subscription?.plan === 'free' ? 'Upgrade to Pro for unlimited.' : ''}`,
        );
      }

      // If no name provided, try to fetch from KIS
      let stockName = name || '';
      let stockNameKo = nameKo || '';
      if (!stockName || !stockNameKo) {
        try {
          const priceResult = await kisService.getPrice(cleanSymbol);
          stockName = stockName || priceResult.data.name || cleanSymbol;
          stockNameKo = stockNameKo || priceResult.data.name || '';
        } catch {
          // Not critical, continue with empty name
        }
      }

      const item = await Watchlist.create({
        userId: req.userId,
        symbol: cleanSymbol,
        name: stockName,
        nameKo: stockNameKo,
        market,
        order: count, // Add at end
      });

      logger.debug(`Watchlist add: ${user?.email} → ${cleanSymbol}`);

      res.status(201).json({
        success: true,
        data: item,
        message: `${cleanSymbol} added to watchlist`,
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * DELETE /api/watchlist/:symbol
   * Remove symbol from watchlist
   */
  async removeFromWatchlist(req, res, next) {
    try {
      const symbol = stripSymbolSuffix(req.params.symbol).toUpperCase();

      const result = await Watchlist.findOneAndDelete({
        userId: req.userId,
        symbol,
      });

      if (!result) {
        throw ApiError.notFound('Symbol not found in watchlist');
      }

      res.json({
        success: true,
        message: `${symbol} removed from watchlist`,
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * PUT /api/watchlist/reorder
   * Reorder watchlist items
   * Body: { symbols: ['005930', '000660', ...] }
   * Pro only
   */
  async reorderWatchlist(req, res, next) {
    try {
      const { symbols } = req.body;
      if (!Array.isArray(symbols)) {
        throw ApiError.badRequest('symbols must be an array');
      }

      // Check if Pro (reorder is Pro-only feature)
      const user = await User.findById(req.userId);
      if (user?.subscription?.plan !== 'pro') {
        throw ApiError.forbidden('Reorder is a Pro feature');
      }

      // Update order for each symbol
      const updates = symbols.map((symbol, index) =>
        Watchlist.findOneAndUpdate(
          { userId: req.userId, symbol: symbol.toUpperCase() },
          { order: index },
        ),
      );

      await Promise.all(updates);

      res.json({
        success: true,
        message: 'Watchlist reordered',
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/watchlist/check/:symbol
   * Check if a symbol is in the user's watchlist
   */
  async isWatched(req, res, next) {
    try {
      const symbol = stripSymbolSuffix(req.params.symbol).toUpperCase();
      const watched = await Watchlist.isWatched(req.userId, symbol);

      res.json({
        success: true,
        data: { symbol, isWatched: watched },
      });
    } catch (error) {
      next(error);
    }
  },
};

export default watchlistController;
