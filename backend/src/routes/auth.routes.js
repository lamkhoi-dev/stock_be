/**
 * Authentication Routes
 * /api/auth/...
 */
import { Router } from 'express';
import { body } from 'express-validator';
import { validate } from '../middleware/validate.js';
import { requireAuth } from '../middleware/auth.middleware.js';
import { authLimiter } from '../middleware/rateLimiter.js';
import {
  register,
  login,
  googleAuth,
  appleAuth,
  verifyEmail,
  forgotPassword,
  resetPassword,
  refreshTokenHandler,
  getMe,
  logout,
} from '../controllers/auth.controller.js';

const router = Router();

// Apply stricter rate limiting to auth routes
router.use(authLimiter);

// ─── Register ────────────────────────────────────────
router.post('/register', [
  body('email')
    .isEmail().withMessage('Valid email required')
    .normalizeEmail(),
  body('password')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
    .matches(/[A-Z]/).withMessage('Password must contain an uppercase letter')
    .matches(/\d/).withMessage('Password must contain a number'),
  body('name')
    .trim()
    .isLength({ min: 2, max: 50 }).withMessage('Name must be 2-50 characters'),
  validate,
], register);

// ─── Login ───────────────────────────────────────────
router.post('/login', [
  body('email').isEmail().withMessage('Valid email required').normalizeEmail(),
  body('password').notEmpty().withMessage('Password required'),
  validate,
], login);

// ─── OAuth ───────────────────────────────────────────
router.post('/google', [
  body('idToken').notEmpty().withMessage('Google ID token required'),
  validate,
], googleAuth);

router.post('/apple', [
  body('identityToken').notEmpty().withMessage('Apple identity token required'),
  validate,
], appleAuth);

// ─── Email Verification ─────────────────────────────
router.post('/verify-email', [
  body('token').notEmpty().withMessage('Verification token required'),
  validate,
], verifyEmail);

// ─── Password Reset ──────────────────────────────────
router.post('/forgot-password', [
  body('email').isEmail().withMessage('Valid email required').normalizeEmail(),
  validate,
], forgotPassword);

router.post('/reset-password', [
  body('token').notEmpty().withMessage('Reset token required'),
  body('password')
    .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
    .matches(/[A-Z]/).withMessage('Password must contain an uppercase letter')
    .matches(/\d/).withMessage('Password must contain a number'),
  validate,
], resetPassword);

// ─── Token Refresh ───────────────────────────────────
router.post('/refresh-token', [
  body('refreshToken').notEmpty().withMessage('Refresh token required'),
  validate,
], refreshTokenHandler);

// ─── Protected Routes ─────────────────────────────────
router.get('/me', requireAuth, getMe);
router.post('/logout', requireAuth, logout);

export default router;
