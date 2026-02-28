/**
 * Admin Controller
 * User management, system config, logs, dashboard stats
 * All endpoints require admin role
 */
import User from '../models/User.js';
import AIAnalysis from '../models/AIAnalysis.js';
import SystemLog from '../models/SystemLog.js';
import Watchlist from '../models/Watchlist.js';
import { getWSStats } from '../services/websocket.service.js';
import cacheService from '../services/cache.service.js';
import { ApiError } from '../middleware/errorHandler.js';
import logger from '../utils/logger.js';

const adminController = {
  // ═══════════════════════════════════════════════════
  //  USER MANAGEMENT
  // ═══════════════════════════════════════════════════

  /**
   * GET /api/admin/users
   * Query: ?page=1&limit=20&search=&plan=&status=
   */
  async getUsers(req, res, next) {
    try {
      const page = Math.max(1, parseInt(req.query.page) || 1);
      const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 20));
      const { search, plan, status } = req.query;

      const filter = {};

      // Text search (name or email)
      if (search) {
        filter.$or = [
          { name: { $regex: search, $options: 'i' } },
          { email: { $regex: search, $options: 'i' } },
        ];
      }

      // Filter by plan
      if (plan && ['free', 'pro'].includes(plan)) {
        filter['subscription.plan'] = plan;
      }

      // Filter by status
      if (status === 'active') filter.isBlocked = false;
      if (status === 'blocked') filter.isBlocked = true;

      const [users, total] = await Promise.all([
        User.find(filter)
          .sort({ createdAt: -1 })
          .skip((page - 1) * limit)
          .limit(limit)
          .select('email name avatar subscription.plan subscription.credits role isBlocked lastLoginAt createdAt'),
        User.countDocuments(filter),
      ]);

      res.json({
        success: true,
        data: {
          users,
          pagination: {
            page,
            limit,
            total,
            pages: Math.ceil(total / limit),
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/admin/users/:id
   * Get detailed user info for admin
   */
  async getUserDetail(req, res, next) {
    try {
      const user = await User.findById(req.params.id);
      if (!user) throw ApiError.notFound('User not found');

      // Get additional stats
      const [watchlistCount, analysisCount, recentAnalyses] = await Promise.all([
        Watchlist.countByUser(user._id),
        AIAnalysis.countDocuments({ userId: user._id }),
        AIAnalysis.find({ userId: user._id })
          .sort({ createdAt: -1 })
          .limit(5)
          .select('symbol level analysis.signal createdAt'),
      ]);

      res.json({
        success: true,
        data: {
          user: {
            id: user._id,
            email: user.email,
            name: user.name,
            avatar: user.avatar,
            provider: user.provider,
            emailVerified: user.emailVerified,
            subscription: user.subscription,
            settings: user.settings,
            role: user.role,
            isBlocked: user.isBlocked,
            blockReason: user.blockReason,
            lastLoginAt: user.lastLoginAt,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
          },
          stats: {
            watchlistCount,
            analysisCount,
            recentAnalyses,
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * PUT /api/admin/users/:id/block
   * Body: { blocked: true/false, reason?: string }
   */
  async blockUser(req, res, next) {
    try {
      const { blocked, reason } = req.body;
      if (typeof blocked !== 'boolean') {
        throw ApiError.badRequest('blocked must be a boolean');
      }

      const user = await User.findById(req.params.id);
      if (!user) throw ApiError.notFound('User not found');

      // Can't block admin
      if (user.role === 'admin') {
        throw ApiError.forbidden('Cannot block admin users');
      }

      user.isBlocked = blocked;
      user.blockReason = blocked ? (reason || 'Blocked by admin') : null;
      await user.save();

      logger.info(`Admin ${blocked ? 'blocked' : 'unblocked'} user: ${user.email}`);

      res.json({
        success: true,
        message: `User ${blocked ? 'blocked' : 'unblocked'} successfully`,
        data: { isBlocked: user.isBlocked, blockReason: user.blockReason },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * PUT /api/admin/users/:id/subscription
   * Body: { plan?: 'free'|'pro', credits?: number, addCredits?: number }
   */
  async updateSubscription(req, res, next) {
    try {
      const { plan, credits, addCredits } = req.body;
      const user = await User.findById(req.params.id);
      if (!user) throw ApiError.notFound('User not found');

      if (plan && ['free', 'pro'].includes(plan)) {
        user.subscription.plan = plan;
      }

      if (typeof credits === 'number' && credits >= 0) {
        user.subscription.credits = credits;
      }

      if (typeof addCredits === 'number' && addCredits > 0) {
        user.subscription.credits = (user.subscription.credits || 0) + addCredits;
      }

      await user.save();

      logger.info(`Admin updated subscription for ${user.email}: plan=${user.subscription.plan}, credits=${user.subscription.credits}`);

      res.json({
        success: true,
        message: 'Subscription updated',
        data: {
          plan: user.subscription.plan,
          credits: user.subscription.credits,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  // ═══════════════════════════════════════════════════
  //  SYSTEM CONFIG
  // ═══════════════════════════════════════════════════

  /**
   * GET /api/admin/config
   * Returns current system configuration (non-sensitive)
   */
  async getConfig(req, res, next) {
    try {
      res.json({
        success: true,
        data: {
          free: {
            dailyBasicLimit: 3,
            maxWatchlist: 10,
            wsPollInterval: '30s',
            maxWsSubscriptions: 5,
          },
          pro: {
            dailyBasicLimit: 'unlimited',
            maxWatchlist: 'unlimited',
            wsPollInterval: '10s',
            maxWsSubscriptions: 20,
            creditCost: {
              geminiPro: 10,
              openai: 20,
            },
          },
          creditPackages: [
            { credits: 100, price: 1000, currency: 'KRW' },
            { credits: 500, price: 5000, currency: 'KRW' },
            { credits: 2000, price: 15000, currency: 'KRW' },
          ],
          ai: {
            hasGemini: !!process.env.GEMINI_API_KEY,
            hasOpenAI: !!process.env.OPENAI_API_KEY,
          },
          cache: cacheService.getStats(),
        },
      });
    } catch (error) {
      next(error);
    }
  },

  // ═══════════════════════════════════════════════════
  //  LOGS
  // ═══════════════════════════════════════════════════

  /**
   * GET /api/admin/logs
   * Query: ?level=&source=&page=1&limit=50
   */
  async getLogs(req, res, next) {
    try {
      const page = Math.max(1, parseInt(req.query.page) || 1);
      const limit = Math.min(100, Math.max(1, parseInt(req.query.limit) || 50));
      const { level, source } = req.query;

      const filter = {};
      if (level && ['error', 'warn', 'info', 'debug'].includes(level)) filter.level = level;
      if (source) filter.source = { $regex: source, $options: 'i' };

      const [logs, total] = await Promise.all([
        SystemLog.find(filter)
          .sort({ createdAt: -1 })
          .skip((page - 1) * limit)
          .limit(limit),
        SystemLog.countDocuments(filter),
      ]);

      res.json({
        success: true,
        data: {
          logs,
          pagination: { page, limit, total, pages: Math.ceil(total / limit) },
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/admin/logs/export
   * Export logs as CSV
   * Query: ?level=&source=&days=7
   */
  async exportLogs(req, res, next) {
    try {
      const days = Math.max(1, Math.min(30, parseInt(req.query.days) || 7));
      const { level, source } = req.query;

      const filter = {
        createdAt: { $gte: new Date(Date.now() - days * 24 * 60 * 60 * 1000) },
      };
      if (level) filter.level = level;
      if (source) filter.source = { $regex: source, $options: 'i' };

      const logs = await SystemLog.find(filter)
        .sort({ createdAt: -1 })
        .limit(10000)
        .lean();

      // Build CSV
      const headers = ['Timestamp', 'Level', 'Source', 'Message'];
      const rows = logs.map(log => [
        log.createdAt?.toISOString() || '',
        log.level || '',
        log.source || '',
        `"${(log.message || '').replace(/"/g, '""')}"`,
      ]);

      const csv = [headers.join(','), ...rows.map(r => r.join(','))].join('\n');

      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename=logs_${days}d_${Date.now()}.csv`);
      res.send(csv);
    } catch (error) {
      next(error);
    }
  },

  // ═══════════════════════════════════════════════════
  //  DASHBOARD STATS
  // ═══════════════════════════════════════════════════

  /**
   * GET /api/admin/stats
   * Dashboard statistics
   */
  async getStats(req, res, next) {
    try {
      const now = new Date();
      const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());

      const [
        totalUsers,
        activeUsers,
        blockedUsers,
        proUsers,
        todayAnalyses,
        totalAnalyses,
        todaySignups,
        recentErrors,
      ] = await Promise.all([
        User.countDocuments(),
        User.countDocuments({ isBlocked: false }),
        User.countDocuments({ isBlocked: true }),
        User.countDocuments({ 'subscription.plan': 'pro' }),
        AIAnalysis.countDocuments({ createdAt: { $gte: todayStart } }),
        AIAnalysis.countDocuments(),
        User.countDocuments({ createdAt: { $gte: todayStart } }),
        SystemLog.countDocuments({ level: 'error', createdAt: { $gte: todayStart } }),
      ]);

      // WebSocket stats
      let wsStats;
      try {
        wsStats = getWSStats();
      } catch {
        wsStats = { totalConnections: 0, authenticatedConnections: 0, uniqueSymbolsWatched: 0 };
      }

      res.json({
        success: true,
        data: {
          users: {
            total: totalUsers,
            active: activeUsers,
            blocked: blockedUsers,
            pro: proUsers,
            todaySignups,
          },
          ai: {
            todayAnalyses,
            totalAnalyses,
          },
          websocket: wsStats,
          system: {
            todayErrors: recentErrors,
            cache: cacheService.getStats(),
            uptime: Math.floor(process.uptime()),
            memoryUsage: {
              rss: Math.round(process.memoryUsage().rss / 1024 / 1024),
              heap: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
            },
          },
        },
      });
    } catch (error) {
      next(error);
    }
  },
};

export default adminController;
