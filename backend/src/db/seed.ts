import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/kanavumeipada',
});

const seedData = async () => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Create subjects
    const subjectsResult = await client.query(
      `INSERT INTO subjects (name, exam_category)
       VALUES
         ('Indian History', 'UPSC'),
         ('Political Science', 'UPSC'),
         ('Geography', 'UPSC'),
         ('Biology', 'NEET'),
         ('Chemistry', 'NEET'),
         ('Mathematics', 'JEE'),
         ('General Knowledge', 'SSC'),
         ('English', 'Banking')
       RETURNING id, name`
    );

    const subjects = subjectsResult.rows;
    console.log('✅ Created subjects:', subjects.map(s => s.name).join(', '));

    // Create chapters for Indian History
    const historySubject = subjects.find((s: any) => s.name === 'Indian History');
    const chaptersResult = await client.query(
      `INSERT INTO chapters (subject_id, title, content_text, order_index, is_approved)
       VALUES
         ($1, 'Ancient India', 'Ancient India includes the Indus Valley Civilization...', 1, true),
         ($1, 'Vedic Period', 'The Vedic period is an important part of Indian history...', 2, true),
         ($1, 'Mauryan Empire', 'The Mauryan Empire was a powerful empire in ancient India...', 3, true),
         ($1, 'Mughal Empire', 'The Mughal Empire was one of the largest empires in Indian history...', 4, true)
       RETURNING id, title`,
      [historySubject?.id]
    );

    const chapters = chaptersResult.rows;
    console.log('✅ Created chapters:', chapters.map((c: any) => c.title).join(', '));

    // Create questions for Ancient India chapter
    const ancientIndiaChapter = chapters[0];
    const questionsData = [
      {
        text: 'Which civilization flourished on the banks of the Indus River?',
        difficulty: 1,
        options: [
          { text: 'Vedic Civilization', isCorrect: false },
          { text: 'Indus Valley Civilization', isCorrect: true },
          { text: 'Aryan Civilization', isCorrect: false },
          { text: 'Mughal Civilization', isCorrect: false },
        ],
      },
      {
        text: 'The capital of Indus Valley Civilization was:',
        difficulty: 2,
        options: [
          { text: 'Ayodhya', isCorrect: false },
          { text: 'Mathura', isCorrect: false },
          { text: 'Mohenjo-Daro and Harappa', isCorrect: true },
          { text: 'Varanasi', isCorrect: false },
        ],
      },
      {
        text: 'Which of the following is NOT a feature of Indus Valley Civilization?',
        difficulty: 3,
        options: [
          { text: 'Planned cities', isCorrect: false },
          { text: 'Advanced drainage system', isCorrect: false },
          { text: 'Written script (undeciphered)', isCorrect: false },
          { text: 'Large temples and pyramids', isCorrect: true },
        ],
      },
      {
        text: 'Mohenjo-Daro was discovered in which year?',
        difficulty: 2,
        options: [
          { text: '1920', isCorrect: true },
          { text: '1905', isCorrect: false },
          { text: '1935', isCorrect: false },
          { text: '1910', isCorrect: false },
        ],
      },
      {
        text: 'The economy of Indus Valley people was based on:',
        difficulty: 2,
        options: [
          { text: 'Agriculture and Animal husbandry', isCorrect: true },
          { text: 'Trade and Commerce', isCorrect: false },
          { text: 'Hunting and Fishing', isCorrect: false },
          { text: 'Mining only', isCorrect: false },
        ],
      },
    ];

    for (const qData of questionsData) {
      const qResult = await client.query(
        `INSERT INTO questions (chapter_id, text, difficulty, ai_generated, is_approved)
         VALUES ($1, $2, $3, false, true)
         RETURNING id`,
        [ancientIndiaChapter.id, qData.text, qData.difficulty]
      );

      const questionId = qResult.rows[0].id;

      for (const option of qData.options) {
        await client.query(
          `INSERT INTO question_options (question_id, text, is_correct)
           VALUES ($1, $2, $3)`,
          [questionId, option.text, option.isCorrect]
        );
      }
    }

    console.log('✅ Created 5 sample questions');

    // Create achievements
    await client.query(
      `INSERT INTO achievements (key, name, description, xp_reward, coins_reward)
       VALUES
         ('streak_7', 'Week Warrior', 'Complete 7-day streak', 50, 50),
         ('streak_30', 'Monthly Master', 'Complete 30-day streak', 300, 300),
         ('streak_100', 'Centennial Champion', 'Complete 100-day streak', 1000, 1000),
         ('first_test', 'First Steps', 'Complete your first test', 10, 0),
         ('test_master', 'Test Master', 'Score 100% on 5 tests', 200, 100),
         ('challenge_creator', 'Challenge Creator', 'Create your first challenge', 25, 0),
         ('challenge_winner', 'Challenge Champion', 'Win a challenge', 50, 50)`
    );

    console.log('✅ Created achievement templates');

    await client.query('COMMIT');
    console.log('\n✅ Seed data inserted successfully!');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error seeding data:', error);
    throw error;
  } finally {
    client.release();
  }
};

seedData().then(() => {
  pool.end();
  process.exit(0);
});
