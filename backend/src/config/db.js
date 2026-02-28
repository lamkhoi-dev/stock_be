/**
 * MongoDB Connection Configuration
 * Uses Mongoose with retry logic and event listeners
 */
import mongoose from 'mongoose';
import env from './env.js';

/**
 * Connect to MongoDB with retry logic
 * @param {number} retries - Number of retries before giving up
 */
export async function connectDB(retries = 5) {
  const options = {
    // Connection pool
    maxPoolSize: 10,
    minPoolSize: 2,
    // Timeouts
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000,
    // Enable keepAlive
    heartbeatFrequencyMS: 10000,
  };

  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      await mongoose.connect(env.MONGODB_URI, options);
      console.log(`✅ MongoDB connected successfully (${env.isDev ? 'development' : 'production'})`);
      break;
    } catch (error) {
      console.error(`❌ MongoDB connection attempt ${attempt}/${retries} failed:`, error.message);
      if (attempt === retries) {
        console.error('💀 All MongoDB connection attempts exhausted. Exiting...');
        process.exit(1);
      }
      // Wait before retrying: 2s, 4s, 8s, 16s, 32s
      const delay = Math.min(2000 * Math.pow(2, attempt - 1), 30000);
      console.log(`⏳ Retrying in ${delay / 1000}s...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  // Connection event listeners
  mongoose.connection.on('error', (err) => {
    console.error('❌ MongoDB connection error:', err.message);
  });

  mongoose.connection.on('disconnected', () => {
    console.warn('⚠️  MongoDB disconnected');
  });

  mongoose.connection.on('reconnected', () => {
    console.log('🔄 MongoDB reconnected');
  });

  // Graceful shutdown
  const gracefulShutdown = async (signal) => {
    console.log(`\n${signal} received. Closing MongoDB connection...`);
    await mongoose.connection.close();
    console.log('MongoDB connection closed.');
    process.exit(0);
  };

  process.on('SIGINT', () => gracefulShutdown('SIGINT'));
  process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
}

export default mongoose;
