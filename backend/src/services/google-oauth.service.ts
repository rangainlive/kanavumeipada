import axios from 'axios';
import { Pool } from 'pg';
import { jwtService } from './jwt.service';

const WEB_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || '';
const ANDROID_CLIENT_ID = '379413625356-d2elf1uui20i2eglsvcl3aqhl923pl8c.apps.googleusercontent.com';

interface TokenInfoPayload {
  iss: string;
  aud: string;
  sub: string;
  email: string;
  email_verified: string;
  name: string;
  picture: string;
  given_name: string;
  family_name: string;
  iat: string;
  exp: string;
}

export class GoogleOAuthService {
  constructor(private pool: Pool) {}

  async verifyToken(idToken: string): Promise<TokenInfoPayload> {
    // Use Google's tokeninfo endpoint — no local cert fetching, always reliable
    let response;
    try {
      response = await axios.get<TokenInfoPayload>(
        `https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`,
        { timeout: 10000 }
      );
    } catch (err: any) {
      const detail = err.response?.data?.error_description || err.message;
      throw new Error(`Google rejected the token: ${detail}`);
    }

    const payload = response.data;
    const validAudiences = [WEB_CLIENT_ID, ANDROID_CLIENT_ID].filter(Boolean);

    if (!validAudiences.includes(payload.aud)) {
      throw new Error(`Audience mismatch — token aud="${payload.aud}", expected one of: ${validAudiences.join(', ')}`);
    }

    if (payload.email_verified !== 'true') {
      throw new Error('Google email not verified');
    }

    return payload;
  }

  async handleGoogleAuth(googleToken: string) {
    const payload = await this.verifyToken(googleToken);

    let result = await this.pool.query('SELECT * FROM users WHERE email = $1', [payload.email]);
    let user = result.rows[0];

    if (!user) {
      result = await this.pool.query(
        `INSERT INTO users (email, name, avatar_url, coins_balance, xp, is_active, google_id)
         VALUES ($1, $2, $3, 100, 0, true, $4)
         RETURNING *`,
        [payload.email, payload.name, payload.picture, payload.sub]
      );
      user = result.rows[0];
      await this.initializeStreak(user.id);
    } else if (!user.google_id || !user.avatar_url) {
      result = await this.pool.query(
        `UPDATE users SET google_id = $1, avatar_url = COALESCE(avatar_url, $2)
         WHERE id = $3 RETURNING *`,
        [payload.sub, payload.picture, user.id]
      );
      user = result.rows[0];
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
        isProfileComplete: !!user.name && !!user.exam_target,
      },
    };
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
