import type { IArcanaRepository } from '../../data/interfaces';
import { AppError } from '../../middlewares/error_handler';
import type { Env } from '../../types/env';
import { sha256Hex } from '../../utils/crypto_jwt';

/**
 * Gera código numérico seguro de 6 dígitos para desbloqueio via e-mail.
 */
function generateSixDigitCode(): string {
  const arr = new Uint32Array(1);
  crypto.getRandomValues(arr);
  const num = (arr[0] ?? 100000) % 900000 + 100000;
  return String(num);
}

/**
 * Aciona Lockout Total: revoga sessões no D1, bloqueia conta e dispara envio transacional.
 */
export async function triggerAccountLockout(
  userId: string,
  reason: string,
  repo: IArcanaRepository,
  env?: Env,
) {
  const user = await repo.findUserById(userId);
  if (!user) {
    throw new AppError(404, 'USER_NOT_FOUND', 'Conta nao encontrada para Lockout.');
  }

  const recoveryCode = generateSixDigitCode();
  const recoveryHash = await sha256Hex(`${user.email}:${recoveryCode}`);

  await repo.revokeAllUserSessions(user.id);
  await repo.updateUserStatusAndLockout(user.id, 'locked', recoveryHash);

  let emailDispatched = false;
  if (env?.RESEND_API_KEY) {
    try {
      const resp = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: env.EMAIL_FROM ?? 'seguranca@arcanavtt.app',
          to: [user.email],
          subject: 'ArcanaVTT — Lockout Total Ativado & Codigo de Desbloqueio',
          text: `Sua conta entrou em Lockout Total (${reason}). Codigo de recuperacao: ${recoveryCode}.`,
        }),
      });
      emailDispatched = resp.ok;
    } catch {
      emailDispatched = false;
    }
  }

  return {
    ok: true,
    account_status: 'locked' as const,
    sessions_revoked: true,
    email_dispatched: emailDispatched,
    recovery_code_preview: env?.ENVIRONMENT !== 'production' ? recoveryCode : undefined,
    message:
      'Lockout Total ativado. Todas as sessoes foram encerradas e um codigo de desbloqueio foi enviado ao seu e-mail.',
  };
}

/**
 * Valida o código enviado por e-mail e libera a conta em Lockout Total.
 */
export async function verifyAccountLockoutUnlock(
  email: string,
  recoveryCode: string,
  deviceFingerprint: string,
  repo: IArcanaRepository,
) {
  const user = await repo.findUserByGoogleSubOrEmail('', email.toLowerCase());
  if (!user) {
    throw new AppError(404, 'USER_NOT_FOUND', 'Conta nao encontrada.');
  }

  const device = await repo.findDeviceSecurity(deviceFingerprint);
  if (device && device.is_hardware_banned === 1) {
    throw new AppError(
      403,
      'HARDWARE_BANNED',
      'Desbloqueio bloqueado: este aparelho esta sob Hardware Ban.',
    );
  }

  const expectedHash = await sha256Hex(`${user.email}:${recoveryCode}`);
  if (!user.lockout_token_hash || user.lockout_token_hash !== expectedHash) {
    throw new AppError(403, 'INVALID_LOCKOUT_CODE', 'Codigo de verificacao invalido.');
  }

  await repo.updateUserStatusAndLockout(user.id, 'active', null);
  return {
    ok: true,
    account_status: 'active' as const,
    message: 'Identidade confirmada. Realize novo login com sua conta Google.',
  };
}

