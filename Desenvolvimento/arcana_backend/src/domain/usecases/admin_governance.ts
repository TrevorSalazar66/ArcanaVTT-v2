import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import { assertRole } from '../../middlewares/auth_middleware';
import { AppError } from '../../middlewares/error_handler';
import type {
  adminModerateSchema,
  adminUpdateRoleSchema,
} from '../../schemas/sync_schemas';
import type { AuthenticatedUser } from '../../types/env';
import { generateId } from '../../utils/crypto_jwt';
import { buildDmChannelId } from './manage_social';

function generateCreationKeyCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const bytes = new Uint8Array(6);
  crypto.getRandomValues(bytes);
  const tail = Array.from(bytes)
    .map((b) => chars[b % chars.length] ?? 'A')
    .join('');
  return `KEY-ARC-${tail}`;
}

const GRAVE_PUNISHMENTS = new Set([
  'suspend_24h',
  'suspend_7d',
  'suspend_30d',
  'hardware_ban',
]);

/**
 * Painel de Governança Admin (Zero-Trust: exclusivo para `admin` e `superadmin`).
 */
export async function getAdminOverviewUseCase(
  authUser: AuthenticatedUser,
  repo: IArcanaRepository,
) {
  assertRole(authUser.role, ['admin', 'superadmin']);
  const [reports, metrics, users, bannedDevices, creationKeys] = await Promise.all([
    repo.listReports(),
    repo.listMetricsSummary(),
    repo.listUsersWithProfiles(),
    repo.listBannedDevices(),
    repo.listSystemKeys(),
  ]);
  return {
    ok: true,
    metrics,
    reports,
    users,
    banned_devices: bannedDevices,
    creation_keys: creationKeys,
  };
}

export async function updateUserRoleAdminUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof adminUpdateRoleSchema>,
  repo: IArcanaRepository,
) {
  assertRole(authUser.role, ['admin', 'superadmin']);

  if (input.target_user_id === 'usr_system_official') {
    throw new AppError(403, 'PROTECTED_SYSTEM_USER', 'Conta do sistema nao pode ser alterada.');
  }

  const targetUser = await repo.findUserById(input.target_user_id);
  if (!targetUser) {
    throw new AppError(404, 'USER_NOT_FOUND', 'Usuario nao localizado.');
  }
  if (targetUser.role === 'superadmin') {
    throw new AppError(403, 'PROTECTED_SUPERADMIN', 'O cargo de Superadmin nao pode ser rebaixado.');
  }

  if (
    (input.role === 'admin' || targetUser.role === 'admin') &&
    authUser.role !== 'superadmin'
  ) {
    throw new AppError(
      403,
      'SUPERADMIN_ONLY',
      'Somente o Superadmin pode conceder ou revogar o cargo de Administrador.',
    );
  }

  await repo.updateUserRole(targetUser.id, input.role);
  return {
    ok: true,
    user_id: targetUser.id,
    role: input.role,
  };
}

/**
 * Moderação de Denúncias com Votação Colegiada de 3 Admins para punições graves (ou imediata pelo Superadmin).
 */
export async function moderateReportUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof adminModerateSchema>,
  repo: IArcanaRepository,
) {
  assertRole(authUser.role, ['admin', 'superadmin']);

  const report = await repo.findReportById(input.report_id);
  if (!report) {
    throw new AppError(404, 'REPORT_NOT_FOUND', 'Denuncia nao localizada.');
  }

  const isGrave = GRAVE_PUNISHMENTS.has(input.decision);
  let votes: string[] = [];
  try {
    votes = JSON.parse(report.votes_json ?? '[]') as string[];
  } catch {
    votes = [];
  }

  if (isGrave && authUser.role === 'admin') {
    if (!votes.includes(authUser.userId)) {
      votes.push(authUser.userId);
    }
    if (votes.length < 3) {
      await repo.updateReportVotes(report.id, JSON.stringify(votes));
      return {
        ok: true,
        report_id: report.id,
        decision: input.decision,
        status: 'pending' as const,
        votes_count: votes.length,
        required_votes: 3,
        message: `Voto registrado (${votes.length}/3 Admins necessarios para execucao colegiada).`,
      };
    }
  }

  if (
    input.decision === 'suspend_24h' ||
    input.decision === 'suspend_7d' ||
    input.decision === 'suspend_30d'
  ) {
    if (report.target_user_id) {
      const hours = input.decision === 'suspend_24h' ? 24 : input.decision === 'suspend_7d' ? 168 : 720;
      const untilIso = new Date(Date.now() + hours * 60 * 60 * 1000).toISOString();
      await repo.updateUserSuspension(report.target_user_id, untilIso);
      await repo.revokeAllUserSessions(report.target_user_id);
    }
  }

  if (input.decision === 'hardware_ban') {
    let targetFingerprint = input.ban_device_fingerprint;
    if (!targetFingerprint) {
      try {
        const snap = JSON.parse(report.evidence_snapshot_json) as Record<string, unknown>;
        targetFingerprint = snap.target_device_fingerprint as string | undefined;
      } catch {
        targetFingerprint = undefined;
      }
    }
    if (!targetFingerprint && report.target_user_id) {
      const latest = await repo.findLatestDeviceByUserId(report.target_user_id);
      targetFingerprint = latest?.device_fingerprint;
    }

    if (targetFingerprint) {
      const existing = await repo.findDeviceSecurity(targetFingerprint);
      await repo.upsertDeviceSecurity({
        device_fingerprint: targetFingerprint,
        user_id: existing?.user_id ?? report.target_user_id ?? null,
        android_id_hash: existing?.android_id_hash ?? 'manual_ban',
        is_trusted: 0,
        is_hardware_banned: 1,
        ban_reason: input.ban_reason ?? 'Violacao severa das Diretrizes ArcanaVTT',
        trusted_until: null,
        last_ip: existing?.last_ip ?? null,
        updated_at: new Date().toISOString(),
      });
      const uid = existing?.user_id ?? report.target_user_id;
      if (uid) {
        await repo.revokeAllUserSessions(uid);
        await repo.updateUserStatusAndLockout(uid, 'banned', null);
      }
    }
  }

  const finalStatus = input.decision === 'dismissed' ? 'dismissed' : 'resolved';
  await repo.updateReportVotes(report.id, JSON.stringify(votes), finalStatus);

  return {
    ok: true,
    report_id: report.id,
    decision: input.decision,
    status: finalStatus,
    votes_count: votes.length,
    required_votes: isGrave ? 3 : 1,
  };
}

export async function unbanDeviceAdminUseCase(
  authUser: AuthenticatedUser,
  deviceFingerprint: string,
  repo: IArcanaRepository,
) {
  assertRole(authUser.role, ['admin', 'superadmin']);
  const dev = await repo.findDeviceSecurity(deviceFingerprint);
  if (!dev) throw new AppError(404, 'DEVICE_NOT_FOUND', 'Dispositivo nao localizado.');
  await repo.upsertDeviceSecurity({
    ...dev,
    is_hardware_banned: 0,
    ban_reason: null,
    updated_at: new Date().toISOString(),
  });
  return { ok: true, device_fingerprint: deviceFingerprint, unbanned: true };
}

export async function generateSystemCreationKeyUseCase(
  authUser: AuthenticatedUser,
  assignedToUserId: string | undefined,
  repo: IArcanaRepository,
) {
  assertRole(authUser.role, ['admin', 'superadmin']);
  const nowIso = new Date().toISOString();
  const code = generateCreationKeyCode();
  const record = {
    code,
    created_by: authUser.userId,
    assigned_to_user_id: assignedToUserId ?? null,
    used_by_user_id: null,
    is_used: 0,
    created_at: nowIso,
  };
  await repo.createSystemKey(record);

  if (assignedToUserId) {
    await repo.createNotification({
      id: generateId('not'),
      user_id: assignedToUserId,
      category: 'sistema',
      title: 'Key de Criação de Sistema Concedida',
      body: `Sua Key oficial para forjar um sistema proprio foi emitida: ${code}`,
      action_payload_json: JSON.stringify({ creation_key: code }),
      is_read: 0,
      created_at: nowIso,
    });
  }
  return { ok: true, key: record };
}

export async function auditDmsSuperadminUseCase(
  authUser: AuthenticatedUser,
  userA: string,
  userB: string,
  repo: IArcanaRepository,
) {
  assertRole(authUser.role, ['superadmin']);
  const channelId = buildDmChannelId(userA, userB);
  const messages = await repo.listChatMessages(channelId);
  return { ok: true, channel_id: channelId, messages };
}
