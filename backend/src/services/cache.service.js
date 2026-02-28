/**
 * In-Memory Cache Service
 * Simple Map-based cache with TTL support
 * Used to reduce API call frequency to KIS and Yahoo
 */
import logger from '../utils/logger.js';

class CacheService {
  constructor() {
    this.store = new Map();
    this.hits = 0;
    this.misses = 0;

    // Periodic cleanup every 5 minutes
    this._cleanupInterval = setInterval(() => this.cleanup(), 5 * 60 * 1000);
  }

  /**
   * Get cached value if still valid
   * @param {string} key - Cache key
   * @param {number} ttlMs - Time-to-live in milliseconds
   * @returns {*} Cached data or null
   */
  get(key, ttlMs) {
    const entry = this.store.get(key);
    if (entry && Date.now() - entry.time < ttlMs) {
      this.hits++;
      return entry.data;
    }
    this.misses++;
    return null;
  }

  /**
   * Store value in cache
   * @param {string} key - Cache key
   * @param {*} data - Data to cache
   */
  set(key, data) {
    this.store.set(key, { data, time: Date.now() });
  }

  /**
   * Delete a specific key
   * @param {string} key
   */
  del(key) {
    this.store.delete(key);
  }

  /**
   * Delete all keys matching a prefix
   * @param {string} prefix
   */
  delByPrefix(prefix) {
    for (const key of this.store.keys()) {
      if (key.startsWith(prefix)) {
        this.store.delete(key);
      }
    }
  }

  /**
   * Remove expired entries (older than 30 minutes by default)
   * @param {number} [maxAge=1800000] - Maximum age in ms
   */
  cleanup(maxAge = 30 * 60 * 1000) {
    const now = Date.now();
    let removed = 0;
    for (const [key, entry] of this.store) {
      if (now - entry.time > maxAge) {
        this.store.delete(key);
        removed++;
      }
    }
    if (removed > 0) {
      logger.debug(`Cache cleanup: removed ${removed} expired entries, ${this.store.size} remaining`);
    }
  }

  /**
   * Clear all cache
   */
  clear() {
    this.store.clear();
    logger.debug('Cache cleared');
  }

  /**
   * Get cache statistics
   */
  getStats() {
    return {
      size: this.store.size,
      hits: this.hits,
      misses: this.misses,
      hitRate: this.hits + this.misses > 0
        ? ((this.hits / (this.hits + this.misses)) * 100).toFixed(1) + '%'
        : '0%',
    };
  }

  /**
   * Destroy the cache service (clear interval)
   */
  destroy() {
    clearInterval(this._cleanupInterval);
    this.store.clear();
  }
}

// Singleton instance
const cacheService = new CacheService();
export default cacheService;
