/**
 * Rate Limiter Middleware
 * Protects API from abuse with configurable limits
 */
import rateLimit from 'express-rate-limit';

/**
 * General API rate limiter
 * 100 requests per 15 minutes per IP
 */
export const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  message: {
    success: false,
    error: {
      status: 429,
      message: 'Too many requests. Please try again later.',
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Auth routes rate limiter
 * 10 attempts per 15 minutes per IP (login, register, etc.)
 */
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: {
    success: false,
    error: {
      status: 429,
      message: 'Too many authentication attempts. Please try again in 15 minutes.',
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * AI analysis rate limiter
 * Free users: 3 per day, configurable per tier
 */
export const aiLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000, // 24 hours
  max: 20, // Base limit (controller checks user's tier)
  message: {
    success: false,
    error: {
      status: 429,
      message: 'AI analysis limit reached for today.',
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});
