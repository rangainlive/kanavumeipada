import { Pool } from 'pg';

export interface Subject {
  id: string;
  name: string;
  icon?: string;
  examCategory?: string;
}

export interface Chapter {
  id: string;
  subjectId: string;
  title: string;
  orderIndex: number;
  contentText?: string;
  contentUrl?: string;
  isApproved: boolean;
  createdBy?: string;
  createdAt: Date;
}

export interface Question {
  id: string;
  chapterId: string;
  text: string;
  difficulty: number;
  aiGenerated: boolean;
  isApproved: boolean;
  helpfulCount: number;
  options: { id: string; text: string; isCorrect: boolean }[];
}

class ContentService {
  constructor(private pool: Pool) {}

  // Subjects
  async getSubjects(): Promise<Subject[]> {
    const result = await this.pool.query(
      `SELECT id, name, icon, exam_category as "examCategory"
       FROM subjects
       ORDER BY name ASC`
    );
    return result.rows;
  }

  async getSubjectById(id: string): Promise<Subject | null> {
    const result = await this.pool.query(
      `SELECT id, name, icon, exam_category as "examCategory"
       FROM subjects WHERE id = $1`,
      [id]
    );
    return result.rows[0] || null;
  }

  async createSubject(name: string, icon?: string, examCategory?: string): Promise<Subject> {
    const result = await this.pool.query(
      `INSERT INTO subjects (name, icon, exam_category)
       VALUES ($1, $2, $3)
       RETURNING id, name, icon, exam_category as "examCategory"`,
      [name, icon || null, examCategory || null]
    );
    return result.rows[0];
  }

  // Chapters
  async getChaptersBySubject(subjectId: string): Promise<Chapter[]> {
    const result = await this.pool.query(
      `SELECT id, subject_id as "subjectId", title, order_index as "orderIndex",
              content_text as "contentText", content_url as "contentUrl",
              is_approved as "isApproved", created_by as "createdBy", created_at as "createdAt"
       FROM chapters
       WHERE subject_id = $1 AND is_approved = true
       ORDER BY order_index ASC`,
      [subjectId]
    );
    return result.rows;
  }

  async getChapterById(id: string): Promise<Chapter | null> {
    const result = await this.pool.query(
      `SELECT id, subject_id as "subjectId", title, order_index as "orderIndex",
              content_text as "contentText", content_url as "contentUrl",
              is_approved as "isApproved", created_by as "createdBy", created_at as "createdAt"
       FROM chapters WHERE id = $1`,
      [id]
    );
    return result.rows[0] || null;
  }

  async createChapter(
    subjectId: string,
    title: string,
    contentText?: string,
    contentUrl?: string,
    createdBy?: string
  ): Promise<Chapter> {
    const result = await this.pool.query(
      `INSERT INTO chapters (subject_id, title, content_text, content_url, created_by, is_approved)
       VALUES ($1, $2, $3, $4, $5, false)
       RETURNING id, subject_id as "subjectId", title, order_index as "orderIndex",
         content_text as "contentText", content_url as "contentUrl",
         is_approved as "isApproved", created_by as "createdBy", created_at as "createdAt"`,
      [subjectId, title, contentText || null, contentUrl || null, createdBy || null]
    );
    return result.rows[0];
  }

  async approveChapter(id: string): Promise<void> {
    await this.pool.query(
      `UPDATE chapters SET is_approved = true WHERE id = $1`,
      [id]
    );
  }

  // Questions
  async getQuestionsByChapter(chapterId: string): Promise<Question[]> {
    const questionsResult = await this.pool.query(
      `SELECT id, chapter_id as "chapterId", text, difficulty,
              ai_generated as "aiGenerated", is_approved as "isApproved",
              helpful_count as "helpfulCount"
       FROM questions
       WHERE chapter_id = $1 AND is_approved = true
       ORDER BY RANDOM()`,
      [chapterId]
    );

    const questions: Question[] = [];

    for (const q of questionsResult.rows) {
      const optionsResult = await this.pool.query(
        `SELECT id, text, is_correct as "isCorrect"
         FROM question_options
         WHERE question_id = $1
         ORDER BY RANDOM()`,
        [q.id]
      );

      questions.push({
        ...q,
        options: optionsResult.rows,
      });
    }

    return questions;
  }

  async getQuestionById(id: string): Promise<Question | null> {
    const result = await this.pool.query(
      `SELECT id, chapter_id as "chapterId", text, difficulty,
              ai_generated as "aiGenerated", is_approved as "isApproved",
              helpful_count as "helpfulCount"
       FROM questions WHERE id = $1`,
      [id]
    );

    if (!result.rows[0]) return null;

    const question = result.rows[0];

    const optionsResult = await this.pool.query(
      `SELECT id, text, is_correct as "isCorrect"
       FROM question_options
       WHERE question_id = $1`,
      [id]
    );

    return {
      ...question,
      options: optionsResult.rows,
    };
  }

  async createQuestion(
    chapterId: string,
    text: string,
    options: { text: string; isCorrect: boolean }[],
    difficulty: number = 2,
    aiGenerated: boolean = false
  ): Promise<Question> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const qResult = await client.query(
        `INSERT INTO questions (chapter_id, text, difficulty, ai_generated, is_approved)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING id, chapter_id as "chapterId", text, difficulty,
           ai_generated as "aiGenerated", is_approved as "isApproved",
           helpful_count as "helpfulCount"`,
        [chapterId, text, difficulty, aiGenerated, !aiGenerated]
      );

      const questionId = qResult.rows[0].id;

      const optionsResult = await client.query(
        `INSERT INTO question_options (question_id, text, is_correct)
         VALUES ${options.map((_, i) => `($1, $${i + 2}, $${i + 2 + options.length})`).join(',')}
         RETURNING id, text, is_correct as "isCorrect"`,
        [questionId, ...options.map(o => o.text), ...options.map(o => o.isCorrect)]
      );

      await client.query('COMMIT');

      return {
        ...qResult.rows[0],
        options: optionsResult.rows,
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async approveQuestion(id: string): Promise<void> {
    await this.pool.query(
      `UPDATE questions SET is_approved = true WHERE id = $1`,
      [id]
    );
  }

  async rateQuestion(questionId: string, userId: string, isHelpful: boolean): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      await client.query(
        `INSERT INTO question_ratings (question_id, user_id, is_helpful)
         VALUES ($1, $2, $3)
         ON CONFLICT (question_id, user_id) DO UPDATE SET is_helpful = $3`,
        [questionId, userId, isHelpful]
      );

      const helpfulCount = await client.query(
        `SELECT COUNT(*) as count FROM question_ratings WHERE question_id = $1 AND is_helpful = true`,
        [questionId]
      );

      await client.query(
        `UPDATE questions SET helpful_count = $1 WHERE id = $2`,
        [helpfulCount.rows[0].count, questionId]
      );

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async searchChapters(query: string, limit: number = 20): Promise<Chapter[]> {
    const result = await this.pool.query(
      `SELECT id, subject_id as "subjectId", title, order_index as "orderIndex",
              content_text as "contentText", content_url as "contentUrl",
              is_approved as "isApproved", created_by as "createdBy", created_at as "createdAt"
       FROM chapters
       WHERE is_approved = true AND (title ILIKE $1 OR content_text ILIKE $1)
       LIMIT $2`,
      [`%${query}%`, limit]
    );
    return result.rows;
  }
}

export const createContentService = (pool: Pool) => new ContentService(pool);
