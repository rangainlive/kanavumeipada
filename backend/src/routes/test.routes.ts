import type { FastifyInstance } from 'fastify';
import { Pool } from 'pg';
import { createTestService } from '../services/test.service';
import { z } from 'zod';

const createTestSchema = z.object({
  chapterId: z.string().uuid(),
  questionIds: z.array(z.string().uuid()).min(1),
  type: z.enum(['practice', 'challenge', 'daily', 'official']),
  title: z.string().optional(),
  timeLimitSec: z.number().optional(),
});

const submitAnswerSchema = z.object({
  questionId: z.string().uuid(),
  selectedOptionId: z.string().uuid().nullable(),
  timeTakenMs: z.number(),
});

export async function testRoutes(fastify: FastifyInstance, pool: Pool) {
  const testService = createTestService(pool);

  // Create test
  fastify.post(
    '/api/tests',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const data = createTestSchema.parse(request.body);
        const creatorId = request.user.userId;

        const test = await testService.createTest(
          data.chapterId,
          creatorId,
          data.type,
          data.questionIds,
          data.title,
          data.timeLimitSec
        );

        return reply.code(201).send({ test });
      } catch (error: any) {
        return reply.code(400).send({ error: 'Failed to create test', message: error.message });
      }
    }
  );

  // Get test
  fastify.get('/api/tests/:testId', async (request: any, reply) => {
    try {
      const { testId } = request.params;
      const test = await testService.getTestById(testId);

      if (!test) {
        return reply.code(404).send({ error: 'Test not found' });
      }

      const questions = await testService.getTestQuestions(testId);

      return reply.code(200).send({ test, questions });
    } catch (error: any) {
      return reply.code(500).send({ error: 'Failed to fetch test', message: error.message });
    }
  });

  // Start attempt
  fastify.post(
    '/api/tests/:testId/attempts',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { testId } = request.params;
        const userId = request.user.userId;

        const attempt = await testService.startAttempt(testId, userId);

        return reply.code(201).send({ attempt });
      } catch (error: any) {
        return reply.code(400).send({ error: 'Failed to start attempt', message: error.message });
      }
    }
  );

  // Submit answer
  fastify.post(
    '/api/tests/attempts/:attemptId/answers',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { attemptId } = request.params;
        const data = submitAnswerSchema.parse(request.body);

        const isCorrect = await testService.submitAnswer(
          attemptId,
          data.questionId,
          data.selectedOptionId,
          data.timeTakenMs
        );

        return reply.code(200).send({ isCorrect });
      } catch (error: any) {
        return reply.code(400).send({ error: 'Failed to submit answer', message: error.message });
      }
    }
  );

  // Complete attempt
  fastify.post(
    '/api/tests/attempts/:attemptId/complete',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { attemptId } = request.params;

        const result = await testService.completeAttempt(attemptId);

        return reply.code(200).send(result);
      } catch (error: any) {
        return reply.code(400).send({ error: 'Failed to complete attempt', message: error.message });
      }
    }
  );

  // Get user attempts
  fastify.get(
    '/api/tests/attempts',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const userId = request.user.userId;
        const testId = request.query.testId;

        const attempts = await testService.getUserAttempts(userId, testId);

        return reply.code(200).send({ attempts, count: attempts.length });
      } catch (error: any) {
        return reply.code(500).send({ error: 'Failed to fetch attempts', message: error.message });
      }
    }
  );

  // Get leaderboard
  fastify.get('/api/tests/:testId/leaderboard', async (request: any, reply) => {
    try {
      const { testId } = request.params;
      const limit = Math.min(parseInt(request.query.limit || '100'), 1000);

      const leaderboard = await testService.getLeaderboard(testId, limit);

      return reply.code(200).send({ leaderboard, count: leaderboard.length });
    } catch (error: any) {
      return reply.code(500).send({ error: 'Failed to fetch leaderboard', message: error.message });
    }
  });

  // Publish test
  fastify.post(
    '/api/tests/:testId/publish',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { testId } = request.params;
        const userId = request.user.userId;

        const test = await testService.getTestById(testId);

        if (!test) {
          return reply.code(404).send({ error: 'Test not found' });
        }

        if (test.creatorId !== userId) {
          return reply.code(403).send({ error: 'You can only publish your own tests' });
        }

        await testService.publishTest(testId);

        return reply.code(200).send({ message: 'Test published' });
      } catch (error: any) {
        return reply.code(400).send({ error: 'Failed to publish test', message: error.message });
      }
    }
  );
}
