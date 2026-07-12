import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import dotenv from 'dotenv';
import { Pool } from 'pg';
import { readFileSync } from 'fs';
import { join } from 'path';
import { registerAuthMiddleware } from './middleware/auth.middleware';
import { authRoutes } from './routes/auth.routes';
import { feedRoutes } from './routes/feed.routes';
import { contentRoutes } from './routes/content.routes';
import { testRoutes } from './routes/test.routes';
import { walletRoutes } from './routes/wallet.routes';
import { challengeRoutes } from './routes/challenge.routes';
import { aiContentRoutes } from './routes/ai-content.routes';

dotenv.config();

const fastify = Fastify({
  logger: true,
});

// Initialize database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/kanavumeipada',
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

// Register plugins
fastify.register(helmet, {
  crossOriginResourcePolicy: false,
  crossOriginOpenerPolicy: false,   // required for Google Sign-In popup
  crossOriginEmbedderPolicy: false,
});

const corsOriginConfig = (requestOrigin: string | undefined, cb: (err: Error | null, allow: boolean) => void) => {
  if (!requestOrigin) return cb(null, true);

  // Always allow localhost and 127.0.0.1 for local development
  if (requestOrigin.startsWith('http://localhost') || requestOrigin.startsWith('http://127.0.0.1')) {
    return cb(null, true);
  }

  const allowedOrigins = (process.env.CORS_ORIGIN || '*').split(',').map(o => o.trim());

  if (allowedOrigins.includes('*')) return cb(null, true);

  for (const origin of allowedOrigins) {
    if (origin === requestOrigin) return cb(null, true);
    if (origin.endsWith(':*')) {
      if (requestOrigin.startsWith(origin.slice(0, -2))) return cb(null, true);
    }
  }

  cb(new Error(`Origin ${requestOrigin} not allowed`), false);
};

fastify.register(cors, {
  origin: corsOriginConfig,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  exposedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400,
});

// Register auth middleware
registerAuthMiddleware(fastify);

// Health check
fastify.get('/health', async (request, reply) => {
  try {
    await pool.query('SELECT NOW()');
    return {
      status: 'ok',
      database: 'connected',
      timestamp: new Date().toISOString(),
    };
  } catch (err) {
    const error = err as Error;
    console.error('DB Health check failed:', error.message);
    return reply.code(200).send({
      status: 'error',
      database: 'disconnected',
      error: error.message,
      hint: 'Check DATABASE_URL environment variable',
    });
  }
});

// API routes
fastify.get('/api', async (request, reply) => {
  return {
    message: 'KanavuMeipada API v1.0.0',
    endpoints: {
      auth: '/api/auth',
      subjects: '/api/subjects',
      chapters: '/api/chapters',
      tests: '/api/tests',
      challenges: '/api/challenges',
      feed: '/api/feed',
      wallet: '/api/wallet',
    },
  };
});

// Register all routes
fastify.register((fastify) => authRoutes(fastify, pool));
fastify.register((fastify) => feedRoutes(fastify, pool));
fastify.register((fastify) => contentRoutes(fastify, pool));
fastify.register((fastify) => testRoutes(fastify, pool));
fastify.register((fastify) => walletRoutes(fastify, pool));
fastify.register((fastify) => challengeRoutes(fastify, pool));
fastify.register((fastify) => aiContentRoutes(fastify, pool));

const runMigrations = async () => {
  try {
    const sql = readFileSync(join(__dirname, 'db', 'init.sql'), 'utf8');
    await pool.query(sql);
    console.log('✅ Database schema initialized');
  } catch (err) {
    console.error('❌ Migration failed:', (err as Error).message);
    throw err;
  }
};

const start = async () => {
  try {
    await runMigrations();

    const port = parseInt(process.env.PORT || '3000');
    const host = process.env.HOST || '0.0.0.0';

    await fastify.listen({ port, host });
    console.log(`🚀 Server running at http://${host}:${port}`);
    console.log(`📚 API Documentation: http://${host}:${port}/api`);
  } catch (err) {
    fastify.log.error(err);
    await pool.end();
    process.exit(1);
  }
};

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM signal received: closing HTTP server');
  await fastify.close();
  await pool.end();
  process.exit(0);
});

start();
