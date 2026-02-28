/**
 * Authentication Middleware
 * JWT verification, user attachment, role checking
 */
import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import env from '../config/env.js';
import { ApiError } from './errorHandler.js';

/**
 * Require authenticated user
 * Extracts Bearer token, verifies JWT, attaches user to req.user
 */
export async function requireAuth(req, res, next) {
  try {
    // 1. Extract token from Authorization header
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw ApiError.unauthorized('Access token required');
    }
    const token = authHeader.split(' ')[1];

    // 2. Verify JWT
    let decoded;
    try {
      decoded = jwt.verify(token, env.JWT_SECRET);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        throw ApiError.unauthorized('Token expired');
      }
      throw ApiError.unauthorized('Invalid token');
    }

    // 3. Find user in DB
    const user = await User.findById(decoded.userId);
    if (!user) {
      throw ApiError.unauthorized('User not found');
    }

    // 4. Check if user is blocked
    if (user.isBlocked) {
      throw ApiError.forbidden('Account has been blocked. Contact admin.');
    }

    // 5. Attach user to request
    req.user = user;
    req.userId = user._id;
    next();
  } catch (error) {
    next(error);
  }
}

/**
 * Optional auth — attaches user if token present, but doesn't fail if missing
 * Useful for endpoints that work for both guests and logged-in users
 */
export async function optionalAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      req.user = null;
      req.userId = null;
      return next();
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, env.JWT_SECRET);
    const user = await User.findById(decoded.userId);
    
    req.user = user || null;
    req.userId = user?._id || null;
    next();
  } catch {
    // Token invalid or expired — treat as guest
    req.user = null;
    req.userId = null;
    next();
  }
}

/**
 * Require admin role
 * Must be used AFTER requireAuth
 */
export function requireAdmin(req, res, next) {
  if (!req.user || req.user.role !== 'admin') {
    return next(ApiError.forbidden('Admin access required'));
  }
  next();
}

/**
 * Generate JWT access token (short-lived)
 * @param {Object} user - Mongoose user document
 * @returns {string} JWT token
 */
export function generateAccessToken(user) {
  return jwt.sign(
    {
      userId: user._id,
      email: user.email,
      role: user.role,
      plan: user.subscription?.plan || 'free',
    },
    env.JWT_SECRET,
    { expiresIn: env.JWT_EXPIRES_IN },
  );
}

/**
 * Generate JWT refresh token (long-lived)
 * @param {Object} user - Mongoose user document
 * @returns {string} JWT refresh token
 */
export function generateRefreshToken(user) {
  return jwt.sign(
    { userId: user._id },
    env.JWT_REFRESH_SECRET,
    { expiresIn: env.JWT_REFRESH_EXPIRES_IN },
  );
}
