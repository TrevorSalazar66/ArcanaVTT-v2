import type { Context, Next } from 'hono';
import type { IArcanaRepository } from '../data/interfaces';
import type { Env, HonoVariables, UserRole } from '../types/env';
import { verifyJwt } from '../utils/crypto_jwt';
import { AppError } from './error_handler';

export function resolveJwtSecret(env?: Env): string {
  return env?.JWT_SECRET ?? 'arcana-vtt-dev-fallback-secret-alterar-em-producao';
}

/**
 * Middleware Zero-Trust: valida JWT, revogação de sessão, bloqueio/ban e hardware ban.
 */
export function createAuthMiddleware(getRepo: (env?: Env) => IArcanaRepository) {
  return async (
    c: Context<{ Bindings: Env; Variables: HonoVariables }>,
    next: Next,
  ): Promise<Response | void> => {
    const authHeader = c.req.header('Authorization') ?? '';
    if (!authHeader.startsWith('Bearer ')) {
      throw new AppError(401, 'UNAUTHORIZED', 'Token Bearer ausente ou malformado.');
    }

    const token = authHeader.slice(7).trim();
    const payload = await verifyJwt(token, resolveJwtSecret(c.env));
    if (!payload) {
      throw new AppError(401, 'INVALID_TOKEN', 'Sessao expirada ou assinatura invalida.');
    }

    const repo = getRepo(c.env);
    const session = await repo.findSessionByJti(payload.jti);
    if (!session || session.revoked === 1) {
      throw new AppError(401, 'SESSION_REVOKED', 'Sessao revogada. Autentique-se novamente via Google OAuth.');
    }

    const user = await repo.findUserById(payload.sub);
    if (!user || user.account_status !== 'active') {
      throw new AppError(
        423,
        'ACCOUNT_LOCKED',
        'Conta bloqueada ou em Lockout Total. Verifique seu e-mail para desbloqueio.',
      );
    }

    const device = await repo.findDeviceSecurity(payload.dfp);
    if (device && device.is_hardware_banned === 1) {
      throw new AppError(
        403,
        'HARDWARE_BANNED',
        'Acesso negado: dispositivo bloqueado por hardware ban.',
      );
    }

    c.set('authUser', {
      userId: user.id,
      email: user.email,
      role: user.role,
      jti: payload.jti,
      deviceFingerprint: payload.dfp,
    });

    await next();
  };
}

/**
 * Valida se o papel do usuário atende aos níveis exigidos na matriz Zero-Trust RBAC.
 */
export function assertRole(userRole: UserRole, allowedRoles: UserRole[]): void {
  if (!allowedRoles.includes(userRole)) {
    throw new AppError(
      403,
      'FORBIDDEN_RBAC',
      'Permissao insuficiente para executar esta operacao.',
    );
  }
}

