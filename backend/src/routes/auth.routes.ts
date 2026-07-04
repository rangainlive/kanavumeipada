import type { FastifyInstance } from 'fastify';
import { Pool } from 'pg';
import { jwtService } from '../services/jwt.service';
import { createUserService } from '../services/user.service';
import { createGoogleOAuthService } from '../services/google-oauth.service';
import { z } from 'zod';
import bcrypt from 'bcryptjs';

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  name: z.string().min(1).max(255),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

const profileUpdateSchema = z.object({
  name: z.string().min(1).max(255),
  email: z.string().email().optional(),
  examTarget: z.string().min(1),
  state: z.string().min(1),
  language: z.string().optional(),
});

const googleAuthSchema = z.object({
  token: z.string().min(1),
});

export async function authRoutes(fastify: FastifyInstance, pool: Pool) {
  const userService = createUserService(pool);
  const googleOAuthService = createGoogleOAuthService(pool);

  // Register
  fastify.post('/api/auth/register', async (request, reply) => {
    try {
      const { email, password, name } = registerSchema.parse(request.body);

      const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
      if (existing.rows.length > 0) {
        return reply.code(400).send({ error: 'Email already registered' });
      }

      const password_hash = await bcrypt.hash(password, 10);

      const result = await pool.query(
        `INSERT INTO users (email, password_hash, name, coins_balance, xp, is_active)
         VALUES ($1, $2, $3, 100, 0, true) RETURNING *`,
        [email, password_hash, name]
      );

      const user = result.rows[0];
      await userService.initializeStreak(user.id);

      const { token, expiresIn } = jwtService.generateToken(user.id, email);
      const refreshToken = jwtService.generateRefreshToken(user.id);

      return reply.code(201).send({
        token,
        refreshToken,
        expiresIn,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          coinsBalance: user.coins_balance,
          isProfileComplete: !!user.exam_target && !!user.state,
        },
      });
    } catch (error: any) {
      return reply.code(400).send({ error: error.message });
    }
  });

  // Login
  fastify.post('/api/auth/login', async (request, reply) => {
    try {
      const { email, password } = loginSchema.parse(request.body);

      const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
      if (result.rows.length === 0) {
        return reply.code(401).send({ error: 'Invalid email or password' });
      }

      const user = result.rows[0];
      const valid = await bcrypt.compare(password, user.password_hash);
      if (!valid) {
        return reply.code(401).send({ error: 'Invalid email or password' });
      }

      const { token, expiresIn } = jwtService.generateToken(user.id, email);
      const refreshToken = jwtService.generateRefreshToken(user.id);

      return reply.code(200).send({
        token,
        refreshToken,
        expiresIn,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          coinsBalance: user.coins_balance,
          examTarget: user.exam_target,
          state: user.state,
          isProfileComplete: !!user.exam_target && !!user.state,
        },
      });
    } catch (error: any) {
      return reply.code(400).send({ error: error.message });
    }
  });

  // Update profile
  fastify.post(
    '/api/auth/profile',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const data = profileUpdateSchema.parse(request.body);
        const userId = request.user.userId;
        const user = await userService.updateProfile(userId, data);
        return reply.code(200).send({ message: 'Profile updated successfully', user });
      } catch (error: any) {
        return reply.code(400).send({ error: error.message });
      }
    }
  );

  // Get current user
  fastify.get(
    '/api/auth/me',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const user = await userService.getUserById(request.user.userId);
        if (!user) return reply.code(404).send({ error: 'User not found' });
        return reply.code(200).send({ user });
      } catch (error: any) {
        return reply.code(500).send({ error: error.message });
      }
    }
  );

  // Refresh token
  fastify.post('/api/auth/refresh', async (request: any, reply) => {
    try {
      const { refreshToken } = request.body;
      if (!refreshToken) return reply.code(400).send({ error: 'Refresh token required' });

      const decoded = jwtService.verifyRefreshToken(refreshToken);
      const user = await userService.getUserById(decoded.userId);
      if (!user) return reply.code(401).send({ error: 'User not found' });

      const { token, expiresIn } = jwtService.generateToken(user.id, user.email || '');
      const newRefreshToken = jwtService.generateRefreshToken(user.id);

      return reply.code(200).send({ token, refreshToken: newRefreshToken, expiresIn });
    } catch (error: any) {
      return reply.code(401).send({ error: error.message });
    }
  });

  // Google OAuth
  fastify.post('/api/auth/google', async (request, reply) => {
    try {
      const { token } = googleAuthSchema.parse(request.body);
      const result = await googleOAuthService.handleGoogleAuth(token);
      return reply.code(200).send(result);
    } catch (error: any) {
      console.error('[Google Auth]', error.message);
      return reply.code(401).send({ error: error.message });
    }
  });

  // Google OAuth authorization URL (unused — web uses GIS renderButton directly)
  fastify.get('/api/auth/google/authorize', async (request, reply) => {
    return reply.code(200).send({ message: 'Use GIS button on client side' });
  });
}
