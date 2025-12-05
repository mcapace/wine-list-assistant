import jwt from 'jsonwebtoken';
import type { VercelRequest } from '@vercel/node';
import type { JWTPayload, User } from '../types';
import { supabaseAdmin } from './supabase';

const JWT_SECRET = process.env.JWT_SECRET!;
const ACCESS_TOKEN_EXPIRY = '24h';
const REFRESH_TOKEN_EXPIRY = '30d';

export function generateTokens(user: User): { accessToken: string; refreshToken: string; expiresIn: number } {
  const payload: Omit<JWTPayload, 'iat' | 'exp'> = {
    sub: user.id,
    email: user.email,
    tier: user.subscription_tier,
  };

  const accessToken = jwt.sign(payload, JWT_SECRET, { expiresIn: ACCESS_TOKEN_EXPIRY });
  const refreshToken = jwt.sign({ sub: user.id, type: 'refresh' }, JWT_SECRET, { expiresIn: REFRESH_TOKEN_EXPIRY });

  return {
    accessToken,
    refreshToken,
    expiresIn: 86400, // 24 hours in seconds
  };
}

export function verifyToken(token: string): JWTPayload | null {
  try {
    return jwt.verify(token, JWT_SECRET) as JWTPayload;
  } catch {
    return null;
  }
}

export function extractToken(req: VercelRequest): string | null {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return null;
  }
  return authHeader.slice(7);
}

export async function authenticateRequest(req: VercelRequest): Promise<{ user: User; payload: JWTPayload } | null> {
  const token = extractToken(req);
  if (!token) {
    return null;
  }

  const payload = verifyToken(token);
  if (!payload) {
    return null;
  }

  // Fetch current user data
  const { data: user, error } = await supabaseAdmin
    .from('users')
    .select('*')
    .eq('id', payload.sub)
    .single();

  if (error || !user) {
    return null;
  }

  return { user: user as User, payload };
}

export function requireAuth(handler: (req: VercelRequest, user: User) => Promise<Response>) {
  return async (req: VercelRequest): Promise<Response> => {
    const auth = await authenticateRequest(req);
    if (!auth) {
      return new Response(
        JSON.stringify({
          success: false,
          error: { code: 'UNAUTHORIZED', message: 'Authentication required' },
        }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }
    return handler(req, auth.user);
  };
}

export function requireSubscription(tier: 'premium' | 'business') {
  return (handler: (req: VercelRequest, user: User) => Promise<Response>) => {
    return async (req: VercelRequest): Promise<Response> => {
      const auth = await authenticateRequest(req);
      if (!auth) {
        return new Response(
          JSON.stringify({
            success: false,
            error: { code: 'UNAUTHORIZED', message: 'Authentication required' },
          }),
          { status: 401, headers: { 'Content-Type': 'application/json' } }
        );
      }

      const { user } = auth;
      const tierLevel = { free: 0, premium: 1, business: 2 };
      const requiredLevel = tierLevel[tier];
      const userLevel = tierLevel[user.subscription_tier];

      if (userLevel < requiredLevel || user.subscription_status !== 'active') {
        return new Response(
          JSON.stringify({
            success: false,
            error: { code: 'SUBSCRIPTION_REQUIRED', message: `${tier} subscription required` },
          }),
          { status: 402, headers: { 'Content-Type': 'application/json' } }
        );
      }

      return handler(req, user);
    };
  };
}
