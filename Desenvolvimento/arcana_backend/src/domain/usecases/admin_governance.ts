import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import { assertRole } from '../../middlewares/auth_middleware';
import type { adminModerateSchema } from '../../schemas/sync_schemas';
import type { AuthenticatedUser } from '../../types/env';

/**
 * Painel de Governança Admin (Zero-Trust: exclusivo para `admin` e `superadmin`).
 */
export async function getAdminOverviewUseCase(
  authUser: AuthenticatedUser,
  repo: IArcanaRepository,
) {
  assertRole(authUser.role, ['admin', 'superadmin']);
  const [reports, metrics] = await Promise.all([
    repo.listReports(),
    repo.listMetricsSummary(),
  ]);
  return {
    ok: true,
    metrics,
    reports,
  };
}

export async function moderateReportUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof adminModerateSchema>,
  repo: IArcanaRepository,
) {
  assertRole(authUser.role, ['admin', 'superadmin']);

  if (input.decision === 'hardware_ban' && input.ban_device_fingerprint) {
    const existing = await repo.findDeviceSecurity(input.ban_device_fingerprint);
    await repo.upsertDeviceSecurity({
      device_fingerprint: input.ban_device_fingerprint,
      user_id: existing?.user_id ?? null,
      android_id_hash: existing?.android_id_hash ?? 'manual_ban',
      is_trusted: 0,
      is_hardware_banned: 1,
      ban_reason: input.ban_reason ?? 'Violacao severa das Diretrizes ArcanaVTT',
      trusted_until: null,
      last_ip: existing?.last_ip ?? null,
      updated_at: new Date().toISOString(),
    });
    if (existing?.user_id) {
      await repo.revokeAllUserSessions(existing.user_id);
      await repo.updateUserStatusAndLockout(existing.user_id, 'banned', null);
    }
  }

  const finalStatus = input.decision === 'dismissed' ? 'dismissed' : 'resolved';
  await repo.updateReportStatus(input.report_id, finalStatus);

  return {
    ok: true,
    report_id: input.report_id,
    decision: input.decision,
    status: finalStatus,
  };
}

