import type { FastifyInstance } from 'fastify';
import { Pool } from 'pg';
import { z } from 'zod';
import { createAiQuestionService } from '../services/ai-question.service';

const generateSchema = z.object({
  count: z.number().int().min(3).max(20).default(10),
  difficulty: z.number().int().min(1).max(3).default(2),
  bloomLevel: z.enum(['remember', 'understand', 'apply', 'analyze']).default('understand'),
  language: z.enum(['tamil', 'english']).default('english'),
});

const uploadContentSchema = z.object({
  contentText: z.string().min(100).max(50000),
});

export async function aiContentRoutes(fastify: FastifyInstance, pool: Pool) {
  const svc = createAiQuestionService(pool);

  // Generate MCQs from a chapter's content_text
  fastify.post(
    '/api/chapters/:chapterId/generate-questions',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      if (!svc.isEnabled) {
        return reply.status(503).send({ error: 'AI generation is not configured. Add GEMINI_API_KEY to Railway environment variables.' });
      }
      try {
        const { chapterId } = request.params;
        const body = generateSchema.parse(request.body);

        const questions = await svc.generateFromChapter(chapterId, {
          count: body.count,
          difficulty: body.difficulty,
          bloomLevel: body.bloomLevel,
          language: body.language,
        });

        return reply.code(200).send({
          message: `Generated ${questions.length} questions`,
          count: questions.length,
          questions,
        });
      } catch (err: any) {
        const status = err.message?.includes('not found') ? 404
          : err.message?.includes('content text') ? 422
          : err.message?.includes('GEMINI_API_KEY') ? 503
          : 500;
        return reply.code(status).send({ error: err.message });
      }
    }
  );

  // Get pending (unapproved AI) questions for a chapter
  fastify.get(
    '/api/chapters/:chapterId/pending-questions',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { chapterId } = request.params;
        const questions = await svc.getPendingQuestions(chapterId);
        return reply.code(200).send({ questions, count: questions.length });
      } catch (err: any) {
        return reply.code(500).send({ error: err.message });
      }
    }
  );

  // Upload / update a chapter's content text
  fastify.post(
    '/api/chapters/:chapterId/content',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { chapterId } = request.params;
        const { contentText } = uploadContentSchema.parse(request.body);
        await svc.updateChapterContent(chapterId, contentText);
        return reply.code(200).send({ message: 'Chapter content updated' });
      } catch (err: any) {
        return reply.code(400).send({ error: err.message });
      }
    }
  );

  // Approve a single AI-generated question
  fastify.post(
    '/api/questions/:questionId/approve',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { questionId } = request.params;
        await svc.approveQuestion(questionId);
        return reply.code(200).send({ message: 'Question approved' });
      } catch (err: any) {
        return reply.code(500).send({ error: err.message });
      }
    }
  );

  // Delete / reject a question
  fastify.delete(
    '/api/questions/:questionId',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { questionId } = request.params;
        await svc.deleteQuestion(questionId);
        return reply.code(200).send({ message: 'Question deleted' });
      } catch (err: any) {
        return reply.code(500).send({ error: err.message });
      }
    }
  );
}
