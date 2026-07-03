import type { FastifyInstance } from 'fastify';
import { Pool } from 'pg';
import { createWalletService } from '../services/wallet.service';
import { z } from 'zod';

const razorpayWebhookSchema = z.object({
  payment: z.object({
    entity: z.string(),
    id: z.string(),
    entity_id: z.string(),
    entity_type: z.string(),
    amount: z.number(),
    currency: z.string(),
    status: z.string(),
    method: z.string(),
    description: z.string(),
    amount_refunded: z.number(),
    refund_status: z.string().nullable(),
    captured: z.boolean(),
    description: z.string().nullable(),
    card_id: z.string().nullable(),
    bank: z.string().nullable(),
    wallet: z.string().nullable(),
    vpa: z.string().nullable(),
    email: z.string().nullable(),
    contact: z.string().nullable(),
    notes: z.object({}).passthrough(),
    fee: z.number().nullable(),
    tax: z.number().nullable(),
    error_code: z.string().nullable(),
    error_description: z.string().nullable(),
    error_source: z.string().nullable(),
    error_reason: z.string().nullable(),
    error_step: z.string().nullable(),
    error_field: z.string().nullable(),
    acquirer_data: z.object({}).passthrough(),
    created_at: z.number(),
  }),
  order: z.object({
    id: z.string(),
  }),
});

export async function walletRoutes(fastify: FastifyInstance, pool: Pool) {
  const walletService = createWalletService(pool);

  // Get balance
  fastify.get(
    '/api/wallet/balance',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const userId = request.user.userId;
        const balance = await walletService.getBalance(userId);

        return reply.code(200).send({ balance });
      } catch (error: any) {
        return reply.code(500).send({
          error: 'Failed to fetch balance',
          message: error.message,
        });
      }
    }
  );

  // Get coin packs
  fastify.get('/api/wallet/packs', async (request, reply) => {
    try {
      const packs = walletService.getCoinPacks();
      return reply.code(200).send({ packs });
    } catch (error: any) {
      return reply.code(500).send({
        error: 'Failed to fetch coin packs',
        message: error.message,
      });
    }
  });

  // Create payment order
  fastify.post(
    '/api/wallet/purchase',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { amountInr } = request.body;
        const userId = request.user.userId;

        // Validate amount
        const coins = walletService.getCoinsForPrice(amountInr);
        if (!coins) {
          return reply.code(400).send({ error: 'Invalid coin pack amount' });
        }

        // Create Razorpay order ID (in production, call Razorpay API)
        const razorpayOrderId = `order_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        const order = await walletService.createPaymentOrder(userId, razorpayOrderId, amountInr);

        return reply.code(201).send({
          order,
          razorpayKey: process.env.RAZORPAY_KEY_ID,
        });
      } catch (error: any) {
        return reply.code(400).send({
          error: 'Failed to create payment order',
          message: error.message,
        });
      }
    }
  );

  // Razorpay webhook
  fastify.post('/api/wallet/webhook/razorpay', async (request: any, reply) => {
    try {
      // In production, verify signature
      // const isValidSignature = verifyRazorpaySignature(request.body);

      const { payment } = request.body;

      if (payment.status === 'captured') {
        // Extract user ID from notes or API call to get user from payment
        // For now, this is a placeholder
        console.log('Payment captured:', payment.id);
      }

      return reply.code(200).send({ status: 'ok' });
    } catch (error: any) {
      console.error('Webhook error:', error);
      return reply.code(500).send({ error: error.message });
    }
  });

  // Confirm payment manually (for development)
  fastify.post(
    '/api/wallet/confirm-payment',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        if (process.env.NODE_ENV !== 'development') {
          return reply.code(403).send({ error: 'Not allowed in production' });
        }

        const { razorpayOrderId, amountInr } = request.body;
        const userId = request.user.userId;

        await walletService.confirmPayment(razorpayOrderId, userId, amountInr);

        return reply.code(200).send({ message: 'Payment confirmed' });
      } catch (error: any) {
        return reply.code(400).send({
          error: 'Failed to confirm payment',
          message: error.message,
        });
      }
    }
  );

  // Get transactions
  fastify.get(
    '/api/wallet/transactions',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const userId = request.user.userId;
        const limit = Math.min(parseInt(request.query.limit || '50'), 100);
        const offset = parseInt(request.query.offset || '0');

        const transactions = await walletService.getTransactions(userId, limit, offset);

        return reply.code(200).send({
          transactions,
          count: transactions.length,
        });
      } catch (error: any) {
        return reply.code(500).send({
          error: 'Failed to fetch transactions',
          message: error.message,
        });
      }
    }
  );
}
