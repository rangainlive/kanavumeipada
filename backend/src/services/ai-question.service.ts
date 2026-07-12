import { GoogleGenerativeAI } from '@google/generative-ai';
import { Pool } from 'pg';

export interface GeneratedQuestion {
  id: string;
  chapterId: string;
  text: string;
  options: { id: string; text: string; isCorrect: boolean }[];
  correctIndex: number;
  explanation: string;
  difficulty: number;
  bloomLevel: string;
  aiGenerated: true;
  isApproved: boolean;
}

interface RawGenerated {
  question: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  difficulty: number;
  bloomLevel: string;
}

const BLOOM_LEVELS = ['remember', 'understand', 'apply', 'analyze'];

function buildPrompt(
  chunkText: string,
  chapterTitle: string,
  count: number,
  difficulty: number,
  bloomLevel: string
): string {
  const difficultyLabel = ['', 'recall a fact', 'understand a concept', 'apply or compare concepts'][difficulty];
  return `You are an expert MCQ question setter for Indian competitive exams (TNPSC, UPSC, SSC, Banking).
Using ONLY the content below about "${chapterTitle}", generate exactly ${count} multiple-choice questions.

RULES — follow strictly:
1. All 4 options must be plausible terms from the SAME topic (never random, unrelated words).
2. Exactly ONE option is correct — no trick questions.
3. Bloom's taxonomy level: ${bloomLevel} — questions should ask students to ${difficultyLabel}.
4. Difficulty ${difficulty}/3: ${difficultyLabel}.
5. Explanation must directly quote or reference a sentence from the content.
6. No duplicate questions.
7. Question text must be at least 15 words.

CONTENT:
---
${chunkText.slice(0, 6000)}
---

Respond with ONLY a valid JSON array — no markdown, no code fences, no extra text:
[
  {
    "question": "string (the MCQ question text)",
    "options": ["option A", "option B", "option C", "option D"],
    "correctIndex": 0,
    "explanation": "string (cite the relevant sentence from the content)",
    "difficulty": ${difficulty},
    "bloomLevel": "${bloomLevel}"
  }
]`;
}

function validateRaw(raw: unknown): RawGenerated | null {
  if (!raw || typeof raw !== 'object') return null;
  const r = raw as Record<string, unknown>;
  if (
    typeof r.question !== 'string' || r.question.length < 15 ||
    !Array.isArray(r.options) || r.options.length !== 4 ||
    !r.options.every((o: unknown) => typeof o === 'string' && (o as string).length > 0) ||
    typeof r.correctIndex !== 'number' || r.correctIndex < 0 || r.correctIndex > 3 ||
    typeof r.explanation !== 'string' ||
    typeof r.difficulty !== 'number' ||
    typeof r.bloomLevel !== 'string'
  ) return null;
  // No duplicate options
  const unique = new Set((r.options as string[]).map(o => o.trim().toLowerCase()));
  if (unique.size < 4) return null;
  return r as unknown as RawGenerated;
}

export class AiQuestionService {
  private genAI: GoogleGenerativeAI | null = null;

  constructor(private pool: Pool) {
    const key = process.env.GEMINI_API_KEY;
    if (key) {
      this.genAI = new GoogleGenerativeAI(key);
    } else {
      console.warn('⚠️  GEMINI_API_KEY not set — AI question generation disabled');
    }
  }

  get isEnabled() { return this.genAI !== null; }

  async generateFromChapter(
    chapterId: string,
    opts: { count: number; difficulty: number; bloomLevel: string }
  ): Promise<GeneratedQuestion[]> {
    if (!this.genAI) throw new Error('AI generation is disabled: GEMINI_API_KEY is not configured');
    const { count, difficulty, bloomLevel } = opts;

    // Fetch chapter
    const chapterResult = await this.pool.query(
      `SELECT id, title, content_text FROM chapters WHERE id = $1`,
      [chapterId]
    );
    const chapter = chapterResult.rows[0];
    if (!chapter) throw new Error('Chapter not found');
    if (!chapter.content_text || chapter.content_text.trim().length < 100) {
      throw new Error('Chapter needs at least 100 characters of content text to generate questions. Add content first.');
    }

    // Call Gemini
    const raw = await this.callGemini(chapter.content_text, chapter.title, count, difficulty, bloomLevel);

    // Save valid questions to DB
    const saved: GeneratedQuestion[] = [];
    for (const q of raw) {
      try {
        const question = await this.saveQuestion(chapterId, q);
        saved.push(question);
      } catch (_) {
        // Skip DB errors on individual questions — keep going
      }
    }
    return saved;
  }

  private async callGemini(
    contentText: string,
    chapterTitle: string,
    count: number,
    difficulty: number,
    bloomLevel: string
  ): Promise<RawGenerated[]> {
    const model = this.genAI!.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const prompt = buildPrompt(contentText, chapterTitle, count, difficulty, bloomLevel);

    let responseText = '';
    try {
      const result = await model.generateContent(prompt);
      responseText = result.response.text().trim();
    } catch (err: any) {
      throw new Error(`Gemini API error: ${err.message}`);
    }

    // Strip markdown fences if model wrapped in them
    const cleaned = responseText
      .replace(/^```(?:json)?/i, '')
      .replace(/```$/i, '')
      .trim();

    let parsed: unknown;
    try {
      parsed = JSON.parse(cleaned);
    } catch {
      throw new Error('Gemini returned invalid JSON. Try again or simplify the content.');
    }

    if (!Array.isArray(parsed)) throw new Error('Gemini response was not a JSON array');

    const valid: RawGenerated[] = [];
    for (const item of parsed) {
      const v = validateRaw(item);
      if (v) valid.push(v);
    }
    if (valid.length === 0) throw new Error('No valid questions in Gemini response');
    return valid;
  }

  private async saveQuestion(chapterId: string, q: RawGenerated): Promise<GeneratedQuestion> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const qResult = await client.query(
        `INSERT INTO questions
           (chapter_id, text, difficulty, ai_generated, is_approved, explanation, bloom_level)
         VALUES ($1, $2, $3, true, false, $4, $5)
         RETURNING id, chapter_id as "chapterId", text, difficulty,
                   ai_generated as "aiGenerated", is_approved as "isApproved",
                   explanation, bloom_level as "bloomLevel"`,
        [chapterId, q.question, q.difficulty, q.explanation, q.bloomLevel]
      );
      const saved = qResult.rows[0];

      const optionRows: { id: string; text: string; isCorrect: boolean }[] = [];
      for (let i = 0; i < q.options.length; i++) {
        const optResult = await client.query(
          `INSERT INTO question_options (question_id, text, is_correct)
           VALUES ($1, $2, $3)
           RETURNING id, text, is_correct as "isCorrect"`,
          [saved.id, q.options[i], i === q.correctIndex]
        );
        optionRows.push(optResult.rows[0]);
      }

      await client.query('COMMIT');

      return {
        ...saved,
        options: optionRows,
        correctIndex: q.correctIndex,
        aiGenerated: true,
      };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async approveQuestion(questionId: string): Promise<void> {
    await this.pool.query(
      `UPDATE questions SET is_approved = true, updated_at = NOW() WHERE id = $1`,
      [questionId]
    );
  }

  async deleteQuestion(questionId: string): Promise<void> {
    await this.pool.query(`DELETE FROM questions WHERE id = $1`, [questionId]);
  }

  async updateChapterContent(chapterId: string, contentText: string): Promise<void> {
    await this.pool.query(
      `UPDATE chapters SET content_text = $1, updated_at = NOW() WHERE id = $2`,
      [contentText, chapterId]
    );
  }

  async getPendingQuestions(chapterId: string): Promise<GeneratedQuestion[]> {
    const result = await this.pool.query(
      `SELECT q.id, q.chapter_id as "chapterId", q.text, q.difficulty,
              q.ai_generated as "aiGenerated", q.is_approved as "isApproved",
              q.explanation, q.bloom_level as "bloomLevel"
       FROM questions q
       WHERE q.chapter_id = $1 AND q.ai_generated = true AND q.is_approved = false
       ORDER BY q.created_at DESC`,
      [chapterId]
    );

    const questions = result.rows;
    for (const q of questions) {
      const optResult = await this.pool.query(
        `SELECT id, text, is_correct as "isCorrect" FROM question_options WHERE question_id = $1`,
        [q.id]
      );
      q.options = optResult.rows;
      q.correctIndex = optResult.rows.findIndex((o: { isCorrect: boolean }) => o.isCorrect);
    }
    return questions;
  }
}

export const createAiQuestionService = (pool: Pool) => new AiQuestionService(pool);
