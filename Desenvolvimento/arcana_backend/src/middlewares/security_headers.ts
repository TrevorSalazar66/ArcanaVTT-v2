import type { Context, Next } from 'hono';
import type { Env, HonoVariables } from '../types/env';

/**
 * Middleware de cabeçalhos de segurança e CORS restritivo para Edge Worker.
 */
export async function securityHeadersMiddleware(
  c: Context<{ Bindings: Env; Variables: HonoVariables }>,
  next: Next,
): Promise<Response | void> {
  const origin = c.req.header('Origin') ?? '';
  const allowedRaw =
    c.env?.ALLOWED_ORIGINS ??
    'https://arcanavtt.app,http://localhost:8080,capacitor://localhost';
  const allowedList = allowedRaw
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

  if (c.req.method === 'OPTIONS') {
    const corsOrigin = allowedList.includes(origin) ? origin : allowedList[0] ?? '*';
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': corsOrigin,
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Device-Fingerprint',
        'Access-Control-Max-Age': '86400',
      },
    });
  }

  await next();

  if (origin && allowedList.includes(origin)) {
    c.header('Access-Control-Allow-Origin', origin);
  }
  c.header('X-Content-Type-Options', 'nosniff');
  c.header('X-Frame-Options', 'DENY');
  c.header('Referrer-Policy', 'strict-origin-when-cross-origin');
  c.header('Strict-Transport-Security', 'max-age=63072000; includeSubDomains');
  c.header('Cache-Control', 'no-store');
}

