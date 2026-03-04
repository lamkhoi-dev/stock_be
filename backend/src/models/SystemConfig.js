/**
 * System Configuration Model
 * Stores app-wide settings that admin can toggle.
 * Uses a single document pattern (singleton).
 */
import mongoose from 'mongoose';

const systemConfigSchema = new mongoose.Schema({
  // Singleton key — always 'main'
  _id: {
    type: String,
    default: 'main',
  },

  // ─── Feature Flags (admin can toggle these) ─────────
  features: {
    aiAnalysis: { type: Boolean, default: true },       // Enable/disable AI analysis
    proAnalysis: { type: Boolean, default: true },       // Enable/disable Pro-level AI
    newsTab: { type: Boolean, default: true },           // Enable/disable news tab
    websocket: { type: Boolean, default: true },         // Enable/disable real-time WS
    registration: { type: Boolean, default: true },      // Enable/disable new registrations
    watchlist: { type: Boolean, default: true },         // Enable/disable watchlist feature
  },

  // ─── Plan Limits ────────────────────────────────────
  free: {
    dailyBasicLimit: { type: Number, default: 3 },
    maxWatchlist: { type: Number, default: 10 },
    wsPollInterval: { type: String, default: '30s' },
    maxWsSubscriptions: { type: Number, default: 5 },
  },

  pro: {
    dailyBasicLimit: { type: String, default: 'unlimited' },
    maxWatchlist: { type: String, default: 'unlimited' },
    wsPollInterval: { type: String, default: '10s' },
    maxWsSubscriptions: { type: Number, default: 20 },
    creditCost: {
      geminiPro: { type: Number, default: 10 },
      openai: { type: Number, default: 20 },
    },
  },

  // ─── Credit Packages ────────────────────────────────
  creditPackages: {
    type: [{
      credits: Number,
      price: Number,
      currency: { type: String, default: 'KRW' },
    }],
    default: [
      { credits: 100, price: 1000, currency: 'KRW' },
      { credits: 500, price: 5000, currency: 'KRW' },
      { credits: 2000, price: 15000, currency: 'KRW' },
    ],
  },

  // ─── AI API Keys (encrypted at rest via MongoDB) ────
  aiKeys: {
    geminiApiKey: { type: String, default: '' },
    groqApiKey: { type: String, default: '' },
  },

  // ─── Maintenance ────────────────────────────────────
  maintenance: {
    enabled: { type: Boolean, default: false },
    message: { type: String, default: 'System is under maintenance. Please try again later.' },
  },
}, {
  timestamps: true,
  collection: 'system_config',
});

/**
 * Get the singleton config document. Creates one with defaults if none exists.
 */
systemConfigSchema.statics.getConfig = async function () {
  let config = await this.findById('main').lean();
  if (!config) {
    config = await this.create({ _id: 'main' });
    config = config.toObject();
  }
  return config;
};

/**
 * Update config (partial update).
 */
systemConfigSchema.statics.updateConfig = async function (updates) {
  // Flatten nested keys for $set so we don't overwrite entire sub-docs
  const flatUpdates = {};
  const flatten = (obj, prefix = '') => {
    for (const [key, val] of Object.entries(obj)) {
      const path = prefix ? `${prefix}.${key}` : key;
      if (val !== null && typeof val === 'object' && !Array.isArray(val) && !(val instanceof Date)) {
        flatten(val, path);
      } else {
        flatUpdates[path] = val;
      }
    }
  };
  flatten(updates);

  // Remove protected fields
  delete flatUpdates._id;
  delete flatUpdates.createdAt;
  delete flatUpdates.updatedAt;

  const config = await this.findByIdAndUpdate(
    'main',
    { $set: flatUpdates },
    { new: true, upsert: true, runValidators: true },
  ).lean();

  return config;
};

const SystemConfig = mongoose.model('SystemConfig', systemConfigSchema);

export default SystemConfig;
