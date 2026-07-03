import type { FastifyInstance } from 'fastify';
import { Pool } from 'pg';
import { createChallengeService } from '../services/challenge.service';
import { z } from 'zod';

const createChallengeSchema = z.object({
  testId: z.string().uuid(),
  entryFeeCoins: z.number().min(10).max(10000),
  durationMinutes: z.number().min(60).max(10080).optional(),
  maxParticipants: z.number().optional(),
});

export async function challengeRoutes(fastify: FastifyInstance, pool: Pool) {
  const challengeService = createChallengeService(pool);

  // Create challenge
  fastify.post(
    '/api/challenges',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const data = createChallengeSchema.parse(request.body);
        const creatorId = request.user.userId;

        const challenge = await challengeService.createChallenge(
          data.testId,
          creatorId,
          data.entryFeeCoins,
          data.durationMinutes || 1440,
          data.maxParticipants
        );

        return reply.code(201).send({ challenge });
      } catch (error: any) {
        return reply.code(400).send({
          error: 'Failed to create challenge',
          message: error.message,
        });
      }
    }
  );

  // Get challenge
  fastify.get('/api/challenges/:challengeId', async (request: any, reply) => {
    try {
      const { challengeId } = request.params;

      const challenge = await challengeService.getChallengeById(challengeId);

      if (!challenge) {
        return reply.code(404).send({ error: 'Challenge not found' });
      }

      const participants = await challengeService.getParticipants(challengeId);

      return reply.code(200).send({ challenge, participants });
    } catch (error: any) {
      return reply.code(500).send({
        error: 'Failed to fetch challenge',
        message: error.message,
      });
    }
  });

  // Join challenge
  fastify.post(
    '/api/challenges/:challengeId/join',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { challengeId } = request.params;
        const userId = request.user.userId;

        await challengeService.joinChallenge(challengeId, userId);

        return reply.code(200).send({ message: 'Joined challenge' });
      } catch (error: any) {
        return reply.code(400).send({
          error: 'Failed to join challenge',
          message: error.message,
        });
      }
    }
  );

  // Submit attempt to challenge
  fastify.post(
    '/api/challenges/:challengeId/submit-attempt',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { challengeId } = request.params;
        const { attemptId, score } = request.body;
        const userId = request.user.userId;

        await challengeService.submitAttemptToChallenge(challengeId, userId, attemptId, score);

        return reply.code(200).send({ message: 'Attempt submitted' });
      } catch (error: any) {
        return reply.code(400).send({
          error: 'Failed to submit attempt',
          message: error.message,
        });
      }
    }
  );

  // Get active challenges
  fastify.get('/api/challenges', async (request, reply) => {
    try {
      const limit = Math.min(parseInt(request.query.limit || '20'), 100);
      const offset = parseInt(request.query.offset || '0');

      const challenges = await challengeService.getActiveChallenges(limit, offset);

      return reply.code(200).send({
        challenges,
        count: challenges.length,
      });
    } catch (error: any) {
      return reply.code(500).send({
        error: 'Failed to fetch challenges',
        message: error.message,
      });
    }
  });

  // Get user's challenges
  fastify.get(
    '/api/challenges/user/my',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const userId = request.user.userId;

        const challenges = await challengeService.getUserChallenges(userId);

        return reply.code(200).send({
          challenges,
          count: challenges.length,
        });
      } catch (error: any) {
        return reply.code(500).send({
          error: 'Failed to fetch challenges',
          message: error.message,
        });
      }
    }
  );

  // Distribute prizes (admin or scheduled job)
  fastify.post(
    '/api/challenges/:challengeId/distribute-prizes',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { challengeId } = request.params;
        const userId = request.user.userId;

        const challenge = await challengeService.getChallengeById(challengeId);

        if (!challenge) {
          return reply.code(404).send({ error: 'Challenge not found' });
        }

        if (challenge.creatorId !== userId && process.env.NODE_ENV !== 'development') {
          return reply.code(403).send({ error: 'Only creator can distribute prizes' });
        }

        await challengeService.distributePrizes(challengeId);

        return reply.code(200).send({ message: 'Prizes distributed' });
      } catch (error: any) {
        return reply.code(400).send({
          error: 'Failed to distribute prizes',
          message: error.message,
        });
      }
    }
  );
}
