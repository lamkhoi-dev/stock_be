/**
 * Watchlist Model
 * Stores user's saved stock symbols with ordering
 */
import mongoose from 'mongoose';

const watchlistSchema = new mongoose.Schema({
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
    maxlength: 20,
  },
  // Stock name snapshot (for display without API call)
  name: {
    type: String,
    trim: true,
    default: '',
  },
  nameKo: {
    type: String,
    trim: true,
    default: '', // 삼성전자
  },
  market: {
    type: String,
    enum: ['KOSPI', 'KOSDAQ', 'OTHER'],
    default: 'KOSPI',
  },
  // Display order in watchlist
  order: {
    type: Number,
    default: 0,
  },
  // Optional: user's notes on this stock
  notes: {
    type: String,
    maxlength: 500,
    default: '',
  },
  addedAt: {
    type: Date,
    default: Date.now,
  },
}, {
  timestamps: true,
});

// Compound unique index: one user can't save the same symbol twice
watchlistSchema.index({ userId: 1, symbol: 1 }, { unique: true });

// Sort by order by default
watchlistSchema.index({ userId: 1, order: 1 });

// ─── Statics ─────────────────────────────────────────

/**
 * Get user's watchlist, sorted by order
 * @param {ObjectId} userId
 * @returns {Promise<Array>}
 */
watchlistSchema.statics.getByUser = function (userId) {
  return this.find({ userId }).sort({ order: 1, addedAt: -1 });
};

/**
 * Count user's watchlist items (for free tier limit check)
 * @param {ObjectId} userId
 * @returns {Promise<number>}
 */
watchlistSchema.statics.countByUser = function (userId) {
  return this.countDocuments({ userId });
};

/**
 * Check if symbol is in user's watchlist
 * @param {ObjectId} userId
 * @param {string} symbol
 * @returns {Promise<boolean>}
 */
watchlistSchema.statics.isWatched = async function (userId, symbol) {
  const item = await this.findOne({ userId, symbol: symbol.toUpperCase() });
  return !!item;
};

const Watchlist = mongoose.model('Watchlist', watchlistSchema);

export default Watchlist;
