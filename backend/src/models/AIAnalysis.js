/**
 * AI Analysis Model
 * Stores AI-generated stock analysis results
 */
import mongoose from 'mongoose';

const aiAnalysisSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User ID is required'],
    index: true,
  },
  symbol: {
    type: String,
    required: [true, 'Stock symbol is required'],
    trim: true,
    uppercase: true,
  },
  stockName: {
    type: String,
    default: '',
  },

  // Analysis level: basic (free) or pro (paid)
  level: {
    type: String,
    enum: ['basic', 'pro'],
    default: 'basic',
  },

  // AI model used
  model: {
    type: String,
    enum: ['gemini', 'openai', 'groq', 'unknown'],
    default: 'gemini',
  },

  // The analysis result
  analysis: {
    // Overall signal: buy / sell / hold / neutral
    signal: {
      type: String,
      enum: ['strong_buy', 'buy', 'hold', 'sell', 'strong_sell', 'neutral'],
      default: 'neutral',
    },
    // Confidence score 0-100
    confidence: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
    },
    // Summary text (markdown supported)
    summary: {
      type: String,
      default: '',
    },
    // Detailed analysis sections
    technicalAnalysis: {
      type: String,
      default: '',
    },
    fundamentalAnalysis: {
      type: String,
      default: '',
    },
    riskAssessment: {
      type: String,
      default: '',
    },
    // Key support/resistance levels
    keyLevels: {
      support: [Number],
      resistance: [Number],
    },
    // Target prices
    targets: {
      upside: Number,
      downside: Number,
    },
  },

  // Input data snapshot (what was fed to AI)
  inputData: {
    price: Number,
    change: Number,
    changePercent: Number,
    volume: Number,
    indicators: {
      rsi: Number,
      macd: Number,
      stochK: Number,
    },
  },

  // Credit tracking
  creditsUsed: {
    type: Number,
    default: 1,
  },

  // Processing info
  processingTimeMs: {
    type: Number,
    default: 0,
  },
  tokensUsed: {
    type: Number,
    default: 0,
  },
}, {
  timestamps: true,
});

// Index for querying user's analyses
aiAnalysisSchema.index({ userId: 1, createdAt: -1 });
// Index for querying by symbol
aiAnalysisSchema.index({ symbol: 1, createdAt: -1 });

// ─── Statics ─────────────────────────────────────────

/**
 * Get latest analysis for a symbol by a user
 */
aiAnalysisSchema.statics.getLatest = function (userId, symbol) {
  return this.findOne({ userId, symbol: symbol.toUpperCase() })
    .sort({ createdAt: -1 });
};

/**
 * Get user's analysis history
 */
aiAnalysisSchema.statics.getUserHistory = function (userId, limit = 20) {
  return this.find({ userId })
    .sort({ createdAt: -1 })
    .limit(limit)
    .select('symbol stockName level analysis.signal analysis.confidence createdAt');
};

const AIAnalysis = mongoose.model('AIAnalysis', aiAnalysisSchema);

export default AIAnalysis;
