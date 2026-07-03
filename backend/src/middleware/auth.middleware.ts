import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { jwtService } from '../services/jwt.service';

declare global {
  namespace Express {
    interface Request {
      user?: {
        userId: string;
        phone: string;
      };
    }
  }
}

declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (request: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
}

export async function registerAuthMiddleware(fastify: FastifyInstance) {
  fastify.decorate('authenticate', async function (request: FastifyRequest, reply: FastifyReply) {
    try {
      const authHeader = request.headers.authorization;

      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return reply.code(401).send({
          error: 'Missing or invalid authorization header',
        });
      }

      const token = authHeader.substring(7);
      const decoded = jwtService.verifyToken(token);

      // Attach user to request
      (request as any).user = {
        userId: decoded.userId,
        phone: decoded.phone,
      };
    } catch (error: any) {
      return reply.code(401).send({
        error: 'Unauthorized',
        message: error.message,
      });
    }
  });
}
