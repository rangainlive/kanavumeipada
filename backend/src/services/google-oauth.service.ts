import { OAuth2Client } from 'google-auth-library';
import { Pool } from 'pg';
import { jwtService } from './jwt.service';

const googleClient = new OAuth2Client(
  process.env.GOOGLE_CLIENT_ID,
  process.env.GOOGLE_CLIENT_SECRET,
  process.env.GOOGLE_CALLBACK_URL || 'http://localhost:3000/api/auth/google/callback'
);

interface GoogleTokenPayload {
  iss: string;
  azp: string;
  aud: string;
  sub: string;
  email: string;
  email_verified: boolean;
  at_hash: string;
  name: string;
  picture: string;
  given_name: string;
  family_name: string;
  iat: number;
  exp: number;
}

export class GoogleOAuthService {
  constructor(private pool: Pool) {}

  getAuthorizationUrl(state?: string) {
    return googleClient.generateAuthUrl({
      access_type: 'offline',
      scope: ['https://www.googleapis.com/auth/userinfo.email', 'https://www.googleapis.com/auth/userinfo.profile'],
      state: state || '',
    });
  }

  async verifyToken(token: string): Promise<GoogleTokenPayload> {
    try {
      // Try with web client ID first, then Android
      const clientIds = [
        process.env.GOOGLE_CLIENT_ID,
        '379413625356-d2elf1uui20i2eglsvcl3aqhl923pl8c.apps.googleusercontent.com', // Android
      ].filter(Boolean);

      let ticket;
      let lastError: any;

      for (const clientId of clientIds) {
        try {
          ticket = await googleClient.verifyIdToken({
            idToken: token,
            audience: clientId,
          });
          break;
        } catch (error) {
          lastError = error;
        }
      }

      if (!ticket) {
        throw lastError || new Error('Invalid Google token');
      }

      const payload = ticket.getPayload() as GoogleTokenPayload;
      return payload;
    } catch (error) {
      console.error('Token verification failed:', error);
      throw new Error('Invalid Google token');
    }
  }

  async handleGoogleAuth(googleToken: string) {
    try {
      const payload = await this.verifyToken(googleToken);

      // Check if user exists
      let result = await this.pool.query('SELECT * FROM users WHERE email = $1', [payload.email]);

      let user = result.rows[0];

      // Create user if doesn't exist
      if (!user) {
        result = await this.pool.query(
          `INSERT INTO users (email, name, avatar_url, coins_balance, xp, is_active, google_id)
           VALUES ($1, $2, $3, 100, 0, true, $4)
           RETURNING *`,
          [payload.email, payload.name, payload.picture, payload.sub]
        );
        user = result.rows[0];
        await this.initializeStreak(user.id);
      } else {
        // Update google_id and avatar if missing
        if (!user.google_id || !user.avatar_url) {
          result = await this.pool.query(
            `UPDATE users SET google_id = $1, avatar_url = COALESCE(avatar_url, $2)
             WHERE id = $3 RETURNING *`,
            [payload.sub, payload.picture, user.id]
          );
          user = result.rows[0];
        }
      }

      const { token, expiresIn } = jwtService.generateToken(user.id, user.email);
      const refreshToken = jwtService.generateRefreshToken(user.id);

      return {
        token,
        refreshToken,
        expiresIn,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          avatarUrl: user.avatar_url,
          coinsBalance: user.coins_balance,
          examTarget: user.exam_target,
          state: user.state,
          isProfileComplete: !!user.exam_target && !!user.state,
        },
      };
    } catch (error: any) {
      throw new Error(`Google auth failed: ${error.message}`);
    }
  }

  private async initializeStreak(userId: string): Promise<void> {
    await this.pool.query(
      `INSERT INTO user_streaks (user_id, current_streak, longest_streak, last_activity_date)
       VALUES ($1, 0, 0, CURRENT_DATE)
       ON CONFLICT (user_id) DO NOTHING`,
      [userId]
    );
  }
}

export const createGoogleOAuthService = (pool: Pool) => new GoogleOAuthService(pool);
