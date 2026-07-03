import { Pool } from 'pg';
import type { User } from '../types/auth';

export interface FeedPost {
  id: string;
  userId: string;
  user?: { name: string; avatarUrl?: string };
  postType: string;
  refId?: string;
  refType?: string;
  bodyText?: string;
  likesCount: number;
  commentsCount: number;
  isLikedByMe?: boolean;
  createdAt: Date;
}

export interface PostComment {
  id: string;
  postId: string;
  userId: string;
  user?: { name: string; avatarUrl?: string };
  text: string;
  createdAt: Date;
}

class FeedService {
  constructor(private pool: Pool) {}

  async createPost(
    userId: string,
    postType: string,
    bodyText?: string,
    refId?: string,
    refType?: string
  ): Promise<FeedPost> {
    const result = await this.pool.query(
      `INSERT INTO feed_posts (user_id, post_type, body_text, ref_id, ref_type, created_at)
       VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
       RETURNING id, user_id as "userId", post_type as "postType", ref_id as "refId",
         ref_type as "refType", body_text as "bodyText", likes_count as "likesCount",
         comments_count as "commentsCount", created_at as "createdAt"`,
      [userId, postType, bodyText || null, refId || null, refType || null]
    );

    return result.rows[0];
  }

  async getFeedForUser(userId: string, limit: number = 20, offset: number = 0): Promise<FeedPost[]> {
    // Get posts from users the current user follows, plus global feed
    const result = await this.pool.query(
      `SELECT fp.id, fp.user_id as "userId", fp.post_type as "postType",
              fp.ref_id as "refId", fp.ref_type as "refType", fp.body_text as "bodyText",
              fp.likes_count as "likesCount", fp.comments_count as "commentsCount",
              fp.created_at as "createdAt", u.name, u.avatar_url as "avatarUrl",
              CASE WHEN pl.user_id IS NOT NULL THEN true ELSE false END as "isLikedByMe"
       FROM feed_posts fp
       JOIN users u ON fp.user_id = u.id
       LEFT JOIN post_likes pl ON fp.id = pl.post_id AND pl.user_id = $1
       WHERE fp.user_id IN (
         SELECT followee_id FROM user_follows WHERE follower_id = $1
       ) OR fp.user_id = $1
       ORDER BY fp.created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    return result.rows.map(row => ({
      id: row.id,
      userId: row.userId,
      user: { name: row.name, avatarUrl: row.avatarUrl },
      postType: row.postType,
      refId: row.refId,
      refType: row.refType,
      bodyText: row.bodyText,
      likesCount: row.likesCount,
      commentsCount: row.commentsCount,
      isLikedByMe: row.isLikedByMe,
      createdAt: row.createdAt,
    }));
  }

  async getGlobalFeed(limit: number = 20, offset: number = 0): Promise<FeedPost[]> {
    const result = await this.pool.query(
      `SELECT fp.id, fp.user_id as "userId", fp.post_type as "postType",
              fp.ref_id as "refId", fp.ref_type as "refType", fp.body_text as "bodyText",
              fp.likes_count as "likesCount", fp.comments_count as "commentsCount",
              fp.created_at as "createdAt", u.name, u.avatar_url as "avatarUrl"
       FROM feed_posts fp
       JOIN users u ON fp.user_id = u.id
       ORDER BY fp.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    return result.rows.map(row => ({
      id: row.id,
      userId: row.userId,
      user: { name: row.name, avatarUrl: row.avatarUrl },
      postType: row.postType,
      refId: row.refId,
      refType: row.refType,
      bodyText: row.bodyText,
      likesCount: row.likesCount,
      commentsCount: row.commentsCount,
      createdAt: row.createdAt,
    }));
  }

  async likePost(postId: string, userId: string): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Insert like
      await client.query(
        `INSERT INTO post_likes (post_id, user_id) VALUES ($1, $2)
         ON CONFLICT DO NOTHING`,
        [postId, userId]
      );

      // Increment likes count
      await client.query(
        `UPDATE feed_posts SET likes_count = likes_count + 1
         WHERE id = $1 AND NOT EXISTS (
           SELECT 1 FROM post_likes WHERE post_id = $1 AND user_id = $2 AND created_at < CURRENT_TIMESTAMP - INTERVAL '1 second'
         )`,
        [postId, userId]
      );

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async unlikePost(postId: string, userId: string): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Remove like
      await client.query(
        `DELETE FROM post_likes WHERE post_id = $1 AND user_id = $2`,
        [postId, userId]
      );

      // Decrement likes count
      await client.query(
        `UPDATE feed_posts SET likes_count = GREATEST(0, likes_count - 1)
         WHERE id = $1`,
        [postId]
      );

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async addComment(postId: string, userId: string, text: string): Promise<PostComment> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Insert comment
      const commentResult = await client.query(
        `INSERT INTO post_comments (post_id, user_id, text, created_at)
         VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
         RETURNING id, post_id as "postId", user_id as "userId", text, created_at as "createdAt"`,
        [postId, userId, text]
      );

      // Increment comments count
      await client.query(
        `UPDATE feed_posts SET comments_count = comments_count + 1 WHERE id = $1`,
        [postId]
      );

      await client.query('COMMIT');

      return commentResult.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  async getComments(postId: string): Promise<PostComment[]> {
    const result = await this.pool.query(
      `SELECT pc.id, pc.post_id as "postId", pc.user_id as "userId", pc.text,
              pc.created_at as "createdAt", u.name, u.avatar_url as "avatarUrl"
       FROM post_comments pc
       JOIN users u ON pc.user_id = u.id
       WHERE pc.post_id = $1
       ORDER BY pc.created_at ASC`,
      [postId]
    );

    return result.rows.map(row => ({
      id: row.id,
      postId: row.postId,
      userId: row.userId,
      user: { name: row.name, avatarUrl: row.avatarUrl },
      text: row.text,
      createdAt: row.createdAt,
    }));
  }

  async followUser(followerId: string, followeeId: string): Promise<void> {
    if (followerId === followeeId) {
      throw new Error('Cannot follow yourself');
    }

    await this.pool.query(
      `INSERT INTO user_follows (follower_id, followee_id) VALUES ($1, $2)
       ON CONFLICT DO NOTHING`,
      [followerId, followeeId]
    );
  }

  async unfollowUser(followerId: string, followeeId: string): Promise<void> {
    await this.pool.query(
      `DELETE FROM user_follows WHERE follower_id = $1 AND followee_id = $2`,
      [followerId, followeeId]
    );
  }

  async isFollowing(followerId: string, followeeId: string): Promise<boolean> {
    const result = await this.pool.query(
      `SELECT 1 FROM user_follows WHERE follower_id = $1 AND followee_id = $2`,
      [followerId, followeeId]
    );
    return result.rows.length > 0;
  }

  async getFollowers(userId: string): Promise<{ id: string; name: string; avatarUrl?: string }[]> {
    const result = await this.pool.query(
      `SELECT u.id, u.name, u.avatar_url as "avatarUrl"
       FROM users u
       WHERE u.id IN (SELECT follower_id FROM user_follows WHERE followee_id = $1)`,
      [userId]
    );
    return result.rows;
  }

  async getFollowing(userId: string): Promise<{ id: string; name: string; avatarUrl?: string }[]> {
    const result = await this.pool.query(
      `SELECT u.id, u.name, u.avatar_url as "avatarUrl"
       FROM users u
       WHERE u.id IN (SELECT followee_id FROM user_follows WHERE follower_id = $1)`,
      [userId]
    );
    return result.rows;
  }
}

export const createFeedService = (pool: Pool) => new FeedService(pool);
