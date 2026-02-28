/**
 * AI Analysis Controller
 * Handles AI-powered stock analysis, history, and credit management
 */
import aiService from '../services/ai.service.js';
import AIAnalysis from '../models/AIAnalysis.js';
import User from '../models/User.js';
import { ApiError } from '../middleware/errorHandler.js';
import logger from '../utils/logger.js';

const aiController = {
  /**
   * POST /api/ai/analyze
   * Body: { symbol, level: 'basic'|'pro', model?: 'gemini'|'openai' }
   * Requires auth
   */
  async analyze(req, res, next) {
    try {
      const { symbol, level = 'basic', model = 'gemini' } = req.body;

      if (!symbol) {
        throw ApiError.badRequest('Symbol is required');
      }
      if (!['basic', 'pro'].includes(level)) {
        throw ApiError.badRequest('Level must be "basic" or "pro"');
      }
      if (!['gemini', 'openai'].includes(model)) {
        throw ApiError.badRequest('Model must be "gemini" or "openai"');
      }

      // Get fresh user with subscription data
      const user = await User.findById(req.userId);
      if (!user) throw ApiError.unauthorized('User not found');

      // Check credits / quota
      const creditCheck = aiService.checkCredits(user, level, model);
      if (!creditCheck.allowed) {
        throw ApiError.forbidden(creditCheck.reason);
      }

      // Perform analysis
      let result;
      if (level === 'basic') {
        result = await aiService.analyzeBasic(symbol);
      } else {
        result = await aiService.analyzePro(symbol, model);
      }

      // Save to database
      const analysis = await AIAnalysis.create({
        userId: req.userId,
        symbol: result.symbol,
        stockName: result.stockName,
        level: result.level,
        model: result.model,
        analysis: result.analysis,
        inputData: result.inputData,
        creditsUsed: result.creditsUsed,
        processingTimeMs: result.processingTimeMs,
        tokensUsed: result.tokensUsed,
      });

      // Deduct credits if applicable
      if (level === 'basic' && user.subscription.plan === 'free') {
        // Reset counter if new day
        const now = new Date();
        const resetAt = user.subscription.aiCreditsResetAt;
        if (!resetAt || now.toDateString() !== new Date(resetAt).toDateString()) {
          user.subscription.aiCreditsUsedToday = 0;
          user.subscription.aiCreditsResetAt = now;
        }
        user.subscription.aiCreditsUsedToday += 1;
        await user.save();
      } else if (level === 'pro') {
        user.subscription.credits = (user.subscription.credits || 0) - result.creditsUsed;
        await user.save();
      }

      logger.info(`AI analysis: ${result.level} for ${result.symbol} by ${user.email} (${result.processingTimeMs}ms)`);

      res.json({
        success: true,
        data: {
          id: analysis._id,
          symbol: result.symbol,
          stockName: result.stockName,
          level: result.level,
          model: result.model,
          analysis: result.analysis,
          strategy: result.strategy,
          timeframe: result.timeframe,
          processingTimeMs: result.processingTimeMs,
          creditsUsed: result.creditsUsed,
          creditsRemaining: creditCheck.creditsRemaining,
        },
      });
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/ai/history
   * Query: ?page=1&limit=20&symbol=005930
   * Requires auth
   */
  async getHistory(req, res, next) {
    try {
      const page = Math.max(1, parseInt(req.query.page) || 1);
      const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 20));
      const { symbol } = req.query;

      const filter = { userId: req.userId };
      if (symbol) filter.symbol = symbol.toUpperCase().replace(/\.(KS|KQ)$/i, '');

      const [analyses, total] = await Promise.all([
        AIAnalysis.find(filter)
          .sort({ createdAt: -1 })
          .skip((page - 1) * limit)
          .limit(limit)
          .select('symbol stockName level model analysis.signal analysis.confidence analysis.summary processingTimeMs creditsUsed createdAt'),
        AIAnalysis.countDocuments(filter),
      ]);

      res.json({
        success: true,
        data: {
          analyses,
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
   * GET /api/ai/credits
   * Returns user's credit info and usage stats
   * Requires auth
   */
  async getCredits(req, res, next) {
    try {
      const user = await User.findById(req.userId);
      if (!user) throw ApiError.unauthorized('User not found');

      const plan = user.subscription?.plan || 'free';
      let dailyUsed = user.subscription?.aiCreditsUsedToday || 0;

      // Reset if new day
      const now = new Date();
      const resetAt = user.subscription?.aiCreditsResetAt;
      if (!resetAt || now.toDateString() !== new Date(resetAt).toDateString()) {
        dailyUsed = 0;
      }

      // Count total analyses
      const [totalAnalyses, todayAnalyses] = await Promise.all([
        AIAnalysis.countDocuments({ userId: req.userId }),
        AIAnalysis.countDocuments({
          userId: req.userId,
          createdAt: {
            $gte: new Date(now.getFullYear(), now.getMonth(), now.getDate()),
          },
        }),
      ]);

      const credits = {
        plan,
        basic: {
          dailyLimit: plan === 'pro' ? Infinity : 3,
          dailyUsed,
          dailyRemaining: plan === 'pro' ? Infinity : Math.max(0, 3 - dailyUsed),
        },
        pro: {
          credits: user.subscription?.credits || 0,
          costGemini: 10,
          costOpenAI: 20,
          lowCreditWarning: (user.subscription?.credits || 0) < 50,
        },
        stats: {
          totalAnalyses,
          todayAnalyses,
        },
        packages: [
          { credits: 100, price: 1000, currency: 'KRW', label: '100 Credits' },
          { credits: 500, price: 5000, currency: 'KRW', label: '500 Credits' },
          { credits: 2000, price: 15000, currency: 'KRW', label: '2000 Credits' },
        ],
      };

      res.json({ success: true, data: credits });
    } catch (error) {
      next(error);
    }
  },

  /**
   * GET /api/ai/analysis/:id
   * Get a specific analysis by ID
   * Requires auth
   */
  async getAnalysis(req, res, next) {
    try {
      const analysis = await AIAnalysis.findOne({
        _id: req.params.id,
        userId: req.userId,
      });

      if (!analysis) {
        throw ApiError.notFound('Analysis not found');
      }

      res.json({ success: true, data: analysis });
    } catch (error) {
      next(error);
    }
  },
};

export default aiController;
