/**
 * Watchlist Routes
 * GET    /api/watchlist             — Get watchlist (with optional live prices)
 * POST   /api/watchlist             — Add symbol
 * DELETE /api/watchlist/:symbol     — Remove symbol
 * PUT    /api/watchlist/reorder     — Reorder (Pro only)
 * GET    /api/watchlist/check/:symbol — Check if watched
 */
import { Router } from 'express';
import { body } from 'express-validator';
import watchlistController from '../controllers/watchlist.controller.js';
import { requireAuth } from '../middleware/auth.middleware.js';
import { validate as handleValidation } from '../middleware/validate.js';

const router = Router();

// All watchlist routes require authentication
router.use(requireAuth);

router.get('/', watchlistController.getWatchlist);

router.post(
  '/',
  [
    body('symbol').notEmpty().withMessage('Symbol is required').isString(),
    body('market').optional().isIn(['KOSPI', 'KOSDAQ', 'OTHER']).withMessage('Invalid market'),
    handleValidation,
  ],
  watchlistController.addToWatchlist,
);

router.delete('/:symbol', watchlistController.removeFromWatchlist);

router.put(
  '/reorder',
  [
    body('symbols').isArray({ min: 1 }).withMessage('symbols must be a non-empty array'),
    handleValidation,
  ],
  watchlistController.reorderWatchlist,
);

router.get('/check/:symbol', watchlistController.isWatched);

export default router;
