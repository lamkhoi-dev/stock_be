/**
 * Admin Routes
 * All routes require requireAuth + requireAdmin
 *
 * Users:
 *   GET    /api/admin/users                  — List users (paginated, search, filter)
 *   GET    /api/admin/users/:id              — User detail
 *   PUT    /api/admin/users/:id/block        — Block/unblock user
 *   PUT    /api/admin/users/:id/subscription — Change plan/credits
 *
 * Config:
 *   GET    /api/admin/config                 — System config
 *
 * Logs:
 *   GET    /api/admin/logs                   — View logs (paginated, filtered)
 *   GET    /api/admin/logs/export            — Export CSV
 *
 * Stats:
 *   GET    /api/admin/stats                  — Dashboard statistics
 */
import { Router } from 'express';
import { body } from 'express-validator';
import adminController from '../controllers/admin.controller.js';
import { requireAuth, requireAdmin } from '../middleware/auth.middleware.js';
import { validate as handleValidation } from '../middleware/validate.js';

const router = Router();

// All admin routes require authentication + admin role
router.use(requireAuth, requireAdmin);

// ─── Users ───────────────────────────────────────────
router.get('/users', adminController.getUsers);
router.get('/users/:id', adminController.getUserDetail);

router.put(
  '/users/:id/block',
  [
    body('blocked').isBoolean().withMessage('blocked must be a boolean'),
    body('reason').optional().isString().isLength({ max: 200 }),
    handleValidation,
  ],
  adminController.blockUser,
);

router.put(
  '/users/:id/subscription',
  [
    body('plan').optional().isIn(['free', 'pro']).withMessage('Plan must be free or pro'),
    body('credits').optional().isInt({ min: 0 }).withMessage('Credits must be a non-negative integer'),
    body('addCredits').optional().isInt({ min: 1 }).withMessage('addCredits must be a positive integer'),
    handleValidation,
  ],
  adminController.updateSubscription,
);

// ─── Config ──────────────────────────────────────────
router.get('/config', adminController.getConfig);

// ─── Logs ────────────────────────────────────────────
router.get('/logs', adminController.getLogs);
router.get('/logs/export', adminController.exportLogs);

// ─── Stats ───────────────────────────────────────────
router.get('/stats', adminController.getStats);

export default router;
