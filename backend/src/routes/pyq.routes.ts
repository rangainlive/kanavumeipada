import type { FastifyInstance } from 'fastify';
import { Pool } from 'pg';
import { createPyqService } from '../services/pyq.service';

export async function pyqRoutes(fastify: FastifyInstance, pool: Pool) {
  const svc = createPyqService(pool);

  // List PYQ topics (with question counts) for a subject
  fastify.get('/api/subjects/:subjectId/pyq/topics', async (request: any, reply) => {
    try {
      const { subjectId } = request.params;
      const topics = await svc.getTopics(subjectId);
      return reply.code(200).send({ topics });
    } catch (error: any) {
      return reply.code(500).send({ error: 'Failed to fetch PYQ topics', message: error.message });
    }
  });

  // List PYQ questions for a subject, optionally filtered by topic
  fastify.get('/api/subjects/:subjectId/pyq/questions', async (request: any, reply) => {
    try {
      const { subjectId } = request.params;
      const topic = request.query.topic as string | undefined;
      const limit = Math.min(parseInt(request.query.limit || '50'), 100);
      const offset = Math.max(parseInt(request.query.offset || '0'), 0);

      const { questions, total } = await svc.getQuestions(subjectId, topic, limit, offset);
      return reply.code(200).send({ questions, total, limit, offset });
    } catch (error: any) {
      return reply.code(500).send({ error: 'Failed to fetch PYQ questions', message: error.message });
    }
  });

  // Get PYQ questions still missing a marked correct answer (admin review queue)
  fastify.get(
    '/api/subjects/:subjectId/pyq/unmarked',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { subjectId } = request.params;
        const limit = Math.min(parseInt(request.query.limit || '20'), 50);
        const questions = await svc.getUnmarkedQuestions(subjectId, limit);
        return reply.code(200).send({ questions, count: questions.length });
      } catch (error: any) {
        return reply.code(500).send({ error: 'Failed to fetch unmarked PYQ questions', message: error.message });
      }
    }
  );

  // Mark the correct option for a PYQ question
  fastify.post(
    '/api/pyq/questions/:questionId/mark-answer',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { questionId } = request.params;
        const { optionId } = request.body;
        if (!optionId) {
          return reply.code(400).send({ error: 'optionId is required' });
        }
        await svc.setCorrectOption(questionId, optionId);
        return reply.code(200).send({ message: 'Answer marked' });
      } catch (error: any) {
        return reply.code(400).send({ error: 'Failed to mark answer', message: error.message });
      }
    }
  );
}
