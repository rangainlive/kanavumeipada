import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { Pool } from 'pg';
import { createFeedService } from '../services/feed.service';
import { z } from 'zod';

const createPostSchema = z.object({
  postType: z.enum(['discussion', 'test_published', 'challenge_created', 'result_shared', 'achievement_unlocked']),
  title: z.string().max(200).optional(),
  bodyText: z.string().max(500).optional(),
  refId: z.string().uuid().optional(),
  refType: z.enum(['test', 'challenge', 'achievement']).optional(),
});

const commentSchema = z.object({
  text: z.string().min(1).max(280),
});

export async function feedRoutes(fastify: FastifyInstance, pool: Pool) {
  const feedService = createFeedService(pool);

  // Get feed for current user (following + own posts)
  fastify.get(
    '/api/feed',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const limit = Math.min(parseInt(request.query.limit || '20'), 100);
        const offset = parseInt(request.query.offset || '0');
        const userId = request.user.userId;

        const posts = await feedService.getFeedForUser(userId, limit, offset);

        return reply.code(200).send({
          posts,
          count: posts.length,
          hasMore: posts.length === limit,
        });
      } catch (error: any) {
        return reply.code(500).send({
          error: 'Failed to fetch feed',
          message: error.message,
        });
      }
    }
  );

  // Get global feed (all posts)
  fastify.get('/api/feed/global', async (request, reply) => {
    try {
      const query = request.query as any;
      const limit = Math.min(parseInt(query.limit || '20'), 100);
      const offset = parseInt(query.offset || '0');

      const posts = await feedService.getGlobalFeed(limit, offset);

      return reply.code(200).send({
        posts,
        count: posts.length,
        hasMore: posts.length === limit,
      });
    } catch (error: any) {
      return reply.code(500).send({
        error: 'Failed to fetch global feed',
        message: error.message,
      });
    }
  });

  // Create post
  fastify.post(
    '/api/feed/posts',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const data = createPostSchema.parse(request.body);
        const userId = request.user.userId;

        const post = await feedService.createPost(userId, data.postType, data.bodyText, data.refId, data.refType);

        return reply.code(201).send({
          message: 'Post created',
          post,
        });
      } catch (error: any) {
        return reply.code(400).send({
          error: 'Failed to create post',
          message: error.message,
        });
      }
    }
  );

  // Like post
  fastify.post(
    '/api/feed/posts/:postId/like',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { postId } = request.params;
        const userId = request.user.userId;

        await feedService.likePost(postId, userId);

        return reply.code(200).send({ message: 'Post liked' });
      } catch (error: any) {
        if (error.message?.includes('duplicate') || error.code === '23505') {
          return reply.code(200).send({ message: 'Post liked' });
        }
        return reply.code(500).send({
          error: 'Failed to like post',
          message: error.message,
        });
      }
    }
  );

  // Unlike post
  fastify.post(
    '/api/feed/posts/:postId/unlike',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { postId } = request.params;
        const userId = request.user.userId;

        await feedService.unlikePost(postId, userId);

        return reply.code(200).send({ message: 'Post unliked' });
      } catch (error: any) {
        return reply.code(500).send({
          error: 'Failed to unlike post',
          message: error.message,
        });
      }
    }
  );

  // Add comment
  fastify.post(
    '/api/feed/posts/:postId/comments',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { postId } = request.params;
        const { text } = commentSchema.parse(request.body);
        const userId = request.user.userId;

        const comment = await feedService.addComment(postId, userId, text);

        return reply.code(201).send({
          message: 'Comment added',
          comment,
        });
      } catch (error: any) {
        return reply.code(400).send({
          error: 'Failed to add comment',
          message: error.message,
        });
      }
    }
  );

  // Get comments
  fastify.get('/api/feed/posts/:postId/comments', async (request: any, reply) => {
    try {
      const { postId } = request.params;

      const comments = await feedService.getComments(postId);

      return reply.code(200).send({
        comments,
        count: comments.length,
      });
    } catch (error: any) {
      return reply.code(500).send({
        error: 'Failed to fetch comments',
        message: error.message,
      });
    }
  });

  // Follow user
  fastify.post(
    '/api/feed/users/:userId/follow',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { userId } = request.params;
        const followerId = request.user.userId;

        await feedService.followUser(followerId, userId);

        return reply.code(200).send({ message: 'User followed' });
      } catch (error: any) {
        return reply.code(400).send({
          error: 'Failed to follow user',
          message: error.message,
        });
      }
    }
  );

  // Unfollow user
  fastify.post(
    '/api/feed/users/:userId/unfollow',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { userId } = request.params;
        const followerId = request.user.userId;

        await feedService.unfollowUser(followerId, userId);

        return reply.code(200).send({ message: 'User unfollowed' });
      } catch (error: any) {
        return reply.code(500).send({
          error: 'Failed to unfollow user',
          message: error.message,
        });
      }
    }
  );

  // Get followers
  fastify.get(
    '/api/feed/users/:userId/followers',
    async (request: any, reply) => {
      try {
        const { userId } = request.params;

        const followers = await feedService.getFollowers(userId);

        return reply.code(200).send({
          followers,
          count: followers.length,
        });
      } catch (error: any) {
        return reply.code(500).send({
          error: 'Failed to fetch followers',
          message: error.message,
        });
      }
    }
  );

  // Get following
  fastify.get(
    '/api/feed/users/:userId/following',
    async (request: any, reply) => {
      try {
        const { userId } = request.params;

        const following = await feedService.getFollowing(userId);

        return reply.code(200).send({
          following,
          count: following.length,
        });
      } catch (error: any) {
        return reply.code(500).send({
          error: 'Failed to fetch following',
          message: error.message,
        });
      }
    }
  );

  // Check if following
  fastify.get(
    '/api/feed/users/:userId/is-following',
    { onRequest: [fastify.authenticate] },
    async (request: any, reply) => {
      try {
        const { userId } = request.params;
        const followerId = request.user.userId;

        const isFollowing = await feedService.isFollowing(followerId, userId);

        return reply.code(200).send({ isFollowing });
      } catch (error: any) {
        return reply.code(500).send({
          error: 'Failed to check follow status',
          message: error.message,
        });
      }
    }
  );
}
