import jwt from 'jsonwebtoken';
import type { JWTPayload } from '../types/auth';

class JWTService {
  private secret = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
  private expiresIn = process.env.JWT_EXPIRY || '7d';
  private refreshExpiresIn = '30d';

  generateToken(userId: string, phone: string): { token: string; expiresIn: string } {
    const payload = { userId, phone };

    const token = jwt.sign(payload, this.secret, {
      expiresIn: this.expiresIn,
      algorithm: 'HS256',
    });

    return { token, expiresIn: this.expiresIn };
  }

  generateRefreshToken(userId: string): string {
    const payload = { userId, type: 'refresh' };
    return jwt.sign(payload, this.secret + '_refresh', {
      expiresIn: this.refreshExpiresIn,
    });
  }

  verifyToken(token: string): JWTPayload {
    try {
      const decoded = jwt.verify(token, this.secret) as JWTPayload;
      return decoded;
    } catch (error: any) {
      if (error.name === 'TokenExpiredError') {
        throw new Error('Token expired');
      }
      throw new Error('Invalid token');
    }
  }

  verifyRefreshToken(token: string): { userId: string; type: string } {
    try {
      return jwt.verify(token, this.secret + '_refresh') as {
        userId: string;
        type: string;
      };
    } catch (error) {
      throw new Error('Invalid refresh token');
    }
  }

  decodeToken(token: string): any {
    return jwt.decode(token);
  }
}

export const jwtService = new JWTService();
