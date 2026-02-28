/**
 * System Log Model
 * Stores backend logs for monitoring (TTL 14 days auto-delete)
 */
import mongoose from 'mongoose';

const systemLogSchema = new mongoose.Schema({
  level: {
    type: String,
    enum: ['error', 'warn', 'info', 'debug'],
    required: true,
    index: true,
  },
  source: {
    type: String, // e.g. 'kis.service', 'auth.controller', 'websocket'
    required: true,
    trim: true,
  },
  message: {
    type: String,
    required: true,
  },
  stack: {
    type: String,
    default: null,
  },
  // Additional metadata (request info, user info, etc.)
  meta: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
  // Optional: which user triggered this
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
  },
  // Request context
  request: {
    method: String,
    url: String,
    ip: String,
    userAgent: String,
  },
}, {
  timestamps: true,
});

// TTL index: auto-delete after 14 days
systemLogSchema.index({ createdAt: 1 }, { expireAfterSeconds: 14 * 24 * 60 * 60 });

// Query indexes
systemLogSchema.index({ level: 1, createdAt: -1 });
systemLogSchema.index({ source: 1, createdAt: -1 });

// ─── Statics ─────────────────────────────────────────

/**
 * Create log entry
 */
systemLogSchema.statics.log = function (level, source, message, meta = {}) {
  return this.create({ level, source, message, meta });
};

/**
 * Get recent logs with filtering
 */
systemLogSchema.statics.getRecent = function ({ level, source, limit = 50, page = 1 } = {}) {
  const filter = {};
  if (level) filter.level = level;
  if (source) filter.source = new RegExp(source, 'i');
  
  return this.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit);
};

/**
 * Count errors in last N hours
 */
systemLogSchema.statics.countErrors = function (hours = 24) {
  const since = new Date(Date.now() - hours * 60 * 60 * 1000);
  return this.countDocuments({ level: 'error', createdAt: { $gte: since } });
};

const SystemLog = mongoose.model('SystemLog', systemLogSchema);

export default SystemLog;
