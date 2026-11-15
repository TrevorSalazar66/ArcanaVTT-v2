import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import { assertRole } from '../../middlewares/auth_middleware';
import { AppError } from '../../middlewares/error_handler';
import type {
  campaignsApplySchema,
  campaignsCreateSchema,
  campaignsListSchema,
} from '../../schemas/sync_schemas';
import type { AuthenticatedUser } from '../../types/env';
import { generateId } from '../../utils/crypto_jwt';

function generateQuickJoinCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const bytes = new Uint8Array(6);
  crypto.getRandomValues(bytes);
  return Array.from(bytes)
    .map((b) => chars[b % chars.length] ?? 'A')
    .join('');
}

export async function listCampaignsUseCase(
  userId: string,
  input: z.infer<typeof campaignsListSchema>,
  repo: IArcanaRepository,
) {
  const [allCampaigns, memberships] = await Promise.all([
    repo.listCampaigns(),
    repo.listCampaignMembershipsByUser(userId),
  ]);

  const membershipMap = new Map(memberships.map((m) => [m.campaign_id, m]));
  const query = input.search?.trim().toLowerCase() ?? '';

  const filtered = allCampaigns.filter((cmp) => {
    const member = membershipMap.get(cmp.id);
    if (query) {
      const hay = `${cmp.title} ${cmp.synopsis} ${cmp.quick_join_code}`.toLowerCase();
      if (!hay.includes(query)) return false;
    }

    switch (input.filter) {
      case 'mestre':
        return cmp.owner_id === userId || member?.table_role === 'mestre';
      case 'auxiliar':
        return member?.table_role === 'assistente_mestre';
      case 'jogando':
        return member?.table_role === 'jogador' && member.status === 'active';
      case 'explorar':
        return cmp.visibility === 'publica';
      default:
        return true;
    }
  });

  return { ok: true, campaigns: filtered, memberships };
}

export async function quickJoinCampaignUseCase(
  userId: string,
  rawCode: string,
  repo: IArcanaRepository,
) {
  const normalizedCode = rawCode.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
  const campaign = await repo.findCampaignByCode(normalizedCode);
  if (!campaign) {
    throw new AppError(
      404,
      'CAMPAIGN_CODE_NOT_FOUND',
      `Nenhuma campanha encontrada para o codigo ${normalizedCode}.`,
    );
  }

  const memberships = await repo.listCampaignMembershipsByUser(userId);
  const alreadyMember = memberships.some(
    (m) => m.campaign_id === campaign.id && m.status === 'active',
  );

  if (!alreadyMember) {
    if (campaign.occupied_slots >= campaign.max_slots) {
      throw new AppError(
        409,
        'CAMPAIGN_FULL',
        'Esta mesa ja atingiu o limite maximo de vagas.',
      );
    }

    await repo.upsertCampaignMember({
      campaign_id: campaign.id,
      user_id: userId,
      table_role: 'jogador',
      status: 'active',
      application_pitch: 'Entrada rapida por codigo Quick Join',
      character_id: null,
      joined_at: new Date().toISOString(),
    });
    await repo.incrementCampaignOccupiedSlots(campaign.id);
  }

  const updated = await repo.findCampaignById(campaign.id);
  return { ok: true, campaign: updated ?? campaign };
}

export async function createCampaignUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof campaignsCreateSchema>,
  repo: IArcanaRepository,
) {
  assertRole(authUser.role, ['mestre', 'admin', 'superadmin']);

  const nowIso = new Date().toISOString();
  const campaignId = generateId('cmp');
  const code = generateQuickJoinCode();

  const campaign = {
    id: campaignId,
    owner_id: authUser.userId,
    title: input.title,
    synopsis: input.synopsis,
    system_id: input.system_id,
    quick_join_code: code,
    mode: input.mode,
    schedule_text: input.schedule_text,
    max_slots: input.max_slots,
    occupied_slots: 1,
    visibility: input.visibility,
    state_json: JSON.stringify({ chapter: 'Sessao 0 — Preparacao' }),
    created_at: nowIso,
  };

  await repo.createCampaign(campaign, {
    campaign_id: campaignId,
    user_id: authUser.userId,
    table_role: 'mestre',
    status: 'active',
    application_pitch: null,
    character_id: null,
    joined_at: nowIso,
  });

  return { ok: true, campaign };
}

export async function applyToCampaignUseCase(
  userId: string,
  input: z.infer<typeof campaignsApplySchema>,
  repo: IArcanaRepository,
) {
  const campaign = await repo.findCampaignById(input.campaign_id);
  if (!campaign) {
    throw new AppError(404, 'CAMPAIGN_NOT_FOUND', 'Campanha nao encontrada.');
  }

  await repo.upsertCampaignMember({
    campaign_id: campaign.id,
    user_id: userId,
    table_role: 'jogador',
    status: 'pending',
    application_pitch: `${input.character_name}: ${input.pitch}`,
    character_id: null,
    joined_at: new Date().toISOString(),
  });

  return {
    ok: true,
    application_status: 'pending',
    campaign_id: campaign.id,
  };
}

