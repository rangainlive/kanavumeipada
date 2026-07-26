import type { FastifyInstance } from 'fastify';
import { Pool } from 'pg';
import { createChallengeService } from '../services/challenge.service';
import { z } from 'zod';

// Keys for the Battle tab's arcade mini-games — must match the Flutter
// registry in app/lib/features/challenge/minigames/minigame_registry.dart.
export const MINIGAME_KEYS = [
  'bang_bang_2',
  'mosquito',
  'counting_stars',
  'puzzle_good',
  'autobahn',
  'apple_shootout',
  'frog_leap',
  'knife_throw',
  'road_safety_dodge',
  'deal_or_no_deal',
  'cave_puzzle',
] as const;

const createChallengeSchema = z
  .object({
    gameType: z.enum(['test', 'minigame']).default('test'),
    testId: z.string().uuid().optional(),
    minigameKey: z.enum(MINIGAME_KEYS).optional(),
    entryFeeCoins: z.number().min(10).max(10000),
    durationMinutes: z.number().min(60).max(10080).optional(),
    minParticipants: z.number().min(2).max(1000).optional(),
    maxParticipants: z.number().min(2).max(1000).optional(),
    isPublic: z.boolean().optional(),
    gameConfig: z.record(z.any()).optional(),
  })
  .refine((d) => (d.gameType === 'test' ? !!d.testId : !!d.minigameKey), {
    message: 'testId is required for test challenges, minigameKey is required for minigame challenges',
  })
  .refine((d) => !(d.minParticipants && d.maxParticipants) || d.minParticipants <= d.maxParticipants, {
    message: 'minParticipants must be less than or equal to maxParticipants',
  });

const joinByCodeSchema = z.object({
  joinCode: z.string().min(4).max(8),
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

        const challenge = await challengeService.createChallenge({
          gameType: data.gameType,
          testId: data.testId,
          minigameKey: data.minigameKey,
          creatorId,
          entryFeeCoins: data.entryFeeCoins,
          durationMinutes: data.durationMinutes || 1440,
          minParticipants: data.minParticipants,
          maxParticipants: data.maxParticipants,
          isPublic: data.isPublic,
          gameConfig: data.gameConfig,
        });

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

  // Join a private challenge via its share code
  fastify.post(
    '/api/challenges/join-by-code',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { joinCode } = joinByCodeSchema.parse(request.body);
        const userId = request.user.userId;

        const challenge = await challengeService.joinChallengeByCode(joinCode, userId);

        return reply.code(200).send({ message: 'Joined challenge', challenge });
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

  // Submit a mini-game score to a challenge
  fastify.post(
    '/api/challenges/:challengeId/submit-minigame-score',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { challengeId } = request.params;
        const { score, timeTakenMs } = request.body;
        const userId = request.user.userId;

        await challengeService.submitMinigameScore(challengeId, userId, score, timeTakenMs);

        return reply.code(200).send({ message: 'Score submitted' });
      } catch (error: any) {
        return reply.code(409).send({
          error: 'Failed to submit score',
          message: error.message,
        });
      }
    }
  );

  // Get active challenges
  fastify.get('/api/challenges', async (request, reply) => {
    try {
      const query = request.query as any;
      const limit = Math.min(parseInt(query.limit || '20'), 100);
      const offset = parseInt(query.offset || '0');

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
