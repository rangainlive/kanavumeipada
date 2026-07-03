import { Pool } from 'pg';

export interface Test {
  id: string;
  chapterId: string;
  creatorId: string;
  type: 'practice' | 'challenge' | 'daily' | 'official';
  title?: string;
  description?: string;
  timeLimitSec?: number;
  questionCount: number;
  isPublished: boolean;
  publishedAt?: Date;
  targetExam?: string;
  targetState?: string;
  createdAt: Date;
}

export interface TestAttempt {
  id: string;
  testId: string;
  userId: string;
  startedAt: Date;
  completedAt?: Date;
  score?: number;
  totalQuestions: number;
  timeTakenSec?: number;
}

export interface TestResult {
  attempt: TestAttempt;
  correct: number;
  incorrect: number;
  accuracy: number;
  answers: { questionId: string; isCorrect: boolean; timeTakenMs: number }[];
}

class TestService {
  constructor(private pool: Pool) {}

  async createTest(
    chapterId: string,
    creatorId: string,
    type: 'practice' | 'challenge' | 'daily' | 'official',
    questionIds: string[],
    title?: string,
    timeLimitSec?: number
  ): Promise<Test> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const testResult = await client.query(
        `INSERT INTO tests (chapter_id, creator_id, type, title, time_limit_sec,
                          question_count, is_published)
         VALUES ($1, $2, $3, $4, $5, $6, false)
         RETURNING id, chapter_id as "chapterId", creator_id as "creatorId", type,
           title, time_limit_sec as "timeLimitSec", question_count as "questionCount",
           is_published as "isPublished", published_at as "publishedAt",
           created_at as "createdAt"`,
        [chapterId, creatorId, type, title || null, timeLimitSec || null, questionIds.length]
      );

      const testId = testResult.rows[0].id;

      for (let i = 0; i < questionIds.length; i++) {
        await client.query(
          `INSERT INTO test_questions (test_id, question_id, position)
           VALUES ($1, $2, $3)`,
          [testId, questionIds[i], i + 1]
        );
      }

      await client.query('COMMIT');

      return testResult.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getTestById(id: string): Promise<Test | null> {
    const result = await this.pool.query(
      `SELECT id, chapter_id as "chapterId", creator_id as "creatorId", type,
              title, time_limit_sec as "timeLimitSec", question_count as "questionCount",
              is_published as "isPublished", published_at as "publishedAt",
              target_exam as "targetExam", target_state as "targetState",
              created_at as "createdAt"
       FROM tests WHERE id = $1`,
      [id]
    );
    return result.rows[0] || null;
  }

  async getTestQuestions(testId: string): Promise<any[]> {
    const result = await this.pool.query(
      `SELECT q.id, q.chapter_id as "chapterId", q.text, q.difficulty,
              q.ai_generated as "aiGenerated", tq.position
       FROM test_questions tq
       JOIN questions q ON tq.question_id = q.id
       WHERE tq.test_id = $1
       ORDER BY tq.position ASC`,
      [testId]
    );

    const questions = [];

    for (const q of result.rows) {
      const optionsResult = await this.pool.query(
        `SELECT id, text, is_correct as "isCorrect"
         FROM question_options
         WHERE question_id = $1`,
        [q.id]
      );

      questions.push({
        ...q,
        options: optionsResult.rows,
      });
    }

    return questions;
  }

  async startAttempt(testId: string, userId: string): Promise<TestAttempt> {
    const result = await this.pool.query(
      `INSERT INTO test_attempts (test_id, user_id, started_at)
       SELECT $1, $2, CURRENT_TIMESTAMP
       RETURNING id, test_id as "testId", user_id as "userId",
         started_at as "startedAt", completed_at as "completedAt",
         score, total_questions as "totalQuestions", time_taken_sec as "timeTakenSec"`,
      [testId, userId]
    );

    const test = await this.getTestById(testId);

    return {
      ...result.rows[0],
      totalQuestions: test?.questionCount || 0,
    };
  }

  async submitAnswer(
    attemptId: string,
    questionId: string,
    selectedOptionId: string | null,
    timeTakenMs: number
  ): Promise<boolean> {
    // Check if answer is correct
    const correctResult = await this.pool.query(
      `SELECT is_correct FROM question_options
       WHERE id = $1`,
      [selectedOptionId]
    );

    const isCorrect = correctResult.rows.length > 0 && correctResult.rows[0].is_correct;

    await this.pool.query(
      `INSERT INTO attempt_answers (attempt_id, question_id, selected_option_id,
                                    time_taken_ms, is_correct)
       VALUES ($1, $2, $3, $4, $5)`,
      [attemptId, questionId, selectedOptionId, timeTakenMs, isCorrect]
    );

    return isCorrect;
  }

  async completeAttempt(attemptId: string): Promise<TestResult> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Get all answers for this attempt
      const answersResult = await client.query(
        `SELECT question_id as "questionId", is_correct as "isCorrect",
                time_taken_ms as "timeTakenMs"
         FROM attempt_answers
         WHERE attempt_id = $1`,
        [attemptId]
      );

      const answers = answersResult.rows;
      const correct = answers.filter((a: any) => a.isCorrect).length;
      const incorrect = answers.filter((a: any) => !a.isCorrect).length;
      const total = answers.length;
      const accuracy = total > 0 ? (correct / total) * 100 : 0;
      const score = correct;

      // Calculate time taken
      const timeTaken = answers.reduce((sum: number, a: any) => sum + a.timeTakenMs, 0) / 1000; // Convert to seconds

      // Update attempt with completion
      const attemptResult = await client.query(
        `UPDATE test_attempts
         SET completed_at = CURRENT_TIMESTAMP, score = $1, time_taken_sec = $2
         WHERE id = $3
         RETURNING id, test_id as "testId", user_id as "userId",
           started_at as "startedAt", completed_at as "completedAt",
           score, total_questions as "totalQuestions", time_taken_sec as "timeTakenSec"`,
        [score, Math.round(timeTaken), attemptId]
      );

      await client.query('COMMIT');

      return {
        attempt: attemptResult.rows[0],
        correct,
        incorrect,
        accuracy,
        answers: answers.map((a: any) => ({
          questionId: a.questionId,
          isCorrect: a.isCorrect,
          timeTakenMs: a.timeTakenMs,
        })),
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getUserAttempts(userId: string, testId?: string): Promise<TestAttempt[]> {
    let query = `SELECT id, test_id as "testId", user_id as "userId",
                        started_at as "startedAt", completed_at as "completedAt",
                        score, total_questions as "totalQuestions", time_taken_sec as "timeTakenSec"
                 FROM test_attempts
                 WHERE user_id = $1`;
    const params: any[] = [userId];

    if (testId) {
      query += ` AND test_id = $2`;
      params.push(testId);
    }

    query += ` ORDER BY started_at DESC`;

    const result = await this.pool.query(query, params);
    return result.rows;
  }

  async getLeaderboard(testId: string, limit: number = 100): Promise<any[]> {
    const result = await this.pool.query(
      `SELECT u.id, u.name, u.avatar_url as "avatarUrl", ta.score, ta.time_taken_sec as "timeTakenSec",
              ta.completed_at as "completedAt", COUNT(*) as "attemptCount"
       FROM test_attempts ta
       JOIN users u ON ta.user_id = u.id
       WHERE ta.test_id = $1 AND ta.completed_at IS NOT NULL
       GROUP BY u.id, u.name, u.avatar_url, ta.score, ta.time_taken_sec, ta.completed_at
       ORDER BY ta.score DESC, ta.time_taken_sec ASC
       LIMIT $2`,
      [testId, limit]
    );
    return result.rows;
  }

  async publishTest(testId: string): Promise<void> {
    await this.pool.query(
      `UPDATE tests
       SET is_published = true, published_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [testId]
    );
  }
}

export const createTestService = (pool: Pool) => new TestService(pool);
