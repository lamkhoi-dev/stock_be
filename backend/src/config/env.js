/**
 * Environment Configuration
 * Centralized env variable access with defaults and validation
 */
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load .env from backend root
dotenv.config({ path: resolve(__dirname, '../../.env') });

const env = {
  // Server
  PORT: parseInt(process.env.PORT, 10) || 5000,
  NODE_ENV: process.env.NODE_ENV || 'development',
  isDev: (process.env.NODE_ENV || 'development') === 'development',
  isProd: process.env.NODE_ENV === 'production',

  // MongoDB
  MONGODB_URI: process.env.MONGODB_URI || 'mongodb://localhost:27017/krx_stock',

  // JWT
  JWT_SECRET: process.env.JWT_SECRET || 'default_jwt_secret_change_me',
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || 'default_refresh_secret_change_me',
  JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '15m',
  JWT_REFRESH_EXPIRES_IN: process.env.JWT_REFRESH_EXPIRES_IN || '7d',

  // KIS Open API (PRIMARY)
  KIS_APP_KEY: process.env.KIS_APP_KEY || '',
  KIS_APP_SECRET: process.env.KIS_APP_SECRET || '',
  KIS_BASE_URL: process.env.KIS_BASE_URL || 'https://openapi.koreainvestment.com:9443',

  // AI Services
  GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
  GROQ_API_KEY: process.env.GROQ_API_KEY || '',

  // Email (SMTP)
  SMTP_HOST: process.env.SMTP_HOST || 'smtp.gmail.com',
  SMTP_PORT: parseInt(process.env.SMTP_PORT, 10) || 587,
  SMTP_USER: process.env.SMTP_USER || '',
  SMTP_PASS: process.env.SMTP_PASS || '',

  // Google OAuth
  GOOGLE_CLIENT_ID: process.env.GOOGLE_CLIENT_ID || '',
  GOOGLE_CLIENT_SECRET: process.env.GOOGLE_CLIENT_SECRET || '',

  // CORS
  APP_URL: process.env.APP_URL || 'http://localhost:3000',
  ADMIN_URL: process.env.ADMIN_URL || 'http://localhost:5173',
};

/**
 * Validate required environment variables
 * Logs warnings (not throws) in dev mode
 */
export function validateEnv() {
  const required = ['MONGODB_URI', 'JWT_SECRET', 'KIS_APP_KEY', 'KIS_APP_SECRET'];
  const missing = required.filter(key => !env[key] || env[key].includes('change_me') || env[key].includes('default_'));
  
  if (missing.length > 0) {
    const msg = `Missing or default environment variables: ${missing.join(', ')}`;
    if (env.isProd) {
      throw new Error(msg);
    } else {
      console.warn(`⚠️  ${msg}`);
    }
  }
}

export default env;
