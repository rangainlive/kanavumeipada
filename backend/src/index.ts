import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import dotenv from 'dotenv';
import { Pool } from 'pg';
import { registerAuthMiddleware } from './middleware/auth.middleware';
import { authRoutes } from './routes/auth.routes';
import { feedRoutes } from './routes/feed.routes';
import { contentRoutes } from './routes/content.routes';
import { testRoutes } from './routes/test.routes';
import { walletRoutes } from './routes/wallet.routes';
import { challengeRoutes } from './routes/challenge.routes';

dotenv.config();

const fastify = Fastify({
  logger: true,
});

// Initialize database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/kanavumeipada',
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

// Register plugins
fastify.register(helmet);
fastify.register(cors, {
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true,
});

// Register auth middleware
registerAuthMiddleware(fastify);

// Health check
fastify.get('/health', async (request, reply) => {
  try {
    const result = await pool.query('SELECT NOW()');
    return {
      status: 'ok',
      database: 'connected',
      timestamp: new Date().toISOString(),
    };
  } catch (err) {
    return reply.code(503).send({
      status: 'error',
      database: 'disconnected',
      error: (err as Error).message,
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

const start = async () => {
  try {
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
