import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import { assertRole } from '../../middlewares/auth_middleware';
import { AppError } from '../../middlewares/error_handler';
import type {
  campaignsAcceptInviteSchema,
  campaignsApplySchema,
  campaignsCreateSchema,
  campaignsInvitePlayerSchema,
  campaignsListSchema,
  campaignsManageMemberSchema,
  campaignsUpdateSettingsSchema,
  scenesTriggerSchema,
  scenesUpsertSchema,
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

function parseJsonSafe(raw: string | undefined | null): Record<string, unknown> {
  if (!raw) return {};
  try {
    const parsed = JSON.parse(raw);
    return typeof parsed === 'object' && parsed !== null ? (parsed as Record<string, unknown>) : {};
  } catch {
    return {};
  }
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
      const hay = `${cmp.title} ${cmp.synopsis} ${cmp.quick_join_code} ${cmp.schedule_text} ${cmp.state_json}`.toLowerCase();
      if (!hay.includes(query)) return false;
    }

    switch (input.filter) {
      case 'mestre':
        return cmp.owner_id === userId || member?.table_role === 'mestre';
      case 'auxiliar':
        return member?.table_role === 'assistente_mestre' && member.status === 'active';
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
  if (await repo.isPlayerBannedByGM(campaign.owner_id, userId)) {
    throw new AppError(
      403,
      'BANNED_BY_GM',
      'Voce foi banido pelo Mestre desta mesa e nao pode ingressar em suas campanhas.',
    );
  }

  const memberships = await repo.listCampaignMembershipsByUser(userId);
  const alreadyMember = memberships.some(
    (m) => m.campaign_id === campaign.id && m.status === 'active',
  );

  if (!alreadyMember) {
    if (campaign.occupied_slots >= campaign.max_slots) {
      throw new AppError(409, 'CAMPAIGN_FULL', 'Esta mesa ja atingiu o limite maximo de vagas.');
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

  const existingSystems = await repo.listSystems();
  const hasSystem = existingSystems.some((s) => s.id === input.system_id);
  const safeSystemId = hasSystem ? input.system_id : 'sys_universal';

  const nowIso = new Date().toISOString();
  const campaignId = generateId('cmp');
  const code = generateQuickJoinCode();

  const initialState = {
    chapter: 'Sessão 0 — Preparação da Mesa',
    icon_name: input.icon_name,
    banner_preset: input.banner_preset,
    age_rating: input.age_rating,
    tags: input.tags.map((t) => t.replace(/\s+/g, '').slice(0, 24)),
    sessions_count: 0,
    notice_board: 'Bem-vindos à mesa! Aguardem as instruções iniciais do Mestre.',
    auto_approve_actions: false,
    scene_access_mode: 'free',
    xp_multiplier: 1.0,
    discord_voice_url: '',
    discord_webhook_url: '',
    channels: ['#geral-mesa', '#off-topic', '#segredos-sussurros'],
    world_clock: {
      year: 1,
      month: 1,
      month_name: 'Primeiro Ciclo',
      day: 1,
      hour: 8,
      minute: 0,
      season: 'Primavera',
      day_hours: 24,
      days_per_month: 30,
      light_hours: 12,
      months: ['Primeiro Ciclo'],
      events: [] as Array<Record<string, unknown>>,
      timeline: [] as Array<Record<string, unknown>>,
    },
    factions: [] as Array<{ id: string; name: string; reputation: number; notes: string }>,
    world_maps: [] as Array<Record<string, unknown>>,
    diary_entries: [] as Array<{
      id: string;
      scope: 'cronica' | 'pessoal' | 'segredo_gm' | 'roteiro';
      title: string;
      content: string;
      visible_to_players: boolean;
      author_id: string;
      created_at: string;
    }>,
    flags: {} as Record<string, unknown>,
  };

  const campaign = {
    id: campaignId,
    owner_id: authUser.userId,
    title: input.title,
    synopsis: input.synopsis,
    system_id: safeSystemId,
    quick_join_code: code,
    mode: input.mode,
    schedule_text: input.schedule_text,
    max_slots: input.max_slots,
    occupied_slots: 1,
    visibility: input.visibility,
    state_json: JSON.stringify(initialState),
    is_inactive_archived: 0,
    last_activity_at: nowIso,
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

export async function lookupCampaignByCodeUseCase(
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
  if (await repo.isPlayerBannedByGM(campaign.owner_id, userId)) {
    throw new AppError(
      403,
      'BANNED_BY_GM',
      'Acesso bloqueado: voce foi banido pelo Mestre desta campanha.',
    );
  }
  const member = await repo.findCampaignMember(campaign.id, userId);
  return {
    ok: true,
    campaign,
    membership: member,
    is_member: member?.status === 'active' || campaign.owner_id === userId,
  };
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
  if (await repo.isPlayerBannedByGM(campaign.owner_id, userId)) {
    throw new AppError(
      403,
      'BANNED_BY_GM',
      'Voce esta impedido de se candidatar pois foi banido pelo Mestre desta mesa.',
    );
  }

  const existing = await repo.findCampaignMember(campaign.id, userId);
  if (existing?.status === 'active' || campaign.owner_id === userId) {
    throw new AppError(409, 'ALREADY_MEMBER', 'Voce ja faz parte desta campanha.');
  }

  const nowIso = new Date().toISOString();
  await repo.upsertCampaignMember({
    campaign_id: campaign.id,
    user_id: userId,
    table_role: 'jogador',
    status: 'pending',
    application_pitch: input.pitch.trim(),
    character_id: null,
    joined_at: nowIso,
  });

  await repo.createNotification({
    id: generateId('not'),
    user_id: campaign.owner_id,
    category: 'mesas',
    title: 'Nova Candidatura na Mesa',
    body: `Um aventureiro solicitou entrada em "${campaign.title}".`,
    action_payload_json: JSON.stringify({
      campaign_id: campaign.id,
      campaign_code: campaign.quick_join_code,
    }),
    is_read: 0,
    created_at: nowIso,
  });

  return {
    ok: true,
    application_status: 'pending',
    campaign_id: campaign.id,
  };
}

export async function invitePlayerToCampaignUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof campaignsInvitePlayerSchema>,
  repo: IArcanaRepository,
) {
  const campaign = await repo.findCampaignById(input.campaign_id);
  if (!campaign) {
    throw new AppError(404, 'CAMPAIGN_NOT_FOUND', 'Campanha nao encontrada.');
  }
  const canInvite =
    campaign.owner_id === authUser.userId ||
    authUser.role === 'admin' ||
    authUser.role === 'superadmin';
  if (!canInvite) {
    throw new AppError(403, 'FORBIDDEN_TABLE_MASTER', 'Apenas o Mestre dono da mesa pode enviar convites diretos.');
  }
  if (await repo.isPlayerBannedByGM(campaign.owner_id, input.target_user_id)) {
    throw new AppError(400, 'TARGET_BANNED', 'Desbana o jogador antes de envia-lo um convite.');
  }

  const nowIso = new Date().toISOString();
  const inviteId = generateId('inv');
  await repo.createCampaignInvite({
    id: inviteId,
    campaign_id: campaign.id,
    target_user_id: input.target_user_id,
    invited_by_user_id: authUser.userId,
    status: 'pending',
    created_at: nowIso,
  });

  await repo.createNotification({
    id: generateId('not'),
    user_id: input.target_user_id,
    category: 'mesas',
    title: `Convite Direto: ${campaign.title}`,
    body: `O Mestre convidou voce para entrar imediatamente na mesa "${campaign.title}".`,
    action_payload_json: JSON.stringify({
      invite_id: inviteId,
      campaign_id: campaign.id,
      campaign_code: campaign.quick_join_code,
    }),
    is_read: 0,
    created_at: nowIso,
  });

  return { ok: true, invite_id: inviteId };
}

export async function acceptCampaignInviteUseCase(
  userId: string,
  input: z.infer<typeof campaignsAcceptInviteSchema>,
  repo: IArcanaRepository,
) {
  const invite = await repo.findCampaignInvite(input.invite_id);
  if (!invite || invite.target_user_id !== userId) {
    throw new AppError(404, 'INVITE_NOT_FOUND', 'Convite nao localizado.');
  }
  if (invite.status !== 'pending') {
    throw new AppError(400, 'INVITE_ALREADY_PROCESSED', 'Este convite ja foi respondido.');
  }

  const campaign = await repo.findCampaignById(invite.campaign_id);
  if (!campaign) {
    throw new AppError(404, 'CAMPAIGN_NOT_FOUND', 'Campanha nao encontrada.');
  }

  if (!input.accept) {
    await repo.updateCampaignInviteStatus(invite.id, 'declined');
    return { ok: true, accepted: false };
  }

  if (await repo.isPlayerBannedByGM(campaign.owner_id, userId)) {
    throw new AppError(403, 'BANNED_BY_GM', 'Voce esta banido pelo Mestre desta campanha.');
  }

  const existingMember = await repo.findCampaignMember(campaign.id, userId);
  if (existingMember?.status !== 'active') {
    if (campaign.occupied_slots >= campaign.max_slots) {
      throw new AppError(409, 'CAMPAIGN_FULL', 'Esta mesa atingiu o limite de vagas.');
    }
    await repo.upsertCampaignMember({
      campaign_id: campaign.id,
      user_id: userId,
      table_role: 'jogador',
      status: 'active',
      application_pitch: 'Convite direto aceito',
      character_id: null,
      joined_at: new Date().toISOString(),
    });
    await repo.incrementCampaignOccupiedSlots(campaign.id);
  }

  await repo.updateCampaignInviteStatus(invite.id, 'accepted');
  const updated = await repo.findCampaignById(campaign.id);
  return { ok: true, accepted: true, campaign: updated ?? campaign };
}

export async function leaveCampaignUseCase(
  userId: string,
  campaignId: string,
  repo: IArcanaRepository,
) {
  const campaign = await repo.findCampaignById(campaignId);
  if (!campaign) throw new AppError(404, 'CAMPAIGN_NOT_FOUND', 'Campanha nao encontrada.');
  if (campaign.owner_id === userId) {
    throw new AppError(400, 'OWNER_CANNOT_LEAVE', 'O Mestre fundador nao pode abandonar sua propria mesa.');
  }
  const existing = await repo.findCampaignMember(campaignId, userId);
  if (!existing || existing.status !== 'active') {
    return { ok: true, left: false };
  }
  await repo.upsertCampaignMember({
    ...existing,
    status: 'rejected',
    table_role: 'jogador',
  });
  await repo.decrementCampaignOccupiedSlots(campaignId);
  return { ok: true, left: true };
}

export async function listCampaignMembersUseCase(
  authUser: AuthenticatedUser,
  campaignId: string,
  repo: IArcanaRepository,
) {
  const campaign = await repo.findCampaignById(campaignId);
  if (!campaign) {
    throw new AppError(404, 'CAMPAIGN_NOT_FOUND', 'Campanha nao encontrada.');
  }
  const member = await repo.findCampaignMember(campaignId, authUser.userId);
  const canView =
    campaign.owner_id === authUser.userId ||
    member?.status === 'active' ||
    authUser.role === 'admin' ||
    authUser.role === 'superadmin';
  if (!canView) {
    throw new AppError(403, 'FORBIDDEN_TABLE_MEMBER', 'Acesso restrito aos participantes da mesa.');
  }
  const members = await repo.listCampaignMembersByCampaign(campaignId);
  return { ok: true, members };
}

export async function manageCampaignMemberUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof campaignsManageMemberSchema>,
  repo: IArcanaRepository,
) {
  const campaign = await repo.findCampaignById(input.campaign_id);
  if (!campaign) {
    throw new AppError(404, 'CAMPAIGN_NOT_FOUND', 'Campanha nao encontrada.');
  }
  const canManage =
    campaign.owner_id === authUser.userId ||
    authUser.role === 'admin' ||
    authUser.role === 'superadmin';
  if (!canManage) {
    throw new AppError(
      403,
      'FORBIDDEN_TABLE_MASTER',
      'Somente o Mestre criador da mesa pode aprovar, expulsar, banir ou delegar funcoes locais.',
    );
  }

  const target = await repo.findCampaignMember(campaign.id, input.target_user_id);
  if (!target) {
    throw new AppError(404, 'MEMBER_NOT_FOUND', 'Membro ou candidato nao localizado.');
  }
  if (input.target_user_id === campaign.owner_id) {
    throw new AppError(400, 'CANNOT_ALTER_OWNER', 'O Mestre criador da mesa nao pode ser alterado.');
  }

  if (input.status === 'banned') {
    await repo.banPlayerFromGM(
      campaign.owner_id,
      target.user_id,
      input.ban_reason?.trim() || 'Banimento em nivel de Mestre',
    );
    await repo.createNotification({
      id: generateId('not'),
      user_id: target.user_id,
      category: 'mesas',
      title: `Banimento de Mesas: ${campaign.title}`,
      body: 'Voce foi banido pelo Mestre de suas campanhas atuais e futuras.',
      action_payload_json: JSON.stringify({ campaign_id: campaign.id }),
      is_read: 0,
      created_at: new Date().toISOString(),
    });
    const members = await repo.listCampaignMembersByCampaign(campaign.id);
    return { ok: true, members, banned_master_level: true };
  }

  const mappedStatus: 'pending' | 'active' | 'rejected' =
    input.status === 'kicked' || input.status === 'rejected'
      ? 'rejected'
      : input.status === 'active'
        ? 'active'
        : target.status;

  const nextTableRole =
    mappedStatus === 'rejected'
      ? 'jogador'
      : (input.table_role ?? (target.table_role === 'mestre' ? 'jogador' : target.table_role));

  const wasActive = target.status === 'active';
  if (!wasActive && mappedStatus === 'active') {
    if (campaign.occupied_slots >= campaign.max_slots) {
      throw new AppError(409, 'CAMPAIGN_FULL', 'Esta mesa ja atingiu o limite maximo de vagas.');
    }
    await repo.incrementCampaignOccupiedSlots(campaign.id);
  } else if (wasActive && mappedStatus === 'rejected') {
    await repo.decrementCampaignOccupiedSlots(campaign.id);
  }

  await repo.upsertCampaignMember({
    ...target,
    status: mappedStatus,
    table_role: nextTableRole,
  });

  await repo.createNotification({
    id: generateId('not'),
    user_id: target.user_id,
    category: 'mesas',
    title:
      mappedStatus === 'active'
        ? `Candidatura Aprovada: ${campaign.title}`
        : `Atualizacao de Mesa: ${campaign.title}`,
    body:
      mappedStatus === 'active'
        ? 'Sua entrada foi aprovada! Crie sua ficha de heroi na aba Personagens da mesa.'
        : input.status === 'kicked'
          ? 'Voce foi removido da mesa pelo Mestre.'
          : 'Sua solicitacao foi atualizada pelo Mestre da mesa.',
    action_payload_json: JSON.stringify({ campaign_id: campaign.id }),
    is_read: 0,
    created_at: new Date().toISOString(),
  });

  const members = await repo.listCampaignMembersByCampaign(campaign.id);
  return { ok: true, members };
}

export async function listGmBannedPlayersUseCase(
  authUser: AuthenticatedUser,
  repo: IArcanaRepository,
) {
  const bans = await repo.listGMBannedPlayers(authUser.userId);
  return { ok: true, bans };
}

export async function unbanPlayerFromGmUseCase(
  authUser: AuthenticatedUser,
  playerId: string,
  repo: IArcanaRepository,
) {
  await repo.unbanPlayerFromGM(authUser.userId, playerId);
  const bans = await repo.listGMBannedPlayers(authUser.userId);
  return { ok: true, bans };
}

export async function updateCampaignSettingsUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof campaignsUpdateSettingsSchema>,
  repo: IArcanaRepository,
) {
  const campaign = await repo.findCampaignById(input.campaign_id);
  if (!campaign) throw new AppError(404, 'CAMPAIGN_NOT_FOUND', 'Campanha nao encontrada.');

  const member = await repo.findCampaignMember(campaign.id, authUser.userId);
  const canEdit =
    campaign.owner_id === authUser.userId ||
    member?.status === 'active' && member.table_role === 'assistente_mestre' ||
    authUser.role === 'admin' ||
    authUser.role === 'superadmin';
  if (!canEdit) {
    throw new AppError(403, 'FORBIDDEN_TABLE_MASTER', 'Permissao restrita ao Mestre da mesa.');
  }

  const prevState = parseJsonSafe(campaign.state_json);
  const nextState: Record<string, unknown> = {
    ...prevState,
    ...(input.state_patch ?? {}),
  };

  if (Array.isArray(nextState.world_maps) && nextState.world_maps.length > 25) {
    throw new AppError(400, 'WORLD_MAPS_LIMIT', 'Limite maximo rigido de 25 mapas globais por campanha.');
  }
  if (Array.isArray(nextState.channels) && nextState.channels.length > 3) {
    nextState.channels = nextState.channels.slice(0, 3);
  }

  const updated = {
    ...campaign,
    title: input.title ?? campaign.title,
    synopsis: input.synopsis ?? campaign.synopsis,
    visibility: input.visibility ?? campaign.visibility,
    mode: input.mode ?? campaign.mode,
    schedule_text: input.schedule_text ?? campaign.schedule_text,
    state_json: JSON.stringify(nextState),
    is_inactive_archived: input.reactivate_75d ? 0 : (campaign.is_inactive_archived ?? 0),
    last_activity_at: new Date().toISOString(),
  };

  await repo.updateCampaign(updated);
  return { ok: true, campaign: updated };
}

export async function listCampaignCharactersUseCase(
  authUser: AuthenticatedUser,
  campaignId: string,
  repo: IArcanaRepository,
) {
  const campaign = await repo.findCampaignById(campaignId);
  if (!campaign) throw new AppError(404, 'CAMPAIGN_NOT_FOUND', 'Campanha nao encontrada.');
  const member = await repo.findCampaignMember(campaignId, authUser.userId);
  const canView =
    campaign.owner_id === authUser.userId ||
    member?.status === 'active' ||
    authUser.role === 'admin' ||
    authUser.role === 'superadmin';
  if (!canView) {
    throw new AppError(403, 'FORBIDDEN', 'Acesso restrito aos membros da campanha.');
  }
  const characters = await repo.listCharactersByCampaign(campaignId);
  return { ok: true, characters };
}

export async function listCampaignScenesUseCase(
  authUser: AuthenticatedUser,
  campaignId: string,
  repo: IArcanaRepository,
) {
  const campaign = await repo.findCampaignById(campaignId);
  if (!campaign) throw new AppError(404, 'CAMPAIGN_NOT_FOUND', 'Campanha nao encontrada.');
  const member = await repo.findCampaignMember(campaignId, authUser.userId);
  const isLeader =
    campaign.owner_id === authUser.userId ||
    authUser.role === 'admin' ||
    authUser.role === 'superadmin';
  const isMember = isLeader || member?.status === 'active';
  if (!isMember) {
    throw new AppError(403, 'FORBIDDEN', 'Entre na campanha para visualizar suas cenas.');
  }
  const all = await repo.listScenesByCampaign(campaignId);
  const scenes = isLeader ? all : all.filter((s) => s.is_active === 1);
  return { ok: true, scenes, total_count: all.length };
}

export async function upsertCampaignSceneUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof scenesUpsertSchema>,
  repo: IArcanaRepository,
) {
  const campaign = await repo.findCampaignById(input.campaign_id);
  if (!campaign) throw new AppError(404, 'CAMPAIGN_NOT_FOUND', 'Campanha nao encontrada.');
  if (
    campaign.owner_id !== authUser.userId &&
    authUser.role !== 'admin' &&
    authUser.role !== 'superadmin'
  ) {
    throw new AppError(403, 'FORBIDDEN_TABLE_MASTER', 'Apenas o Mestre da campanha pode editar a Oficina de Cenas.');
  }

  const existing = await repo.listScenesByCampaign(campaign.id);
  const isUpdate = Boolean(input.id && existing.some((s) => s.id === input.id));
  if (!isUpdate && existing.length >= 18) {
    throw new AppError(
      409,
      'SCENES_LIMIT_REACHED',
      'Limite maximo rigido de 18 cenas por campanha atingido.',
    );
  }

  const nowIso = new Date().toISOString();
  const prev = input.id ? await repo.findSceneById(input.id) : null;
  const scene = {
    id: input.id && input.id.trim().length > 0 ? input.id.trim() : generateId('scn'),
    campaign_id: campaign.id,
    name: input.name.trim(),
    description: input.description.trim(),
    model_type: input.model_type,
    is_active: input.is_active ? 1 : 0,
    max_players: input.max_players,
    model_data_json: JSON.stringify(input.model_data),
    rules_data_json: JSON.stringify(input.rules_data),
    state_data_json: JSON.stringify(input.state_data),
    created_at: prev?.created_at ?? nowIso,
    updated_at: nowIso,
  };

  await repo.upsertScene(scene);
  return { ok: true, scene };
}

export async function deleteCampaignSceneUseCase(
  authUser: AuthenticatedUser,
  campaignId: string,
  sceneId: string,
  repo: IArcanaRepository,
) {
  const campaign = await repo.findCampaignById(campaignId);
  if (!campaign) throw new AppError(404, 'CAMPAIGN_NOT_FOUND', 'Campanha nao encontrada.');
  if (
    campaign.owner_id !== authUser.userId &&
    authUser.role !== 'admin' &&
    authUser.role !== 'superadmin'
  ) {
    throw new AppError(403, 'FORBIDDEN_TABLE_MASTER', 'Apenas o Mestre pode excluir cenas.');
  }
  await repo.deleteScene(sceneId);
  return { ok: true, deleted_scene_id: sceneId };
}

/**
 * Execução autoritativa de Gatilhos No-Code (`[QUANDO] -> [SE] -> [ENTÃO]`) validada contra o banco.
 */
export async function triggerSceneActionUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof scenesTriggerSchema>,
  repo: IArcanaRepository,
) {
  const [campaign, scene] = await Promise.all([
    repo.findCampaignById(input.campaign_id),
    repo.findSceneById(input.scene_id),
  ]);
  if (!campaign || !scene || scene.campaign_id !== campaign.id) {
    throw new AppError(404, 'SCENE_NOT_FOUND', 'Cena nao localizada nesta campanha.');
  }
  const member = await repo.findCampaignMember(campaign.id, authUser.userId);
  if (
    campaign.owner_id !== authUser.userId &&
    authUser.role !== 'admin' &&
    authUser.role !== 'superadmin' &&
    member?.status !== 'active'
  ) {
    throw new AppError(403, 'FORBIDDEN', 'Apenas membros ativos podem acionar gatilhos na cena.');
  }

  let rules: Array<Record<string, unknown>> = [];
  try {
    rules = JSON.parse(scene.rules_data_json) as Array<Record<string, unknown>>;
  } catch {
    rules = [];
  }

  const stateData = parseJsonSafe(scene.state_data_json);
  const campaignState = parseJsonSafe(campaign.state_json);
  const character = await repo.findCharacterByUserAndCampaign(authUser.userId, campaign.id);

  const matchingRules = rules.filter((r) => {
    const trig = (r.trigger as Record<string, unknown> | undefined) ?? {};
    return trig.type === input.trigger_type;
  });

  const logs: string[] = [];
  const toasts: string[] = [];
  let transferSceneId: string | null = null;

  for (const rule of matchingRules) {
    const conditions = (rule.conditions as Array<Record<string, unknown>> | undefined) ?? [];
    let conditionsPass = true;

    for (const cond of conditions) {
      const cType = cond.type as string | undefined;
      if (!cType || cType === 'always') continue;
      if (cType === 'has_item') {
        const itemId = String(cond.item_name ?? cond.item_id ?? '').toLowerCase();
        const slots = character ? (JSON.parse(character.slots_json) as string[]) : [];
        if (!slots.some((s) => s.toLowerCase().includes(itemId))) {
          conditionsPass = false;
        }
      } else if (cType === 'attribute_gte') {
        const attrKey = String(cond.attribute ?? 'corpo').toLowerCase();
        const minVal = Number(cond.value ?? 1);
        const attrs = character ? parseJsonSafe(character.attributes_json) : {};
        if (Number(attrs[attrKey] ?? 0) < minVal) {
          conditionsPass = false;
        }
      } else if (cType === 'faction_gte') {
        const facName = String(cond.faction_name ?? '').toLowerCase();
        const minRep = Number(cond.value ?? 0);
        const factions = (campaignState.factions as Array<Record<string, unknown>> | undefined) ?? [];
        const matched = factions.find((f) => String(f.name ?? '').toLowerCase() === facName);
        if (Number(matched?.reputation ?? 0) < minRep) {
          conditionsPass = false;
        }
      }
    }

    const effectsList = conditionsPass
      ? ((rule.effects as Array<Record<string, unknown>> | undefined) ?? [])
      : ((rule.fallback_effects as Array<Record<string, unknown>> | undefined) ?? []);

    for (const eff of effectsList) {
      const eType = eff.type as string | undefined;
      const params = (eff.params as Record<string, unknown> | undefined) ?? {};
      if (eType === 'show_toast') {
        toasts.push(String(params.message ?? 'Gatilho acionado.'));
      } else if (eType === 'log_diary') {
        const txt = String(params.text ?? 'Evento registrado na cena.');
        logs.push(txt);
        const entries = (campaignState.diary_entries as Array<Record<string, unknown>> | undefined) ?? [];
        entries.unshift({
          id: generateId('dia'),
          scope: 'cronica',
          title: `Evento: ${scene.name}`,
          content: txt,
          visible_to_players: true,
          author_id: authUser.userId,
          created_at: new Date().toISOString(),
        });
        campaignState.diary_entries = entries;
      } else if (eType === 'transfer_scene') {
        transferSceneId = String(params.target_scene_id ?? '');
      } else if (eType === 'award_item' && character) {
        const slots = JSON.parse(character.slots_json) as string[];
        const itemLabel = String(params.item_name ?? params.item_id ?? 'Relíquia');
        slots.push(itemLabel);
        await repo.upsertCharacter({
          ...character,
          slots_json: JSON.stringify(slots.slice(0, 24)),
          updated_at: new Date().toISOString(),
        });
      } else if ((eType === 'apply_damage' || eType === 'heal_anima') && character) {
        const statuses = parseJsonSafe(character.statuses_json);
        const cur = Number(statuses.anima_current ?? 10);
        const max = Number(statuses.anima_max ?? 10);
        const delta = Number(params.amount ?? 2);
        statuses.anima_current =
          eType === 'apply_damage' ? Math.max(0, cur - delta) : Math.min(max, cur + delta);
        await repo.upsertCharacter({
          ...character,
          statuses_json: JSON.stringify(statuses),
          updated_at: new Date().toISOString(),
        });
      }
    }
  }

  stateData.last_triggered = {
    type: input.trigger_type,
    params: input.params,
    by: authUser.userId,
    at: new Date().toISOString(),
  };

  await repo.upsertScene({
    ...scene,
    state_data_json: JSON.stringify(stateData),
    updated_at: new Date().toISOString(),
  });
  await repo.updateCampaign({
    ...campaign,
    state_json: JSON.stringify(campaignState),
    last_activity_at: new Date().toISOString(),
  });

  return {
    ok: true,
    matched_rules: matchingRules.length,
    toasts,
    logs,
    transfer_scene_id: transferSceneId,
    scene_state: stateData,
  };
}
