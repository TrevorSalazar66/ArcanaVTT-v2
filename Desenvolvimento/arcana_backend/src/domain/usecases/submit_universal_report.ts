import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import type { reportSubmitSchema } from '../../schemas/sync_schemas';
import type { AuthenticatedUser } from '../../types/env';
import { generateId } from '../../utils/crypto_jwt';

/**
 * Gera e persiste Denúncia Universal com Autotags automáticas imutáveis de contexto.
 */
export async function submitUniversalReportUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof reportSubmitSchema>,
  repo: IArcanaRepository,
) {
  const timestampUtc = new Date().toISOString();
  const autoTags = [
    `#origem:${input.origin_type}`,
    `#alvo:${input.origin_id}`,
    `#sessao:${input.context_session}`,
    `#cargo_relator:${authUser.role}`,
    `#utc:${timestampUtc.slice(0, 19)}Z`,
  ];

  const report = {
    id: generateId('rep'),
    reporter_id: authUser.userId,
    target_user_id: input.target_user_id ?? null,
    origin_type: input.origin_type,
    origin_id: input.origin_id,
    reason_category: input.reason_category,
    description: input.description,
    auto_tags_json: JSON.stringify(autoTags),
    evidence_snapshot_json: JSON.stringify({
      reporter_device: authUser.deviceFingerprint.slice(0, 10),
      context_session: input.context_session,
      captured_at: timestampUtc,
    }),
    status: 'pending' as const,
    created_at: timestampUtc,
  };

  await repo.createReport(report);
  return {
    ok: true,
    report_id: report.id,
    auto_tags: autoTags,
    status: report.status,
  };
}

