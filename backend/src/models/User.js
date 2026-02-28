/**
 * User Model
 * Stores user accounts, authentication, subscription tier, and preferences
 */
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Invalid email format'],
    index: true,
  },
  passwordHash: {
    type: String,
    // Not required for OAuth users
    select: false, // Don't return in queries by default
  },
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    minlength: [2, 'Name must be at least 2 characters'],
    maxlength: [50, 'Name must be at most 50 characters'],
  },
  avatar: {
    type: String,
    default: null,
  },

  // Auth provider
  provider: {
    type: String,
    enum: ['local', 'google', 'apple'],
    default: 'local',
  },
  providerId: {
    type: String,
    default: null, // Google/Apple user ID
  },

  // Email verification
  emailVerified: {
    type: Boolean,
    default: false,
  },
  emailVerifyToken: {
    type: String,
    select: false,
  },
  emailVerifyExpires: {
    type: Date,
    select: false,
  },

  // Password reset
  resetPasswordToken: {
    type: String,
    select: false,
  },
  resetPasswordExpires: {
    type: Date,
    select: false,
  },

  // Subscription & permissions
  subscription: {
    plan: {
      type: String,
      enum: ['free', 'pro'],
      default: 'free',
    },
    credits: {
      type: Number,
      default: 0,
      min: 0,
    },
    aiCreditsUsedToday: {
      type: Number,
      default: 0,
    },
    aiCreditsResetAt: {
      type: Date,
      default: Date.now,
    },
  },

  // User preferences
  settings: {
    language: {
      type: String,
      enum: ['en', 'vi', 'ko'],
      default: 'en',
    },
    theme: {
      type: String,
      enum: ['dark', 'light', 'system'],
      default: 'dark',
    },
    defaultChart: {
      type: String,
      enum: ['candle', 'line', 'area', 'bar'],
      default: 'candle',
    },
    notifications: {
      type: Boolean,
      default: true,
    },
  },

  // Admin controls
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user',
  },
  isBlocked: {
    type: Boolean,
    default: false,
  },
  blockReason: {
    type: String,
    default: null,
  },

  // Refresh token for JWT refresh flow
  refreshToken: {
    type: String,
    select: false,
  },

  lastLoginAt: {
    type: Date,
    default: null,
  },
}, {
  timestamps: true, // createdAt, updatedAt
  toJSON: {
    transform(doc, ret) {
      delete ret.passwordHash;
      delete ret.refreshToken;
      delete ret.__v;
      return ret;
    },
  },
});

// ─── Pre-save: Hash password ─────────────────────────
userSchema.pre('save', async function (next) {
  // Only hash if password is modified
  if (!this.isModified('passwordHash') || !this.passwordHash) return next();
  
  try {
    const salt = await bcrypt.genSalt(12);
    this.passwordHash = await bcrypt.hash(this.passwordHash, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// ─── Methods ─────────────────────────────────────────

/**
 * Compare candidate password with stored hash
 * @param {string} candidatePassword
 * @returns {Promise<boolean>}
 */
userSchema.methods.comparePassword = async function (candidatePassword) {
  if (!this.passwordHash) return false;
  return bcrypt.compare(candidatePassword, this.passwordHash);
};

/**
 * Check if user can use AI today (free tier = 3/day)
 * @returns {boolean}
 */
userSchema.methods.canUseAI = function () {
  if (this.subscription.plan === 'pro') return true;
  
  // Reset counter if new day
  const now = new Date();
  const resetAt = this.subscription.aiCreditsResetAt;
  if (!resetAt || now.toDateString() !== resetAt.toDateString()) {
    this.subscription.aiCreditsUsedToday = 0;
    this.subscription.aiCreditsResetAt = now;
  }
  
  return this.subscription.aiCreditsUsedToday < 3;
};

/**
 * Increment AI usage count
 */
userSchema.methods.useAICredit = function () {
  this.subscription.aiCreditsUsedToday += 1;
  return this.save();
};

// ─── Statics ─────────────────────────────────────────

/**
 * Find user by email (including password for auth)
 */
userSchema.statics.findByEmailForAuth = function (email) {
  return this.findOne({ email: email.toLowerCase() })
    .select('+passwordHash +refreshToken');
};

const User = mongoose.model('User', userSchema);

export default User;
