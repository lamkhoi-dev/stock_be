/**
 * AI Analysis Routes
 * POST /api/ai/analyze      — Run AI analysis (basic/pro)
 * GET  /api/ai/history       — Analysis history (paginated)
 * GET  /api/ai/credits       — Credit info & usage
 * GET  /api/ai/analysis/:id  — Specific analysis detail
 */
import { Router } from 'express';
import aiController from '../controllers/ai.controller.js';
import { requireAuth } from '../middleware/auth.middleware.js';
import { aiLimiter } from '../middleware/rateLimiter.js';

const router = Router();

// All AI routes require authentication
router.use(requireAuth);

// Rate limit AI analysis
router.post('/analyze', aiLimiter, aiController.analyze);

// History and credits (no special rate limit beyond global API limiter)
router.get('/history', aiController.getHistory);
router.get('/credits', aiController.getCredits);
router.get('/analysis/:id', aiController.getAnalysis);

export default router;
