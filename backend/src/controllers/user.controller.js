/**
 * User Controller
 * Profile management, settings, password change
 */
import User from '../models/User.js';
import { ApiError } from '../middleware/errorHandler.js';
import logger from '../utils/logger.js';

const userController = {
  /**
   * GET /api/users/profile
   * Get current user's full profile
   */
  async getProfile(req, res, next) {
    try {
      const user = await User.findById(req.userId);
      if (!user) throw ApiError.notFound('User not found');

      res.json({
        success: true,
        data: {
          id: user._id,
          email: user.email,
          name: user.name,
          avatar: user.avatar,
          provider: user.provider,
          emailVerified: user.emailVerified,
          subscription: {
            plan: user.subscription.plan,
            credits: user.subscription.credits || 0,
            aiCreditsUsedToday: user.subscription.aiCreditsUsedToday,
          },
          settings: user.settings,
          role: user.role,
          lastLoginAt: user.lastLoginAt,
          createdAt: user.createdAt,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * PUT /api/users/profile
   * Update user profile (name, avatar, settings)
   */
  async updateProfile(req, res, next) {
    try {
      const allowedFields = ['name', 'avatar'];
      const updates = {};

      for (const field of allowedFields) {
        if (req.body[field] !== undefined) {
          updates[field] = req.body[field];
        }
      }

      // Handle nested settings
      if (req.body.settings && typeof req.body.settings === 'object') {
        const allowedSettings = ['language', 'theme', 'defaultChart', 'notifications'];
        for (const key of allowedSettings) {
          if (req.body.settings[key] !== undefined) {
            updates[`settings.${key}`] = req.body.settings[key];
          }
        }
      }

      if (Object.keys(updates).length === 0) {
        throw ApiError.badRequest('No valid fields to update');
      }

      const user = await User.findByIdAndUpdate(
        req.userId,
        { $set: updates },
        { new: true, runValidators: true },
      );

      if (!user) throw ApiError.notFound('User not found');

      res.json({
        success: true,
        data: {
          id: user._id,
          email: user.email,
          name: user.name,
          avatar: user.avatar,
          settings: user.settings,
        },
        message: 'Profile updated successfully',
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * PUT /api/users/change-password
   * Body: { currentPassword, newPassword }
   */
  async changePassword(req, res, next) {
    try {
      const { currentPassword, newPassword } = req.body;

      if (!currentPassword || !newPassword) {
        throw ApiError.badRequest('Current password and new password are required');
      }

      if (newPassword.length < 8) {
        throw ApiError.badRequest('New password must be at least 8 characters');
      }

      // Get user with password hash
      const user = await User.findById(req.userId).select('+passwordHash');
      if (!user) throw ApiError.notFound('User not found');

      // OAuth users can't change password
      if (user.provider !== 'local') {
        throw ApiError.badRequest('Cannot change password for OAuth accounts');
      }

      // Verify current password
      const isValid = await user.comparePassword(currentPassword);
      if (!isValid) {
        throw ApiError.badRequest('Current password is incorrect');
      }

      // Update password
      user.passwordHash = newPassword;
      await user.save(); // pre-save hook will hash it

      logger.info(`Password changed for ${user.email}`);

      res.json({
        success: true,
        message: 'Password changed successfully',
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * DELETE /api/users/account
   * Soft delete — marks account as blocked with reason
   */
  async deleteAccount(req, res, next) {
    try {
      const user = await User.findById(req.userId);
      if (!user) throw ApiError.notFound('User not found');

      user.isBlocked = true;
      user.blockReason = 'Account deleted by user';
      await user.save();

      logger.info(`Account self-deleted: ${user.email}`);

      res.json({
        success: true,
        message: 'Account has been deactivated',
      });
    } catch (error) {
      next(error);
    }
  },
};

export default userController;
