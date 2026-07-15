import { Pool } from 'pg';

export interface PyqOption {
  id: string;
  text: string;
  textTamil: string | null;
  isCorrect: boolean;
}

export interface PyqQuestion {
  id: string;
  chapterId: string;
  topic: string | null;
  text: string;
  textTamil: string | null;
  examName: string | null;
  examYear: number | null;
  answerMarked: boolean;
  options: PyqOption[];
}

class PyqService {
  constructor(private pool: Pool) {}

  async getTopics(subjectId: string): Promise<{ topic: string; count: number }[]> {
    const result = await this.pool.query(
      `SELECT q.topic, COUNT(*)::int as count
       FROM questions q
       JOIN chapters c ON c.id = q.chapter_id
       WHERE c.subject_id = $1 AND q.is_pyq = true AND q.is_approved = true
       GROUP BY q.topic
       ORDER BY q.topic ASC`,
      [subjectId]
    );
    return result.rows;
  }

  async getQuestions(subjectId: string, topic?: string, limit = 50, offset = 0): Promise<{ questions: PyqQuestion[]; total: number }> {
    const params: any[] = [subjectId];
    let topicFilter = '';
    if (topic) {
      params.push(topic);
      topicFilter = `AND q.topic = $${params.length}`;
    }

    const countResult = await this.pool.query(
      `SELECT COUNT(*)::int as total
       FROM questions q
       JOIN chapters c ON c.id = q.chapter_id
       WHERE c.subject_id = $1 AND q.is_pyq = true AND q.is_approved = true ${topicFilter}`,
      params
    );

    params.push(limit, offset);
    const questionsResult = await this.pool.query(
      `SELECT q.id, q.chapter_id as "chapterId", q.topic, q.text, q.text_tamil as "textTamil",
              q.exam_name as "examName", q.exam_year as "examYear", q.answer_marked as "answerMarked"
       FROM questions q
       JOIN chapters c ON c.id = q.chapter_id
       WHERE c.subject_id = $1 AND q.is_pyq = true AND q.is_approved = true ${topicFilter}
       ORDER BY q.topic ASC, q.created_at ASC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    const questions: PyqQuestion[] = [];
    for (const q of questionsResult.rows) {
      const optionsResult = await this.pool.query(
        `SELECT id, text, text_tamil as "textTamil", is_correct as "isCorrect"
         FROM question_options
         WHERE question_id = $1
         ORDER BY text ASC`,
        [q.id]
      );
      questions.push({ ...q, options: optionsResult.rows });
    }

    return { questions, total: countResult.rows[0].total };
  }

  async getUnmarkedQuestions(subjectId: string, limit = 20): Promise<PyqQuestion[]> {
    const result = await this.pool.query(
      `SELECT q.id, q.chapter_id as "chapterId", q.topic, q.text, q.text_tamil as "textTamil",
              q.exam_name as "examName", q.exam_year as "examYear", q.answer_marked as "answerMarked"
       FROM questions q
       JOIN chapters c ON c.id = q.chapter_id
       WHERE c.subject_id = $1 AND q.is_pyq = true AND q.answer_marked = false
       ORDER BY q.topic ASC, q.created_at ASC
       LIMIT $2`,
      [subjectId, limit]
    );

    const questions: PyqQuestion[] = [];
    for (const q of result.rows) {
      const optionsResult = await this.pool.query(
        `SELECT id, text, text_tamil as "textTamil", is_correct as "isCorrect"
         FROM question_options
         WHERE question_id = $1
         ORDER BY text ASC`,
        [q.id]
      );
      questions.push({ ...q, options: optionsResult.rows });
    }
    return questions;
  }

  async setCorrectOption(questionId: string, optionId: string): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      const owner = await client.query(
        `SELECT question_id FROM question_options WHERE id = $1`,
        [optionId]
      );
      if (owner.rows.length === 0 || owner.rows[0].question_id !== questionId) {
        throw new Error('Option does not belong to question');
      }
      await client.query(
        `UPDATE question_options SET is_correct = (id = $1) WHERE question_id = $2`,
        [optionId, questionId]
      );
      await client.query(
        `UPDATE questions SET answer_marked = true, updated_at = NOW() WHERE id = $1`,
        [questionId]
      );
      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }
}

export const createPyqService = (pool: Pool) => new PyqService(pool);
