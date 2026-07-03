import { Pool } from 'pg';
import { createWalletService } from './wallet.service';

export interface Challenge {
  id: string;
  testId: string;
  creatorId: string;
  entryFeeCoins: number;
  prizePoolCoins: number;
  maxParticipants?: number;
  startAt: Date;
  endAt: Date;
  status: 'draft' | 'active' | 'closed' | 'distributed';
  createdAt: Date;
}

export interface ChallengeParticipant {
  id: string;
  challengeId: string;
  userId: string;
  attemptId?: string;
  rank?: number;
  prizeWonCoins: number;
  joinedAt: Date;
}

class ChallengeService {
  private walletService: ReturnType<typeof createWalletService>;

  constructor(private pool: Pool) {
    this.walletService = createWalletService(pool);
  }

  async createChallenge(
    testId: string,
    creatorId: string,
    entryFeeCoins: number,
    durationMinutes: number = 1440,
    maxParticipants?: number
  ): Promise<Challenge> {
    const endAt = new Date();
    endAt.setMinutes(endAt.getMinutes() + durationMinutes);

    const result = await this.pool.query(
      `INSERT INTO challenges (test_id, creator_id, entry_fee_coins, prize_pool_coins,
                               max_participants, start_at, end_at, status)
       VALUES ($1, $2, $3, 0, $4, CURRENT_TIMESTAMP, $5, 'draft')
       RETURNING id, test_id as "testId", creator_id as "creatorId",
         entry_fee_coins as "entryFeeCoins", prize_pool_coins as "prizePoolCoins",
         max_participants as "maxParticipants", start_at as "startAt",
         end_at as "endAt", status, created_at as "createdAt"`,
      [testId, creatorId, entryFeeCoins, maxParticipants || null, endAt]
    );

    return result.rows[0];
  }

  async getChallengeById(id: string): Promise<Challenge | null> {
    const result = await this.pool.query(
      `SELECT id, test_id as "testId", creator_id as "creatorId",
              entry_fee_coins as "entryFeeCoins", prize_pool_coins as "prizePoolCoins",
              max_participants as "maxParticipants", start_at as "startAt",
              end_at as "endAt", status, created_at as "createdAt"
       FROM challenges WHERE id = $1`,
      [id]
    );

    return result.rows[0] || null;
  }

  async joinChallenge(challengeId: string, userId: string): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Get challenge details
      const challengeResult = await client.query(
        `SELECT entry_fee_coins as "entryFeeCoins", status, max_participants as "maxParticipants"
         FROM challenges WHERE id = $1 FOR UPDATE`,
        [challengeId]
      );

      if (!challengeResult.rows[0]) {
        throw new Error('Challenge not found');
      }

      const challenge = challengeResult.rows[0];

      if (challenge.status !== 'draft' && challenge.status !== 'active') {
        throw new Error('Challenge is not accepting participants');
      }

      // Check max participants
      if (challenge.maxParticipants) {
        const countResult = await client.query(
          `SELECT COUNT(*) as count FROM challenge_participants WHERE challenge_id = $1`,
          [challengeId]
        );

        if (countResult.rows[0].count >= challenge.maxParticipants) {
          throw new Error('Challenge is full');
        }
      }

      // Deduct coins from user
      await this.walletService.deductCoins(
        userId,
        challenge.entryFeeCoins,
        'entry_fee',
        `Challenge entry: ${challengeId}`,
        challengeId
      );

      // Add participant
      await client.query(
        `INSERT INTO challenge_participants (challenge_id, user_id, joined_at)
         VALUES ($1, $2, CURRENT_TIMESTAMP)
         ON CONFLICT DO NOTHING`,
        [challengeId, userId]
      );

      // Update prize pool
      await client.query(
        `UPDATE challenges
         SET prize_pool_coins = prize_pool_coins + $1, status = 'active'
         WHERE id = $2`,
        [challenge.entryFeeCoins, challengeId]
      );

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getParticipants(challengeId: string): Promise<ChallengeParticipant[]> {
    const result = await this.pool.query(
      `SELECT id, challenge_id as "challengeId", user_id as "userId",
              attempt_id as "attemptId", rank, prize_won_coins as "prizeWonCoins",
              joined_at as "joinedAt"
       FROM challenge_participants
       WHERE challenge_id = $1
       ORDER BY rank ASC NULLS LAST`,
      [challengeId]
    );

    return result.rows;
  }

  async submitAttemptToChallenge(
    challengeId: string,
    userId: string,
    attemptId: string,
    score: number
  ): Promise<void> {
    await this.pool.query(
      `UPDATE challenge_participants
       SET attempt_id = $1
       WHERE challenge_id = $2 AND user_id = $3`,
      [attemptId, challengeId, userId]
    );
  }

  async closeChallenge(challengeId: string): Promise<void> {
    await this.pool.query(
      `UPDATE challenges SET status = 'closed' WHERE id = $1`,
      [challengeId]
    );
  }

  async distributePrizes(challengeId: string): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Get challenge and participants
      const challengeResult = await client.query(
        `SELECT creator_id as "creatorId", prize_pool_coins as "prizePoolCoins"
         FROM challenges WHERE id = $1`,
        [challengeId]
      );

      if (!challengeResult.rows[0]) {
        throw new Error('Challenge not found');
      }

      const challenge = challengeResult.rows[0];
      const totalPool = challenge.prizePoolCoins;

      // Get ranked participants with scores
      const participantsResult = await client.query(
        `SELECT cp.id, cp.user_id as "userId", ta.score, ta.time_taken_sec as "timeTakenSec"
         FROM challenge_participants cp
         LEFT JOIN test_attempts ta ON cp.attempt_id = ta.id
         WHERE cp.challenge_id = $1
         ORDER BY COALESCE(ta.score, 0) DESC, COALESCE(ta.time_taken_sec, 999999) ASC`,
        [challengeId]
      );

      const participants = participantsResult.rows;

      if (participants.length < 3) {
        // Refund if not enough participants
        await client.query(
          `UPDATE challenge_participants
           SET prize_won_coins = (SELECT entry_fee_coins FROM challenges WHERE id = $1)
           WHERE challenge_id = $1`,
          [challengeId]
        );
      } else {
        // Calculate prize distribution
        const platformCut = Math.floor(totalPool * 0.15);
        const creatorReward = Math.floor(totalPool * 0.10);
        const participantPrizes = totalPool - platformCut - creatorReward;

        const prizes = [
          Math.floor(participantPrizes * 0.40),
          Math.floor(participantPrizes * 0.25),
          Math.floor(participantPrizes * 0.15),
        ];

        // Distribute prizes to top participants
        for (let i = 0; i < Math.min(participants.length, 3); i++) {
          const participant = participants[i];
          const prize = prizes[i] || 0;

          await client.query(
            `UPDATE challenge_participants
             SET rank = $1, prize_won_coins = $2
             WHERE id = $3`,
            [i + 1, prize, participant.id]
          );

          // Add coins to user
          await client.query(
            `UPDATE users SET coins_balance = coins_balance + $1 WHERE id = $2`,
            [prize, participant.userId]
          );

          // Log transaction
          await client.query(
            `INSERT INTO wallet_transactions (user_id, type, amount_coins, status, reference_id, description)
             VALUES ($1, 'prize', $2, 'success', $3, $4)`,
            [participant.userId, prize, challengeId, `Challenge prize - Rank ${i + 1}`]
          );
        }

        // Give creator reward
        await client.query(
          `UPDATE users SET coins_balance = coins_balance + $1 WHERE id = $2`,
          [creatorReward, challenge.creatorId]
        );

        await client.query(
          `INSERT INTO wallet_transactions (user_id, type, amount_coins, status, reference_id, description)
           VALUES ($1, 'creator_reward', $2, 'success', $3, $4)`,
          [challenge.creatorId, creatorReward, challengeId, `Challenge creator reward`]
        );
      }

      // Update challenge status
      await client.query(
        `UPDATE challenges SET status = 'distributed' WHERE id = $1`,
        [challengeId]
      );

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getActiveChallenges(limit: number = 20, offset: number = 0): Promise<any[]> {
    const result = await this.pool.query(
      `SELECT c.id, c.test_id as "testId", c.creator_id as "creatorId",
              c.entry_fee_coins as "entryFeeCoins", c.prize_pool_coins as "prizePoolCoins",
              c.status, c.end_at as "endAt",
              t.title, u.name as "creatorName",
              COUNT(cp.id) as "participantCount"
       FROM challenges c
       JOIN tests t ON c.test_id = t.id
       JOIN users u ON c.creator_id = u.id
       LEFT JOIN challenge_participants cp ON c.id = cp.challenge_id
       WHERE c.status IN ('draft', 'active')
       GROUP BY c.id, t.title, u.name
       ORDER BY c.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    return result.rows;
  }

  async getUserChallenges(userId: string): Promise<any[]> {
    const result = await this.pool.query(
      `SELECT c.id, c.test_id as "testId", c.creator_id as "creatorId",
              c.entry_fee_coins as "entryFeeCoins", c.prize_pool_coins as "prizePoolCoins",
              c.status, c.created_at as "createdAt",
              t.title, COUNT(cp.id) as "participantCount"
       FROM challenges c
       JOIN tests t ON c.test_id = t.id
       LEFT JOIN challenge_participants cp ON c.id = cp.challenge_id
       WHERE c.creator_id = $1
       GROUP BY c.id, t.title
       ORDER BY c.created_at DESC`,
      [userId]
    );

    return result.rows;
  }
}

export const createChallengeService = (pool: Pool) => new ChallengeService(pool);
