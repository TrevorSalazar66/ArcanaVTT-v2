import type { UserRole } from '../types/env';

export interface JwtPayload {
  sub: string;
  email: string;
  role: UserRole;
  jti: string;
  dfp: string;
  iat: number;
  exp: number;
}

function toBase64Url(input: Uint8Array | string): string {
  const bytes =
    typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let binary = '';
  for (let i = 0; i < bytes.length; i += 1) {
    binary += String.fromCharCode(bytes[i] ?? 0);
  }
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function fromBase64Url(input: string): Uint8Array {
  const padded = input.replace(/-/g, '+').replace(/_/g, '/');
  const padLength = (4 - (padded.length % 4)) % 4;
  const binary = atob(padded + '='.repeat(padLength));
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

async function importHmacKey(secret: string): Promise<CryptoKey> {
  const rawKey = new TextEncoder().encode(secret);
  return crypto.subtle.importKey(
    'raw',
    rawKey,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify'],
  );
}

/**
 * Assina um token JWT usando WebCrypto nativo HMAC-SHA256.
 */
export async function signJwt(
  payload: JwtPayload,
  secret: string,
): Promise<string> {
  const header = toBase64Url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const body = toBase64Url(JSON.stringify(payload));
  const data = `${header}.${body}`;
  const key = await importHmacKey(secret);
  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(data),
  );
  return `${data}.${toBase64Url(new Uint8Array(signature))}`;
}

/**
 * Verifica integridade e expiração de um token JWT sem dependências externas.
 */
export async function verifyJwt(
  token: string,
  secret: string,
): Promise<JwtPayload | null> {
  const parts = token.split('.');
  if (parts.length !== 3) {
    return null;
  }
  const [header, body, sig] = parts;
  if (!header || !body || !sig) {
    return null;
  }
  try {
    const key = await importHmacKey(secret);
    const sigBytes = fromBase64Url(sig);
    const dataBytes = new TextEncoder().encode(`${header}.${body}`);
    const valid = await crypto.subtle.verify(
      'HMAC',
      key,
      sigBytes,
      dataBytes,
    );
    if (!valid) {
      return null;
    }
    const decoded = new TextDecoder().decode(fromBase64Url(body));
    const parsed = JSON.parse(decoded) as JwtPayload;
    const nowSeconds = Math.floor(Date.now() / 1000);
    if (!parsed.exp || parsed.exp <= nowSeconds) {
      return null;
    }
    return parsed;
  } catch {
    return null;
  }
}

/**
 * Gera resumo SHA-256 em hexadecimal para hashes de segurança (Device ID / Lockout).
 */
export async function sha256Hex(raw: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(raw),
  );
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

/**
 * Gera identificador único criptograficamente seguro em formato URL-safe.
 */
export function generateId(prefix: string): string {
  const randomBytes = new Uint8Array(8);
  crypto.getRandomValues(randomBytes);
  const hex = Array.from(randomBytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return `${prefix}_${hex}`;
}

/**
 * Calcula idade exata em anos UTC a partir de data ISO YYYY-MM-DD.
 */
export function calculateAgeUtc(
  birthDateIso: string,
  now: Date = new Date(),
): number {
  const parts = birthDateIso.split('-').map((p) => Number.parseInt(p, 10));
  if (parts.length !== 3 || parts.some((n) => Number.isNaN(n))) {
    return -1;
  }
  const [year, month, day] = parts;
  if (!year || !month || !day) {
    return -1;
  }
  let age = now.getUTCFullYear() - year;
  const currentMonth = now.getUTCMonth() + 1;
  const currentDay = now.getUTCDate();
  if (currentMonth < month || (currentMonth === month && currentDay < day)) {
    age -= 1;
  }
  return age;
}

