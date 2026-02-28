/**
 * User Routes
 * GET    /api/users/profile          — Get profile
 * PUT    /api/users/profile          — Update profile
 * PUT    /api/users/change-password  — Change password
 * DELETE /api/users/account          — Deactivate account
 */
import { Router } from 'express';
import { body } from 'express-validator';
import userController from '../controllers/user.controller.js';
import { requireAuth } from '../middleware/auth.middleware.js';
import { validate as handleValidation } from '../middleware/validate.js';

const router = Router();

// All user routes require authentication
router.use(requireAuth);

// Profile
router.get('/profile', userController.getProfile);

router.put(
  '/profile',
  [
    body('name').optional().isLength({ min: 2, max: 50 }).withMessage('Name must be 2-50 characters'),
    body('avatar').optional().isURL().withMessage('Avatar must be a valid URL'),
    body('settings.language').optional().isIn(['en', 'vi', 'ko']).withMessage('Language must be en, vi, or ko'),
    body('settings.theme').optional().isIn(['dark', 'light', 'system']).withMessage('Theme must be dark, light, or system'),
    body('settings.defaultChart').optional().isIn(['candle', 'line', 'area', 'bar']).withMessage('Invalid chart type'),
    body('settings.notifications').optional().isBoolean().withMessage('Notifications must be boolean'),
    handleValidation,
  ],
  userController.updateProfile,
);

// Password
router.put(
  '/change-password',
  [
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    body('newPassword')
      .isLength({ min: 8 }).withMessage('New password must be at least 8 characters')
      .matches(/[A-Z]/).withMessage('Password must contain an uppercase letter')
      .matches(/[0-9]/).withMessage('Password must contain a number'),
    handleValidation,
  ],
  userController.changePassword,
);

// Account
router.delete('/account', userController.deleteAccount);

export default router;
