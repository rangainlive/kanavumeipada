import { Pool } from 'pg';

export interface WalletTransaction {
  id: string;
  userId: string;
  type: string;
  amountCoins: number;
  referenceId?: string;
  description?: string;
  status: string;
  createdAt: Date;
}

export interface CoinPack {
  coins: number;
  priceInr: number;
}

class WalletService {
  private coinPacks: CoinPack[] = [
    { coins: 120, priceInr: 10 },
    { coins: 350, priceInr: 29 },
    { coins: 650, priceInr: 49 },
    { coins: 1400, priceInr: 99 },
    { coins: 3000, priceInr: 199 },
  ];

  constructor(private pool: Pool) {}

  async getBalance(userId: string): Promise<number> {
    const result = await this.pool.query(
      `SELECT coins_balance FROM users WHERE id = $1`,
      [userId]
    );

    if (!result.rows[0]) {
      throw new Error('User not found');
    }

    return result.rows[0].coins_balance;
  }

  async addCoins(
    userId: string,
    amount: number,
    type: string = 'topup',
    description?: string,
    referenceId?: string
  ): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      await client.query(
        `UPDATE users SET coins_balance = coins_balance + $1 WHERE id = $2`,
        [amount, userId]
      );

      await client.query(
        `INSERT INTO wallet_transactions (user_id, type, amount_coins, status, description, reference_id)
         VALUES ($1, $2, $3, 'success', $4, $5)`,
        [userId, type, amount, description || null, referenceId || null]
      );

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async deductCoins(
    userId: string,
    amount: number,
    type: string = 'entry_fee',
    description?: string,
    referenceId?: string
  ): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Check balance with FOR UPDATE lock
      const balanceResult = await client.query(
        `SELECT coins_balance FROM users WHERE id = $1 FOR UPDATE`,
        [userId]
      );

      if (!balanceResult.rows[0]) {
        throw new Error('User not found');
      }

      if (balanceResult.rows[0].coins_balance < amount) {
        throw new Error('Insufficient coins');
      }

      await client.query(
        `UPDATE users SET coins_balance = coins_balance - $1 WHERE id = $2`,
        [amount, userId]
      );

      await client.query(
        `INSERT INTO wallet_transactions (user_id, type, amount_coins, status, description, reference_id)
         VALUES ($1, $2, -$3, 'success', $4, $5)`,
        [userId, type, amount, description || null, referenceId || null]
      );

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getTransactions(
    userId: string,
    limit: number = 50,
    offset: number = 0
  ): Promise<WalletTransaction[]> {
    const result = await this.pool.query(
      `SELECT id, user_id as "userId", type, amount_coins as "amountCoins",
              reference_id as "referenceId", description, status,
              created_at as "createdAt"
       FROM wallet_transactions
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    return result.rows;
  }

  async createPaymentOrder(
    userId: string,
    razorpayOrderId: string,
    amountInr: number
  ): Promise<any> {
    const result = await this.pool.query(
      `INSERT INTO payment_orders (user_id, razorpay_order_id, amount_inr, status)
       VALUES ($1, $2, $3, 'pending')
       RETURNING id, user_id as "userId", razorpay_order_id as "razorpayOrderId",
         amount_inr as "amountInr", status, created_at as "createdAt"`,
      [userId, razorpayOrderId, amountInr]
    );

    return result.rows[0];
  }

  async confirmPayment(razorpayOrderId: string, userId: string, amountInr: number): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Update payment order
      await client.query(
        `UPDATE payment_orders SET status = 'success' WHERE razorpay_order_id = $1`,
        [razorpayOrderId]
      );

      // Find corresponding coin pack and add coins
      const packIndex = this.coinPacks.findIndex(p => p.priceInr === amountInr);
      if (packIndex === -1) {
        throw new Error('Invalid amount');
      }

      const coins = this.coinPacks[packIndex].coins;

      await client.query(
        `UPDATE users SET coins_balance = coins_balance + $1 WHERE id = $2`,
        [coins, userId]
      );

      await client.query(
        `INSERT INTO wallet_transactions (user_id, type, amount_coins, status, reference_id, description)
         VALUES ($1, 'topup', $2, 'success', $3, $4)`,
        [userId, coins, razorpayOrderId, `Coin pack purchase - ₹${amountInr}`]
      );

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  getCoinPacks(): CoinPack[] {
    return this.coinPacks;
  }

  getCoinsForPrice(priceInr: number): number | null {
    const pack = this.coinPacks.find(p => p.priceInr === priceInr);
    return pack ? pack.coins : null;
  }
}

export const createWalletService = (pool: Pool) => new WalletService(pool);
