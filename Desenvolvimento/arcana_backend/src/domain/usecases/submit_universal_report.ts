import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import type { reportSubmitSchema } from '../../schemas/sync_schemas';
import type { AuthenticatedUser } from '../../types/env';
import { generateId } from '../../utils/crypto_jwt';

const ENTITY_TO_DB_ORIGIN: Record<
  string,
  'chat' | 'campanha' | 'usuario' | 'sistema' | 'forum'
> = {
  chat: 'chat',
  dm: 'chat',
  campanha: 'campanha',
  usuario: 'usuario',
  ficha_personagem: 'usuario',
  compendio: 'sistema',
  sistema: 'sistema',
  homebrew: 'sistema',
  guilda: 'forum',
  cla: 'forum',
  forum: 'forum',
  wiki: 'forum',
};

const ENTITY_LABEL: Record<string, string> = {
  usuario: 'USUÁRIO',
  chat: 'MENSAGEM_CHAT',
  dm: 'DM_PRIVADA',
  campanha: 'CAMPANHA',
  ficha_personagem: 'FICHA_PERSONAGEM',
  compendio: 'ELEMENTO_COMPÊNDIO',
  sistema: 'SISTEMA_RPG',
  homebrew: 'PACOTE_HOMEBREW',
  guilda: 'GUILDA',
  cla: 'CLÃ',
  forum: 'TOPICO_FORUM',
  wiki: 'ARTIGO_WIKI',
};

/**
 * Gera e persiste Denúncia Universal para todos os grupos de conteúdo com Autotags + pacote inviolável de evidências.
 */
export async function submitUniversalReportUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof reportSubmitSchema>,
  repo: IArcanaRepository,
) {
  const timestampUtc = new Date().toISOString();
  const label = ENTITY_LABEL[input.origin_type] ?? input.origin_type.toUpperCase();
  const dbOriginType = ENTITY_TO_DB_ORIGIN[input.origin_type] ?? 'chat';

  const targetDevice = input.target_user_id
    ? await repo.findLatestDeviceByUserId(input.target_user_id)
    : null;

  const autoTags = [
    `[TIPO: ${label}]`,
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
    origin_type: dbOriginType,
    entity_type: input.origin_type,
    origin_id: input.origin_id,
    reason_category: input.reason_category,
    description: input.description,
    auto_tags_json: JSON.stringify(autoTags),
    evidence_snapshot_json: JSON.stringify({
      reporter_device: authUser.deviceFingerprint.slice(0, 12),
      target_device_fingerprint: targetDevice?.device_fingerprint ?? null,
      context_session: input.context_session,
      entity_type: input.origin_type,
      captured_at: timestampUtc,
    }),
    votes_json: '[]',
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
