/**
 * Authentication Controller
 * Handles register, login, OAuth, password reset, email verification, token refresh
 */
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { OAuth2Client } from 'google-auth-library';
import User from '../models/User.js';
import env from '../config/env.js';
import { ApiError } from '../middleware/errorHandler.js';
import { generateAccessToken, generateRefreshToken } from '../middleware/auth.middleware.js';
import emailService from '../services/email.service.js';
import logger from '../utils/logger.js';

const googleClient = new OAuth2Client(env.GOOGLE_CLIENT_ID);

/**
 * POST /api/auth/register
 * Create new user account with email/password
 */
export async function register(req, res, next) {
  try {
    const { email, password, name } = req.body;

    // Check if user exists
    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      throw ApiError.badRequest('Email already registered');
    }

    // Create user
    const user = new User({
      email: email.toLowerCase(),
      passwordHash: password, // Pre-save hook will hash it
      name,
      provider: 'local',
    });

    // Generate email verification token
    const verifyToken = crypto.randomBytes(32).toString('hex');
    user.emailVerifyToken = crypto.createHash('sha256').update(verifyToken).digest('hex');
    user.emailVerifyExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24h

    await user.save();

    // Send verification email (non-blocking)
    emailService.sendVerificationEmail(email, name, verifyToken).catch(err => {
      logger.error('Failed to send verification email:', err);
    });

    // Auto-login: generate tokens so the client can proceed immediately
    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);
    user.refreshToken = refreshToken;
    user.lastLoginAt = new Date();
    await user.save();

    res.status(201).json({
      success: true,
      message: 'Account created successfully.',
      data: {
        accessToken,
        refreshToken,
        user: {
          id: user._id,
          email: user.email,
          name: user.name,
          avatar: user.avatar,
          subscription: user.subscription,
          settings: user.settings,
          role: user.role,
          emailVerified: user.emailVerified,
        },
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/login
 * Login with email/password, returns JWT pair
 */
export async function login(req, res, next) {
  try {
    const { email, password } = req.body;

    // Find user with password field
    const user = await User.findByEmailForAuth(email);
    if (!user) {
      throw ApiError.unauthorized('Invalid email or password');
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      throw ApiError.unauthorized('Invalid email or password');
    }

    // Check blocked
    if (user.isBlocked) {
      throw ApiError.forbidden(`Account blocked${user.blockReason ? `: ${user.blockReason}` : ''}`);
    }

    // Generate tokens
    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    // Save refresh token
    user.refreshToken = refreshToken;
    user.lastLoginAt = new Date();
    await user.save();

    res.json({
      success: true,
      data: {
        accessToken,
        refreshToken,
        user: {
          id: user._id,
          email: user.email,
          name: user.name,
          avatar: user.avatar,
          subscription: user.subscription,
          settings: user.settings,
          role: user.role,
          emailVerified: user.emailVerified,
        },
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/google
 * Google OAuth login/register
 */
export async function googleAuth(req, res, next) {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      throw ApiError.badRequest('Google ID token required');
    }

    // Verify Google token
    let payload;
    try {
      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: env.GOOGLE_CLIENT_ID,
      });
      payload = ticket.getPayload();
    } catch {
      throw ApiError.unauthorized('Invalid Google token');
    }

    const { sub: googleId, email, name, picture } = payload;

    // Find or create user
    let user = await User.findOne({
      $or: [
        { providerId: googleId, provider: 'google' },
        { email: email.toLowerCase() },
      ],
    });

    if (user) {
      // Update existing user
      if (user.provider !== 'google') {
        user.provider = 'google';
        user.providerId = googleId;
      }
      if (!user.avatar && picture) user.avatar = picture;
      user.emailVerified = true;
    } else {
      // Create new user
      user = new User({
        email: email.toLowerCase(),
        name: name || email.split('@')[0],
        avatar: picture || null,
        provider: 'google',
        providerId: googleId,
        emailVerified: true,
      });
    }

    // Check blocked
    if (user.isBlocked) {
      throw ApiError.forbidden('Account blocked');
    }

    // Generate tokens
    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);
    user.refreshToken = refreshToken;
    user.lastLoginAt = new Date();
    await user.save();

    res.json({
      success: true,
      data: {
        accessToken,
        refreshToken,
        user: {
          id: user._id,
          email: user.email,
          name: user.name,
          avatar: user.avatar,
          subscription: user.subscription,
          settings: user.settings,
          role: user.role,
          emailVerified: user.emailVerified,
        },
        isNewUser: user.createdAt === user.updatedAt,
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/apple
 * Apple Sign-In login/register
 */
export async function appleAuth(req, res, next) {
  try {
    const { identityToken, user: appleUser } = req.body;
    if (!identityToken) {
      throw ApiError.badRequest('Apple identity token required');
    }

    // Decode Apple JWT (basic validation — in production use apple-signin-auth)
    let decoded;
    try {
      decoded = jwt.decode(identityToken, { complete: true });
    } catch {
      throw ApiError.unauthorized('Invalid Apple token');
    }

    const appleId = decoded?.payload?.sub;
    const email = decoded?.payload?.email || appleUser?.email;
    const name = appleUser?.name
      ? `${appleUser.name.firstName || ''} ${appleUser.name.lastName || ''}`.trim()
      : null;

    if (!appleId) {
      throw ApiError.unauthorized('Invalid Apple token payload');
    }

    // Find or create user
    let user = await User.findOne({
      $or: [
        { providerId: appleId, provider: 'apple' },
        ...(email ? [{ email: email.toLowerCase() }] : []),
      ],
    });

    if (user) {
      if (user.provider !== 'apple') {
        user.provider = 'apple';
        user.providerId = appleId;
      }
      user.emailVerified = true;
    } else {
      user = new User({
        email: email?.toLowerCase() || `apple_${appleId.substring(0, 8)}@private.relay`,
        name: name || 'Apple User',
        provider: 'apple',
        providerId: appleId,
        emailVerified: true,
      });
    }

    if (user.isBlocked) {
      throw ApiError.forbidden('Account blocked');
    }

    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);
    user.refreshToken = refreshToken;
    user.lastLoginAt = new Date();
    await user.save();

    res.json({
      success: true,
      data: {
        accessToken,
        refreshToken,
        user: {
          id: user._id,
          email: user.email,
          name: user.name,
          avatar: user.avatar,
          subscription: user.subscription,
          settings: user.settings,
          role: user.role,
        },
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/verify-email
 */
export async function verifyEmail(req, res, next) {
  try {
    const { token } = req.body;
    if (!token) {
      throw ApiError.badRequest('Verification token required');
    }

    const hashedToken = crypto.createHash('sha256').update(token).digest('hex');
    const user = await User.findOne({
      emailVerifyToken: hashedToken,
      emailVerifyExpires: { $gt: Date.now() },
    }).select('+emailVerifyToken +emailVerifyExpires');

    if (!user) {
      throw ApiError.badRequest('Invalid or expired verification token');
    }

    user.emailVerified = true;
    user.emailVerifyToken = undefined;
    user.emailVerifyExpires = undefined;
    await user.save();

    res.json({
      success: true,
      message: 'Email verified successfully',
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/forgot-password
 */
export async function forgotPassword(req, res, next) {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email: email.toLowerCase() })
      .select('+resetPasswordToken +resetPasswordExpires');

    // Always return success to prevent email enumeration
    if (!user) {
      return res.json({
        success: true,
        message: 'If that email exists, a password reset link has been sent.',
      });
    }

    // Generate reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    user.resetPasswordToken = crypto.createHash('sha256').update(resetToken).digest('hex');
    user.resetPasswordExpires = new Date(Date.now() + 60 * 60 * 1000); // 1 hour
    await user.save();

    // Send email
    emailService.sendPasswordResetEmail(email, user.name, resetToken).catch(err => {
      logger.error('Failed to send reset email:', err);
    });

    res.json({
      success: true,
      message: 'If that email exists, a password reset link has been sent.',
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/reset-password
 */
export async function resetPassword(req, res, next) {
  try {
    const { token, password } = req.body;
    if (!token || !password) {
      throw ApiError.badRequest('Token and new password are required');
    }

    const hashedToken = crypto.createHash('sha256').update(token).digest('hex');
    const user = await User.findOne({
      resetPasswordToken: hashedToken,
      resetPasswordExpires: { $gt: Date.now() },
    }).select('+resetPasswordToken +resetPasswordExpires +passwordHash');

    if (!user) {
      throw ApiError.badRequest('Invalid or expired reset token');
    }

    user.passwordHash = password; // Pre-save hook will hash
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    res.json({
      success: true,
      message: 'Password reset successfully. Please login with your new password.',
    });
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/refresh-token
 */
export async function refreshTokenHandler(req, res, next) {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      throw ApiError.badRequest('Refresh token required');
    }

    // Verify refresh token
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET);
    } catch {
      throw ApiError.unauthorized('Invalid or expired refresh token');
    }

    // Find user and check stored refresh token matches
    const user = await User.findById(decoded.userId).select('+refreshToken');
    if (!user || user.refreshToken !== refreshToken) {
      throw ApiError.unauthorized('Invalid refresh token');
    }

    if (user.isBlocked) {
      throw ApiError.forbidden('Account blocked');
    }

    // Generate new token pair
    const newAccessToken = generateAccessToken(user);
    const newRefreshToken = generateRefreshToken(user);
    user.refreshToken = newRefreshToken;
    await user.save();

    res.json({
      success: true,
      data: {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      },
    });
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/auth/me
 * Get current user profile
 */
export async function getMe(req, res) {
  res.json({
    success: true,
    data: {
      user: req.user,
    },
  });
}

/**
 * POST /api/auth/logout
 * Invalidate refresh token
 */
export async function logout(req, res, next) {
  try {
    const user = await User.findById(req.userId).select('+refreshToken');
    if (user) {
      user.refreshToken = undefined;
      await user.save();
    }
    res.json({ success: true, message: 'Logged out' });
  } catch (error) {
    next(error);
  }
}
