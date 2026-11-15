import type { Context, Next } from 'hono';
import type { Env, HonoVariables } from '../types/env';

interface Bucket {
  count: number;
  resetAt: number;
}

const buckets = new Map<string, Bucket>();

/**
 * Limita taxa de requisições por IP + Device Fingerprint contra flood e força bruta.
 */
export function createRateLimiter(maxRequests = 90, windowMs = 60_000) {
  return async (
    c: Context<{ Bindings: Env; Variables: HonoVariables }>,
    next: Next,
  ): Promise<Response | void> => {
    const ip = c.req.header('CF-Connecting-IP') ?? c.req.header('x-forwarded-for') ?? 'local';
    const fp = c.req.header('X-Device-Fingerprint') ?? 'no-fp';
    const key = `${ip}:${fp}`;
    const now = Date.now();

    const current = buckets.get(key);
    if (!current || current.resetAt <= now) {
      buckets.set(key, { count: 1, resetAt: now + windowMs });
      await next();
      return;
    }

    if (current.count >= maxRequests) {
      return c.json(
        {
          ok: false,
          error: 'RATE_LIMITED',
          message: 'Muitas requisicoes em curto periodo. Aguarde alguns segundos.',
        },
        429,
      );
    }

    current.count += 1;
    await next();
  };
}

export function resetRateLimiterForTests(): void {
  buckets.clear();
}

