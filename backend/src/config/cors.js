/**
 * CORS Configuration
 * Allows Flutter App (any origin in dev) + Admin panel
 */
import cors from 'cors';
import env from './env.js';

const allowedOrigins = [
  env.APP_URL,
  env.ADMIN_URL,
  'http://localhost:3000',
  'http://localhost:5173',
  'http://localhost:5000',
].filter(Boolean);

const corsOptions = {
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, curl, Postman)
    if (!origin) return callback(null, true);
    
    if (env.isDev) {
      // In development, allow all origins
      return callback(null, true);
    }

    // In production, allow all origins for mobile app (no browser CORS needed)
    // Mobile apps don't send Origin header, so this mainly affects admin web
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }

    // Allow any https origin in production (mobile apps + admin)
    if (origin && origin.startsWith('https://')) {
      return callback(null, true);
    }
    
    callback(new Error(`CORS not allowed for origin: ${origin}`));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  exposedHeaders: ['X-Total-Count', 'X-Page', 'X-Limit'],
  maxAge: 86400, // 24 hours
};

export function setupCors(app) {
  app.use(cors(corsOptions));
}

export default corsOptions;
