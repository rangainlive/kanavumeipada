import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { Pool } from 'pg';
import { jwtService } from '../services/jwt.service';
import { createUserService } from '../services/user.service';
import type { PhoneOTPRequest, VerifyOTPRequest, ProfileUpdateRequest } from '../types/auth';
import { z } from 'zod';

const phoneOTPSchema = z.object({
  phone: z.string().min(10).max(20),
});

const verifyOTPSchema = z.object({
  phone: z.string().min(10).max(20),
  otp: z.string().length(6),
});

const profileUpdateSchema = z.object({
  name: z.string().min(1).max(255),
  email: z.string().email().optional(),
  examTarget: z.string().min(1),
  state: z.string().min(1),
  language: z.string().optional(),
});

export async function authRoutes(fastify: FastifyInstance, pool: Pool) {
  const userService = createUserService(pool);

  // Request phone OTP
  fastify.post<{ Body: PhoneOTPRequest }>('/api/auth/request-otp', async (request, reply) => {
    try {
      const { phone } = phoneOTPSchema.parse(request.body);

      // In production, integrate with Firebase to send OTP
      // For now, we'll simulate it
      const otp = '123456'; // Simulate OTP for development

      // Store OTP in Redis (cache) with expiry of 10 minutes
      // This would be: await redis.setex(`otp:${phone}`, 600, otp);

      return reply.code(200).send({
        message: 'OTP sent successfully',
        requestId: `req_${Date.now()}`,
        // In development only, return OTP:
        ...(process.env.NODE_ENV === 'development' && { otp }),
      });
    } catch (error: any) {
      return reply.code(400).send({
        error: 'Invalid phone number',
        message: error.message,
      });
    }
  });

  // Verify OTP and create/login user
  fastify.post<{ Body: VerifyOTPRequest }>('/api/auth/verify-otp', async (request, reply) => {
    try {
      const { phone, otp } = verifyOTPSchema.parse(request.body);

      // In production, verify OTP from Redis
      // For development, accept any 6-digit code
      if (otp.length !== 6) {
        return reply.code(400).send({ error: 'Invalid OTP' });
      }

      // Get or create user
      let user = await userService.getUserByPhone(phone);

      if (!user) {
        user = await userService.createUser(phone);
        await userService.initializeStreak(user.id);
      }

      // Generate JWT tokens
      const { token, expiresIn } = jwtService.generateToken(user.id, phone);
      const refreshToken = jwtService.generateRefreshToken(user.id);

      return reply.code(200).send({
        token,
        refreshToken,
        expiresIn,
        user: {
          id: user.id,
          phone: user.phone,
          name: user.name,
          isProfileComplete:
            !!user.name && !!user.examTarget && !!user.state && user.coinsBalance >= 0,
        },
      });
    } catch (error: any) {
      return reply.code(400).send({
        error: 'Authentication failed',
        message: error.message,
      });
    }
  });

  // Update profile
  fastify.post<{ Body: ProfileUpdateRequest }>(
    '/api/auth/profile',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const data = profileUpdateSchema.parse(request.body);
        const userId = request.user.userId;

        const user = await userService.updateProfile(userId, data);

        return reply.code(200).send({
          message: 'Profile updated successfully',
          user,
        });
      } catch (error: any) {
        return reply.code(400).send({
          error: 'Profile update failed',
          message: error.message,
        });
      }
    }
  );

  // Get current user
  fastify.get(
    '/api/auth/me',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const userId = request.user.userId;
        const user = await userService.getUserById(userId);

        if (!user) {
          return reply.code(404).send({ error: 'User not found' });
        }

        return reply.code(200).send({ user });
      } catch (error: any) {
        return reply.code(500).send({
          error: 'Failed to fetch user',
          message: error.message,
        });
      }
    }
  );

  // Refresh token
  fastify.post<{ Body: { refreshToken: string } }>(
    '/api/auth/refresh',
    async (request, reply) => {
      try {
        const { refreshToken } = request.body as { refreshToken: string };

        if (!refreshToken) {
          return reply.code(400).send({ error: 'Refresh token required' });
        }

        const decoded = jwtService.verifyRefreshToken(refreshToken);
        const user = await userService.getUserById(decoded.userId);

        if (!user) {
          return reply.code(401).send({ error: 'User not found' });
        }

        const { token, expiresIn } = jwtService.generateToken(user.id, user.phone);
        const newRefreshToken = jwtService.generateRefreshToken(user.id);

        return reply.code(200).send({
          token,
          refreshToken: newRefreshToken,
          expiresIn,
        });
      } catch (error: any) {
        return reply.code(401).send({
          error: 'Token refresh failed',
          message: error.message,
        });
      }
    }
  );
}
