import type { FastifyInstance } from 'fastify';
import { Pool } from 'pg';
import { createContentService } from '../services/content.service';

export async function contentRoutes(fastify: FastifyInstance, pool: Pool) {
  const contentService = createContentService(pool);

  // Get all subjects
  fastify.get('/api/subjects', async (request, reply) => {
    try {
      const subjects = await contentService.getSubjects();
      return reply.code(200).send({ subjects });
    } catch (error: any) {
      return reply.code(500).send({ error: 'Failed to fetch subjects', message: error.message });
    }
  });

  // Get chapters by subject
  fastify.get('/api/subjects/:subjectId/chapters', async (request: any, reply) => {
    try {
      const { subjectId } = request.params;
      const chapters = await contentService.getChaptersBySubject(subjectId);
      return reply.code(200).send({ chapters });
    } catch (error: any) {
      return reply.code(500).send({ error: 'Failed to fetch chapters', message: error.message });
    }
  });

  // Get chapter details
  fastify.get('/api/chapters/:chapterId', async (request: any, reply) => {
    try {
      const { chapterId } = request.params;
      const chapter = await contentService.getChapterById(chapterId);

      if (!chapter) {
        return reply.code(404).send({ error: 'Chapter not found' });
      }

      return reply.code(200).send({ chapter });
    } catch (error: any) {
      return reply.code(500).send({ error: 'Failed to fetch chapter', message: error.message });
    }
  });

  // Get questions for chapter
  fastify.get('/api/chapters/:chapterId/questions', async (request: any, reply) => {
    try {
      const { chapterId } = request.params;
      const limit = Math.min(parseInt(request.query.limit || '50'), 50);

      const questions = await contentService.getQuestionsByChapter(chapterId);

      return reply.code(200).send({
        questions: questions.slice(0, limit),
        count: questions.length,
      });
    } catch (error: any) {
      return reply.code(500).send({ error: 'Failed to fetch questions', message: error.message });
    }
  });

  // Rate question
  fastify.post(
    '/api/questions/:questionId/rate',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { questionId } = request.params;
        const { isHelpful } = request.body;
        const userId = request.user.userId;

        await contentService.rateQuestion(questionId, userId, isHelpful);

        return reply.code(200).send({ message: 'Rating submitted' });
      } catch (error: any) {
        return reply.code(400).send({ error: 'Failed to submit rating', message: error.message });
      }
    }
  );

  // Search chapters
  fastify.get('/api/chapters/search', async (request: any, reply) => {
    try {
      const query = request.query.q;

      if (!query || query.length < 2) {
        return reply.code(400).send({ error: 'Query must be at least 2 characters' });
      }

      const chapters = await contentService.searchChapters(query);

      return reply.code(200).send({ chapters, count: chapters.length });
    } catch (error: any) {
      return reply.code(500).send({ error: 'Search failed', message: error.message });
    }
  });
}
