import { Pool } from 'pg';
import type { User, ProfileUpdateRequest } from '../types/auth';

class UserService {
  constructor(private pool: Pool) {}

  async getUserById(userId: string): Promise<User | null> {
    const result = await this.pool.query(
      `SELECT
        id, phone, email, name, avatar_url as "avatarUrl",
        exam_target as "examTarget", state, language,
        coins_balance as "coinsBalance", xp, is_active as "isActive",
        created_at as "createdAt", updated_at as "updatedAt"
       FROM users WHERE id = $1`,
      [userId]
    );

    return result.rows[0] || null;
  }

  async getUserByPhone(phone: string): Promise<User | null> {
    const result = await this.pool.query(
      `SELECT
        id, phone, email, name, avatar_url as "avatarUrl",
        exam_target as "examTarget", state, language,
        coins_balance as "coinsBalance", xp, is_active as "isActive",
        created_at as "createdAt", updated_at as "updatedAt"
       FROM users WHERE phone = $1`,
      [phone]
    );

    return result.rows[0] || null;
  }

  async createUser(phone: string, name?: string): Promise<User> {
    const result = await this.pool.query(
      `INSERT INTO users (phone, name, language, coins_balance, xp, is_active)
       VALUES ($1, $2, 'en', 0, 0, true)
       RETURNING id, phone, email, name, avatar_url as "avatarUrl",
         exam_target as "examTarget", state, language,
         coins_balance as "coinsBalance", xp, is_active as "isActive",
         created_at as "createdAt", updated_at as "updatedAt"`,
      [phone, name || '']
    );

    return result.rows[0];
  }

  async updateProfile(userId: string, data: ProfileUpdateRequest): Promise<User> {
    const result = await this.pool.query(
      `UPDATE users
       SET name = $1, email = $2, exam_target = $3, state = $4,
           language = COALESCE($5, language), updated_at = CURRENT_TIMESTAMP
       WHERE id = $6
       RETURNING id, phone, email, name, avatar_url as "avatarUrl",
         exam_target as "examTarget", state, language,
         coins_balance as "coinsBalance", xp, is_active as "isActive",
         created_at as "createdAt", updated_at as "updatedAt"`,
      [data.name, data.email || null, data.examTarget, data.state, data.language, userId]
    );

    if (!result.rows[0]) {
      throw new Error('User not found');
    }

    return result.rows[0];
  }

  async initializeStreak(userId: string): Promise<void> {
    await this.pool.query(
      `INSERT INTO user_streaks (user_id, current_streak, longest_streak, last_activity_date)
       VALUES ($1, 0, 0, CURRENT_DATE)
       ON CONFLICT (user_id) DO NOTHING`,
      [userId]
    );
  }

  async addCoins(userId: string, amount: number, description?: string): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Update user balance
      await client.query('UPDATE users SET coins_balance = coins_balance + $1 WHERE id = $2', [
        amount,
        userId,
      ]);

      // Log transaction
      await client.query(
        `INSERT INTO wallet_transactions (user_id, type, amount_coins, description, status)
         VALUES ($1, 'topup', $2, $3, 'success')`,
        [userId, amount, description]
      );

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async deductCoins(userId: string, amount: number, type: string = 'entry_fee'): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Check balance
      const result = await client.query(
        'SELECT coins_balance FROM users WHERE id = $1 FOR UPDATE',
        [userId]
      );

      if (!result.rows[0] || result.rows[0].coins_balance < amount) {
        throw new Error('Insufficient coins');
      }

      // Deduct coins
      await client.query('UPDATE users SET coins_balance = coins_balance - $1 WHERE id = $2', [
        amount,
        userId,
      ]);

      // Log transaction
      await client.query(
        `INSERT INTO wallet_transactions (user_id, type, amount_coins, status)
         VALUES ($1, $2, -$3, 'success')`,
        [userId, type, amount]
      );

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}

export const createUserService = (pool: Pool) => new UserService(pool);
