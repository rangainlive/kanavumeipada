import { Pool } from 'pg';
import { readFileSync } from 'fs';
import { join } from 'path';

export async function runMigrations(pool: Pool): Promise<void> {
  try {
    const sql = readFileSync(join(__dirname, 'init.sql'), 'utf8');
    await pool.query(sql);
    console.log('✅ Database schema initialized successfully');
  } catch (err) {
    console.error('❌ Database migration failed:', (err as Error).message);
    throw err;
  }
}
