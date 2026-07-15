import { Pool } from 'pg';
import { readFileSync } from 'fs';
import { join } from 'path';

interface PyqOptionData {
  id: string;
  text: string;
  text_tamil: string | null;
}

interface PyqQuestionData {
  id: string;
  topic: string;
  text: string;
  text_tamil: string;
  exam_name: string | null;
  exam_year: number | null;
  options: PyqOptionData[];
}

const PYQ_SUBJECT_NAME = 'TNPSC Group 1';
const PYQ_CHAPTER_TITLE = 'Previous Year Questions — Economics';

async function getOrCreatePyqChapter(pool: Pool): Promise<string> {
  const subjectResult = await pool.query(
    `SELECT id FROM subjects WHERE name = $1`,
    [PYQ_SUBJECT_NAME]
  );
  if (subjectResult.rows.length === 0) {
    throw new Error(`Subject "${PYQ_SUBJECT_NAME}" not found — run the base migration first`);
  }
  const subjectId = subjectResult.rows[0].id;

  const chapterResult = await pool.query(
    `SELECT id FROM chapters WHERE subject_id = $1 AND title = $2`,
    [subjectId, PYQ_CHAPTER_TITLE]
  );
  if (chapterResult.rows.length > 0) {
    return chapterResult.rows[0].id;
  }

  const inserted = await pool.query(
    `INSERT INTO chapters (subject_id, title, title_tamil, order_index, is_approved)
     VALUES ($1, $2, $3, 999, true)
     RETURNING id`,
    [subjectId, PYQ_CHAPTER_TITLE, 'முந்தைய ஆண்டு வினாக்கள் — பொருளாதாரம்']
  );
  return inserted.rows[0].id;
}

// pyq_data.json ships with a fixed id pre-assigned to every question/option
// (see pyq_import_log.json for the same ids as a plain-text manifest). This
// lets us check what's already imported with one bulk primary-key lookup
// instead of a per-question query, and re-running on every boot is safe: a
// question already present in the DB is skipped, so redeploys never duplicate.
export async function importPyqData(pool: Pool): Promise<void> {
  const dataPath = join(__dirname, 'pyq_data.json');
  const questions: PyqQuestionData[] = JSON.parse(readFileSync(dataPath, 'utf8'));

  const chapterId = await getOrCreatePyqChapter(pool);

  const allIds = questions.map(q => q.id);
  const existingResult = await pool.query(
    `SELECT id FROM questions WHERE id = ANY($1::uuid[])`,
    [allIds]
  );
  const existingIds = new Set(existingResult.rows.map(r => r.id));

  const toImport = questions.filter(q => !existingIds.has(q.id));
  let inserted = 0;

  for (const q of toImport) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      await client.query(
        `INSERT INTO questions
           (id, chapter_id, text, text_tamil, difficulty, source, is_approved, is_pyq, topic, exam_name, exam_year)
         VALUES ($1, $2, $3, $4, 2, 'TNPSC Previous Year Questions', true, true, $5, $6, $7)`,
        [q.id, chapterId, q.text, q.text_tamil, q.topic, q.exam_name, q.exam_year]
      );

      for (const opt of q.options) {
        await client.query(
          `INSERT INTO question_options (id, question_id, text, text_tamil, is_correct)
           VALUES ($1, $2, $3, $4, false)`,
          [opt.id, q.id, opt.text, opt.text_tamil]
        );
      }

      await client.query('COMMIT');
      inserted++;
    } catch (err) {
      await client.query('ROLLBACK');
      console.error(`⚠️  Failed to import PYQ question ${q.id}: ${(err as Error).message}`);
    } finally {
      client.release();
    }
  }

  console.log(`✅ PYQ import: ${inserted} inserted, ${existingIds.size} already present (of ${questions.length})`);
}
