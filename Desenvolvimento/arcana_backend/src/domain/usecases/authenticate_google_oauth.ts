import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import { AppError } from '../../middlewares/error_handler';
import { resolveJwtSecret } from '../../middlewares/auth_middleware';
import type { authOAuthGoogleSchema } from '../../schemas/auth_schemas';
import type { Env, UserRole } from '../../types/env';
import { calculateAgeUtc, generateId, sha256Hex, signJwt } from '../../utils/crypto_jwt';

type OAuthInput = z.infer<typeof authOAuthGoogleSchema>;

/**
 * Autenticação 100% Google OAuth 2.0 com validação de `id_token`, barreira etária LGPD (>= 16 anos),
 * proteção Hardware Ban e sessão de Dispositivo Confiável (15–30 dias).
 */
export async function authenticateGoogleOAuth(
  input: OAuthInput,
  repo: IArcanaRepository,
  env?: Env,
  clientIp = '0.0.0.0',
) {
  let verifiedSub = input.google_sub;
  let verifiedEmail = input.email.toLowerCase();
  let verifiedDisplayName = input.display_name;

  if (
    env?.GOOGLE_CLIENT_ID &&
    env.GOOGLE_CLIENT_ID.trim().length > 0 &&
    env?.ENVIRONMENT === 'production' &&
    !input.id_token
  ) {
    throw new AppError(
      401,
      'MISSING_GOOGLE_TOKEN',
      'Token id_token do Google OAuth obrigatorio.',
    );
  }

  if (input.id_token) {
    const tokenRes = await fetch(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(input.id_token)}`,
    );
    if (!tokenRes.ok) {
      throw new AppError(
        401,
        'INVALID_GOOGLE_TOKEN',
        'Token Google OAuth 2.0 invalido ou expirado.',
      );
    }
    const tokenInfo = (await tokenRes.json()) as {
      sub?: string;
      email?: string;
      aud?: string;
      name?: string;
    };
    const allowedClientIds = (env?.GOOGLE_CLIENT_ID ?? '')
      .split(',')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);
    if (
      allowedClientIds.length > 0 &&
      (!tokenInfo.aud || !allowedClientIds.includes(tokenInfo.aud))
    ) {
      throw new AppError(
        401,
        'INVALID_GOOGLE_TOKEN',
        'Client ID (aud) do token Google OAuth nao corresponde ao aplicativo.',
      );
    }
    if (tokenInfo.sub) verifiedSub = tokenInfo.sub;
    if (tokenInfo.email) verifiedEmail = tokenInfo.email.toLowerCase();
    if (tokenInfo.name && tokenInfo.name.trim().length >= 2) {
      verifiedDisplayName = tokenInfo.name.trim();
    }
  }

  const minAge = Number.parseInt(env?.MIN_AGE_YEARS ?? '16', 10) || 16;
  const age = calculateAgeUtc(input.birth_date);
  if (age < 0) {
    throw new AppError(400, 'INVALID_BIRTH_DATE', 'Data de nascimento invalida.');
  }
  if (age < minAge) {
    throw new AppError(
      403,
      'AGE_RESTRICTED',
      `Acesso bloqueado: e obrigatorio ter no minimo ${minAge} anos conforme diretrizes LGPD.`,
    );
  }

  const existingDevice = await repo.findDeviceSecurity(input.device_fingerprint);
  if (existingDevice && existingDevice.is_hardware_banned === 1) {
    throw new AppError(
      403,
      'HARDWARE_BANNED',
      existingDevice.ban_reason ??
        'Este aparelho Android foi bloqueado permanentemente por Hardware Ban.',
    );
  }

  const nowIso = new Date().toISOString();
  let user = await repo.findUserByGoogleSubOrEmail(verifiedSub, verifiedEmail);
  let profile = user ? await repo.findProfileByUserId(user.id) : null;

  if (user && user.account_status === 'locked') {
    throw new AppError(
      423,
      'ACCOUNT_LOCKED',
      'Conta em Lockout Total preventivo. Conclua a verificacao por codigo no seu e-mail Google.',
    );
  }
  if (user && user.account_status === 'banned') {
    throw new AppError(
      403,
      'ACCOUNT_BANNED',
      'Esta conta foi suspensa pelas Diretrizes de Convivencia.',
    );
  }

  if (!user) {
    const userId = generateId('usr');
    const sanitizedBase = verifiedEmail
      .split('@')[0]
      ?.toLowerCase()
      .replace(/[^a-z0-9_]/g, '_')
      .slice(0, 14) || 'heroi';
    const username = `${sanitizedBase}_${userId.slice(-4)}`;

    const realUsersCount = await repo.countRealUsers();
    let initialRole: UserRole;
    if (realUsersCount === 0 && !(env?.ENVIRONMENT === 'test' && input.requested_role)) {
      initialRole = 'superadmin';
    } else if (
      input.requested_role === 'jogador' ||
      input.requested_role === 'assistente_mestre' ||
      input.requested_role === 'mestre'
    ) {
      initialRole = input.requested_role;
    } else if (input.requested_role && env?.ENVIRONMENT !== 'production') {
      initialRole = input.requested_role;
    } else if (input.requested_role) {
      initialRole = 'jogador';
    } else {
      initialRole = 'mestre';
    }

    user = {
      id: userId,
      google_sub: verifiedSub,
      email: verifiedEmail,
      birth_date: input.birth_date,
      role: initialRole,
      account_status: 'active',
      lockout_token_hash: null,
      created_at: nowIso,
      updated_at: nowIso,
    };

    profile = {
      user_id: userId,
      username,
      display_name: verifiedDisplayName,
      bio: 'Aventureiro recem-chegado a Taverna ArcanaVTT.',
      avatar_icon: 'crown',
      preferred_role: initialRole,
      reputation_points: 100,
      theme_preference: 'escuro_heraldico',
      font_scale: 1.0,
      onboarding_completed: 0,
      updated_at: nowIso,
    };

    await repo.createUserWithProfile(user, profile);
  }

  const ttlDays = input.trust_device
    ? Number.parseInt(env?.SESSION_TTL_DAYS ?? '30', 10) || 30
    : 1;
  const expiresAtDate = new Date(Date.now() + ttlDays * 24 * 60 * 60 * 1000);
  const jti = generateId('jti');

  const androidIdHash =
    input.android_id_hash ?? (await sha256Hex(input.device_fingerprint));

  await repo.upsertDeviceSecurity({
    device_fingerprint: input.device_fingerprint,
    user_id: user.id,
    android_id_hash: androidIdHash,
    is_trusted: input.trust_device ? 1 : 0,
    is_hardware_banned: 0,
    ban_reason: null,
    trusted_until: input.trust_device ? expiresAtDate.toISOString() : null,
    last_ip: clientIp,
    updated_at: nowIso,
  });

  await repo.createSession({
    id: generateId('ses'),
    user_id: user.id,
    device_fingerprint: input.device_fingerprint,
    token_jti: jti,
    expires_at: expiresAtDate.toISOString(),
    revoked: 0,
    created_at: nowIso,
  });

  const nowSeconds = Math.floor(Date.now() / 1000);
  const token = await signJwt(
    {
      sub: user.id,
      email: user.email,
      role: user.role,
      jti,
      dfp: input.device_fingerprint,
      iat: nowSeconds,
      exp: Math.floor(expiresAtDate.getTime() / 1000),
    },
    resolveJwtSecret(env),
  );

  return {
    ok: true,
    auth_provider: 'google_oauth_2',
    token,
    expires_at: expiresAtDate.toISOString(),
    trusted_device_days: input.trust_device ? ttlDays : 0,
    user: {
      id: user.id,
      email: user.email,
      role: user.role,
      account_status: user.account_status,
    },
    profile,
  };
}

