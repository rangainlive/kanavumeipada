import { Pool } from 'pg';
import { createWalletService } from './wallet.service';

export interface Challenge {
  id: string;
  gameType: 'test' | 'minigame';
  testId?: string;
  minigameKey?: string;
  creatorId: string;
  entryFeeCoins: number;
  prizePoolCoins: number;
  minParticipants: number;
  maxParticipants?: number;
  isPublic: boolean;
  joinCode?: string;
  gameConfig?: any;
  startAt: Date;
  endAt: Date;
  status: 'draft' | 'active' | 'closed' | 'distributed';
  createdAt: Date;
}

const JOIN_CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I to avoid ambiguity

function generateJoinCode(): string {
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += JOIN_CODE_CHARS[Math.floor(Math.random() * JOIN_CODE_CHARS.length)];
  }
  return code;
}

export interface ChallengeParticipant {
  id: string;
  challengeId: string;
  userId: string;
  attemptId?: string;
  score?: number;
  timeTakenMs?: number;
  rank?: number;
  prizeWonCoins: number;
  joinedAt: Date;
}

class ChallengeService {
  private walletService: ReturnType<typeof createWalletService>;

  constructor(private pool: Pool) {
    this.walletService = createWalletService(pool);
  }

  async createChallenge(opts: {
    gameType: 'test' | 'minigame';
    testId?: string;
    minigameKey?: string;
    creatorId: string;
    entryFeeCoins: number;
    durationMinutes?: number;
    minParticipants?: number;
    maxParticipants?: number;
    isPublic?: boolean;
    gameConfig?: any;
  }): Promise<Challenge> {
    const endAt = new Date();
    endAt.setMinutes(endAt.getMinutes() + (opts.durationMinutes ?? 1440));
    const isPublic = opts.isPublic ?? true;

    // Private battles get a short shareable code; retry on the rare
    // collision against the unique index instead of pre-checking.
    let joinCode: string | null = null;
    if (!isPublic) {
      for (let attempt = 0; attempt < 5; attempt++) {
        const candidate = generateJoinCode();
        const existing = await this.pool.query(
          `SELECT 1 FROM challenges WHERE join_code = $1`,
          [candidate]
        );
        if (existing.rows.length === 0) {
          joinCode = candidate;
          break;
        }
      }
      if (!joinCode) {
        throw new Error('Could not generate a unique join code, please try again');
      }
    }

    const result = await this.pool.query(
      `INSERT INTO challenges (game_type, test_id, minigame_key, creator_id, entry_fee_coins,
                               prize_pool_coins, min_participants, max_participants,
                               is_public, join_code, game_config, start_at, end_at, status)
       VALUES ($1, $2, $3, $4, $5, 0, $6, $7, $8, $9, $10, CURRENT_TIMESTAMP, $11, 'draft')
       RETURNING id, game_type as "gameType", test_id as "testId", minigame_key as "minigameKey",
         creator_id as "creatorId", entry_fee_coins as "entryFeeCoins", prize_pool_coins as "prizePoolCoins",
         min_participants as "minParticipants", max_participants as "maxParticipants",
         is_public as "isPublic", join_code as "joinCode", game_config as "gameConfig",
         start_at as "startAt", end_at as "endAt", status, created_at as "createdAt"`,
      [
        opts.gameType,
        opts.testId || null,
        opts.minigameKey || null,
        opts.creatorId,
        opts.entryFeeCoins,
        opts.minParticipants ?? 3,
        opts.maxParticipants || null,
        isPublic,
        joinCode,
        opts.gameConfig ? JSON.stringify(opts.gameConfig) : null,
        endAt,
      ]
    );

    return result.rows[0];
  }

  async getChallengeById(id: string): Promise<Challenge | null> {
    const result = await this.pool.query(
      `SELECT id, game_type as "gameType", test_id as "testId", minigame_key as "minigameKey",
              creator_id as "creatorId",
              entry_fee_coins as "entryFeeCoins", prize_pool_coins as "prizePoolCoins",
              min_participants as "minParticipants", max_participants as "maxParticipants",
              is_public as "isPublic", join_code as "joinCode", game_config as "gameConfig",
              start_at as "startAt",
              end_at as "endAt", status, created_at as "createdAt"
       FROM challenges WHERE id = $1`,
      [id]
    );

    return result.rows[0] || null;
  }

  async getChallengeByJoinCode(joinCode: string): Promise<Challenge | null> {
    const result = await this.pool.query(
      `SELECT id, game_type as "gameType", test_id as "testId", minigame_key as "minigameKey",
              creator_id as "creatorId",
              entry_fee_coins as "entryFeeCoins", prize_pool_coins as "prizePoolCoins",
              min_participants as "minParticipants", max_participants as "maxParticipants",
              is_public as "isPublic", join_code as "joinCode", game_config as "gameConfig",
              start_at as "startAt",
              end_at as "endAt", status, created_at as "createdAt"
       FROM challenges WHERE join_code = $1`,
      [joinCode.toUpperCase()]
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

      // Already joined? Bail out before touching coins. Safe against a
      // concurrent double-join because both calls must first acquire the
      // FOR UPDATE lock on the challenge row above, so they serialize here.
      const existingResult = await client.query(
        `SELECT 1 FROM challenge_participants WHERE challenge_id = $1 AND user_id = $2`,
        [challengeId, userId]
      );
      if (existingResult.rows.length > 0) {
        throw new Error('You have already joined this challenge');
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

      // Deduct coins from user — on this same client/transaction, so a
      // failure anywhere below rolls the deduction back too instead of
      // leaving a committed charge with no participant row to show for it.
      await this.walletService.deductCoinsWithClient(
        client,
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

  async joinChallengeByCode(joinCode: string, userId: string): Promise<Challenge> {
    const challenge = await this.getChallengeByJoinCode(joinCode);
    if (!challenge) {
      throw new Error('Invalid or expired join code');
    }
    await this.joinChallenge(challenge.id, userId);
    return challenge;
  }

  async getParticipants(challengeId: string): Promise<ChallengeParticipant[]> {
    const result = await this.pool.query(
      `SELECT id, challenge_id as "challengeId", user_id as "userId",
              attempt_id as "attemptId", score, time_taken_ms as "timeTakenMs",
              rank, prize_won_coins as "prizeWonCoins",
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

  async submitMinigameScore(
    challengeId: string,
    userId: string,
    score: number,
    timeTakenMs?: number
  ): Promise<void> {
    const challenge = await this.getChallengeById(challengeId);
    if (!challenge) {
      throw new Error('Challenge not found');
    }
    if (challenge.gameType !== 'minigame') {
      throw new Error('Challenge is not a minigame challenge');
    }

    const result = await this.pool.query(
      `UPDATE challenge_participants
       SET score = $1, time_taken_ms = $2
       WHERE challenge_id = $3 AND user_id = $4 AND score IS NULL`,
      [score, timeTakenMs ?? null, challengeId, userId]
    );

    if (result.rowCount === 0) {
      throw new Error('Score already submitted, or you have not joined this challenge');
    }
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
        `SELECT creator_id as "creatorId", prize_pool_coins as "prizePoolCoins",
                min_participants as "minParticipants"
         FROM challenges WHERE id = $1`,
        [challengeId]
      );

      if (!challengeResult.rows[0]) {
        throw new Error('Challenge not found');
      }

      const challenge = challengeResult.rows[0];
      const totalPool = challenge.prizePoolCoins;

      // Get ranked participants with scores — normalizes quiz-test scores
      // (via test_attempts) and raw minigame scores into one ranking shape.
      const participantsResult = await client.query(
        `SELECT cp.id, cp.user_id as "userId",
                COALESCE(ta.score, cp.score, 0) as score,
                COALESCE(ta.time_taken_sec * 1000, cp.time_taken_ms, 999999999) as "timeTakenMs"
         FROM challenge_participants cp
         LEFT JOIN test_attempts ta ON cp.attempt_id = ta.id
         WHERE cp.challenge_id = $1
         ORDER BY score DESC, "timeTakenMs" ASC`,
        [challengeId]
      );

      const participants = participantsResult.rows;
      const minParticipants = challenge.minParticipants ?? 3;

      if (participants.length < minParticipants) {
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
      `SELECT c.id, c.game_type as "gameType", c.test_id as "testId",
              c.minigame_key as "minigameKey", c.creator_id as "creatorId",
              c.entry_fee_coins as "entryFeeCoins", c.prize_pool_coins as "prizePoolCoins",
              c.min_participants as "minParticipants", c.max_participants as "maxParticipants",
              c.status, c.end_at as "endAt",
              t.title, u.name as "creatorName",
              COUNT(cp.id) as "participantCount"
       FROM challenges c
       LEFT JOIN tests t ON c.test_id = t.id
       JOIN users u ON c.creator_id = u.id
       LEFT JOIN challenge_participants cp ON c.id = cp.challenge_id
       WHERE c.status IN ('draft', 'active') AND c.is_public = true
       GROUP BY c.id, t.title, u.name
       ORDER BY c.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    return result.rows;
  }

  async getUserChallenges(userId: string): Promise<any[]> {
    const result = await this.pool.query(
      `SELECT c.id, c.game_type as "gameType", c.test_id as "testId",
              c.minigame_key as "minigameKey", c.creator_id as "creatorId",
              c.entry_fee_coins as "entryFeeCoins", c.prize_pool_coins as "prizePoolCoins",
              c.min_participants as "minParticipants", c.max_participants as "maxParticipants",
              c.is_public as "isPublic", c.join_code as "joinCode",
              c.status, c.created_at as "createdAt",
              t.title, COUNT(cp.id) as "participantCount",
              me.score as "myScore", me.rank as "myRank",
              me.prize_won_coins as "myPrizeWonCoins"
       FROM challenges c
       LEFT JOIN tests t ON c.test_id = t.id
       LEFT JOIN challenge_participants cp ON c.id = cp.challenge_id
       LEFT JOIN challenge_participants me ON me.challenge_id = c.id AND me.user_id = $1
       WHERE c.creator_id = $1
          OR c.id IN (SELECT challenge_id FROM challenge_participants WHERE user_id = $1)
       GROUP BY c.id, t.title, me.score, me.rank, me.prize_won_coins
       ORDER BY c.created_at DESC`,
      [userId]
    );

    return result.rows;
  }
}

export const createChallengeService = (pool: Pool) => new ChallengeService(pool);
