import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import { AppError } from '../../middlewares/error_handler';
import type {
  charactersUpsertSchema,
  dmListMessagesSchema,
  dmSendMessageSchema,
  socialAddFriendSchema,
  socialGetProfileSchema,
  socialRespondFriendSchema,
} from '../../schemas/sync_schemas';
import { generateId } from '../../utils/crypto_jwt';
import { executeUniversalRoll } from './universal_rpg_engine';

export function buildDmChannelId(userA: string, userB: string): string {
  const sorted = [userA, userB].sort();
  return `dm:${sorted[0]}__${sorted[1]}`;
}

export async function getSocialOverviewUseCase(userId: string, repo: IArcanaRepository) {
  const [friends, notifications, characters] = await Promise.all([
    repo.listFriendships(userId),
    repo.listNotifications(userId),
    repo.listCharactersByUser(userId),
  ]);

  return {
    ok: true,
    friends,
    notifications,
    characters,
    unread_count: notifications.filter((n) => n.is_read === 0).length,
  };
}

/**
 * Retorna Perfil Social Estilo Discord SEM expor e-mail privado (Sigilo LGPD).
 * Inclui campanhas em comum (`mutual_campaigns`) e Vitrine da Taverna com dados para Drill-Down.
 */
export async function getSocialProfileUseCase(
  requesterId: string,
  input: z.infer<typeof socialGetProfileSchema>,
  repo: IArcanaRepository,
) {
  const targetProfile = input.user_id
    ? await repo.findProfileByUserId(input.user_id)
    : input.username
      ? await repo.findProfileByUsername(input.username.replace(/^@+/, ''))
      : await repo.findProfileByUserId(requesterId);

  if (!targetProfile) {
    throw new AppError(404, 'PROFILE_NOT_FOUND', 'Perfil nao encontrado.');
  }

  const [targetUser, targetMemberships, reqMemberships, allCampaigns, targetChars, allSystems] =
    await Promise.all([
      repo.findUserById(targetProfile.user_id),
      repo.listCampaignMembershipsByUser(targetProfile.user_id),
      repo.listCampaignMembershipsByUser(requesterId),
      repo.listCampaigns(),
      repo.listCharactersByUser(targetProfile.user_id),
      repo.listSystems(),
    ]);

  const reqCmpIds = new Set(
    reqMemberships.filter((m) => m.status === 'active').map((m) => m.campaign_id),
  );
  const targetActiveIds = new Set(
    targetMemberships.filter((m) => m.status === 'active').map((m) => m.campaign_id),
  );

  const mutualCampaigns = allCampaigns
    .filter((c) => reqCmpIds.has(c.id) && targetActiveIds.has(c.id))
    .map((c) => ({ id: c.id, title: c.title, mode: c.mode }));

  const targetCampaignsList = allCampaigns
    .filter((c) => targetActiveIds.has(c.id) || c.owner_id === targetProfile.user_id)
    .map((c) => ({ id: c.id, title: c.title, system_id: c.system_id, owner_id: c.owner_id }));

  const sysCount = new Map<string, number>();
  for (const c of targetCampaignsList) {
    sysCount.set(c.system_id, (sysCount.get(c.system_id) ?? 0) + 1);
  }
  const systemsRanked = Array.from(sysCount.entries()).map(([sysId, count]) => {
    const foundSys = allSystems.find((s) => s.id === sysId);
    const tier =
      count >= 30
        ? 'Mestre do Sistema'
        : count >= 11
          ? 'Veterano'
          : count >= 3
            ? 'Praticante'
            : 'Iniciante';
    return {
      system_id: sysId,
      system_name: foundSys?.name ?? 'Motor Universal',
      campaigns_count: count,
      experience_tier: tier,
    };
  });

  let contacts: Record<string, string> = {};
  try {
    contacts = JSON.parse(targetProfile.contacts_json ?? '{}') as Record<string, string>;
  } catch {
    contacts = {};
  }

  return {
    ok: true,
    profile: {
      user_id: targetProfile.user_id,
      username: targetProfile.username,
      display_name: targetProfile.display_name,
      bio: targetProfile.bio,
      avatar_icon: targetProfile.avatar_icon,
      role: targetUser?.role ?? 'jogador',
      oauth_verified: true,
      reputation_points: targetProfile.reputation_points,
      created_at: targetUser?.created_at ?? '',
      contacts,
    },
    mutual_campaigns: mutualCampaigns,
    showcase: {
      campaigns_as_player: targetMemberships.filter(
        (m) => m.status === 'active' && m.table_role === 'jogador',
      ).length,
      campaigns_as_master: targetCampaignsList.filter(
        (c) => c.owner_id === targetProfile.user_id,
      ).length,
      characters_count: targetChars.length,
      systems_ranked: systemsRanked,
      campaigns_list: targetCampaignsList,
      characters_list: targetChars.map((ch) => ({
        id: ch.id,
        name: ch.name,
        title: ch.title,
        level: ch.level,
        campaign_id: ch.campaign_id,
      })),
    },
  };
}

export async function markNotificationsReadUseCase(
  userId: string,
  notificationId: string | undefined,
  repo: IArcanaRepository,
) {
  await repo.markNotificationsRead(userId, notificationId);
  const notifications = await repo.listNotifications(userId);
  return {
    ok: true,
    unread_count: notifications.filter((n) => n.is_read === 0).length,
  };
}

export async function addFriendUseCase(
  userId: string,
  input: z.infer<typeof socialAddFriendSchema>,
  repo: IArcanaRepository,
) {
  const cleanHandle = input.username.replace(/^@+/, '').trim().toLowerCase();

  const [targetProfile, requesterProfile] = await Promise.all([
    repo.findProfileByUsername(cleanHandle),
    repo.findProfileByUserId(userId),
  ]);

  if (!targetProfile) {
    throw new AppError(
      404,
      'USER_NOT_FOUND',
      `Nenhum aventureiro encontrado com o identificador @${cleanHandle}.`,
    );
  }
  if (targetProfile.user_id === userId) {
    throw new AppError(400, 'SELF_FRIEND_INVALID', 'Voce nao pode adicionar a si mesmo como aliado.');
  }

  const nowIso = new Date().toISOString();
  const sentRecord = {
    user_id: userId,
    friend_id: targetProfile.user_id,
    friend_username: targetProfile.username,
    friend_display_name: targetProfile.display_name,
    status: 'accepted' as const,
    presence_status: 'online' as const,
    presence_activity: 'Na Taverna',
    updated_at: nowIso,
  };
  await repo.addFriendship(sentRecord);

  // Registra solicitação recebida para o outro usuário aceitar ou recusar
  await repo.addFriendship({
    user_id: targetProfile.user_id,
    friend_id: userId,
    friend_username: requesterProfile?.username ?? 'heroi',
    friend_display_name: requesterProfile?.display_name ?? 'Aventureiro',
    status: 'pending',
    presence_status: 'online',
    presence_activity: 'Aguardando resposta',
    updated_at: nowIso,
  });

  await repo.createNotification({
    id: generateId('not'),
    user_id: targetProfile.user_id,
    category: 'social',
    title: 'Solicitação de Amizade',
    body: `@${requesterProfile?.username ?? 'aventureiro'} enviou um pedido de amizade.`,
    action_payload_json: JSON.stringify({ friend_user_id: userId }),
    is_read: 0,
    created_at: nowIso,
  });

  return { ok: true, friendship: sentRecord };
}

export async function respondFriendUseCase(
  userId: string,
  input: z.infer<typeof socialRespondFriendSchema>,
  repo: IArcanaRepository,
) {
  const nowIso = new Date().toISOString();
  if (input.decision === 'reject' || input.decision === 'remove') {
    await repo.removeFriendship(userId, input.friend_user_id);
    return { ok: true, status: input.decision };
  }

  const peerProfile = await repo.findProfileByUserId(input.friend_user_id);
  const myProfile = await repo.findProfileByUserId(userId);
  const status = input.decision === 'block' ? ('blocked' as const) : ('accepted' as const);

  await repo.addFriendship({
    user_id: userId,
    friend_id: input.friend_user_id,
    friend_username: peerProfile?.username ?? '',
    friend_display_name: peerProfile?.display_name ?? '',
    status,
    presence_status: 'online',
    presence_activity: status === 'blocked' ? 'Bloqueado' : 'Aliado Confirmado',
    updated_at: nowIso,
  });

  if (status === 'accepted') {
    await repo.addFriendship({
      user_id: input.friend_user_id,
      friend_id: userId,
      friend_username: myProfile?.username ?? '',
      friend_display_name: myProfile?.display_name ?? '',
      status: 'accepted',
      presence_status: 'online',
      presence_activity: 'Aliado Confirmado',
      updated_at: nowIso,
    });
  }

  const friends = await repo.listFriendships(userId);
  return { ok: true, status, friends };
}

export async function listDmMessagesUseCase(
  userId: string,
  input: z.infer<typeof dmListMessagesSchema>,
  repo: IArcanaRepository,
) {
  const channelId = buildDmChannelId(userId, input.peer_user_id);
  const messages = await repo.listChatMessages(channelId);
  return { ok: true, channel_id: channelId, peer_user_id: input.peer_user_id, messages };
}

export async function sendDmMessageUseCase(
  userId: string,
  userRole: string,
  input: z.infer<typeof dmSendMessageSchema>,
  repo: IArcanaRepository,
) {
  if (input.peer_user_id === userId) {
    throw new AppError(400, 'SELF_DM_INVALID', 'Nao e possivel abrir DM consigo mesmo.');
  }
  const peer = await repo.findUserById(input.peer_user_id);
  if (!peer) throw new AppError(404, 'USER_NOT_FOUND', 'Destinatario nao localizado.');

  const peerFriends = await repo.listFriendships(input.peer_user_id);
  const isBlocked = peerFriends.some((f) => f.friend_id === userId && f.status === 'blocked');
  if (isBlocked) {
    throw new AppError(403, 'USER_BLOCKED_DM', 'Este usuario bloqueou mensagens diretas de voce.');
  }

  const senderProfile = await repo.findProfileByUserId(userId);
  const senderHandle = senderProfile ? `@${senderProfile.username}` : '@heroi';
  const channelId = buildDmChannelId(userId, input.peer_user_id);

  const roll = input.roll_expression?.trim()
    ? executeUniversalRoll({ expression: input.roll_expression.trim(), label: 'ROLAGEM PRIVADA (DM)' })
    : null;

  const message = {
    id: generateId('dm'),
    channel_id: channelId,
    sender_id: userId,
    sender_handle: senderHandle,
    sender_role: userRole,
    content: input.content.trim(),
    reply_to_id: null,
    reply_preview: null,
    dice_roll_json: roll ? JSON.stringify(roll) : null,
    created_at: new Date().toISOString(),
  };

  await repo.createChatMessage(message);

  await repo.createNotification({
    id: generateId('not'),
    user_id: input.peer_user_id,
    category: 'social',
    title: `DM de ${senderHandle}`,
    body: input.content.trim().slice(0, 80),
    action_payload_json: JSON.stringify({ dm_peer_id: userId }),
    is_read: 0,
    created_at: new Date().toISOString(),
  });

  return { ok: true, channel_id: channelId, message, dice_roll: roll };
}

export async function upsertCharacterUseCase(
  userId: string,
  input: z.infer<typeof charactersUpsertSchema>,
  repo: IArcanaRepository,
) {
  const campaign = await repo.findCampaignById(input.campaign_id);
  if (!campaign) {
    throw new AppError(
      404,
      'CAMPAIGN_NOT_FOUND',
      'Campanha obrigatoria para criar ou editar uma ficha de personagem.',
    );
  }
  const membership = await repo.findCampaignMember(campaign.id, userId);
  const isOwner = campaign.owner_id === userId;
  if (!isOwner && (!membership || membership.status !== 'active')) {
    throw new AppError(
      403,
      'CHARACTER_REQUIRES_ACTIVE_CAMPAIGN',
      'Personagens nao podem ser criados fora de uma mesa. Aguarde a aprovacao do Mestre.',
    );
  }

  // Regra Rígida: no máximo 1 personagem por jogador por campanha
  const existingChar = await repo.findCharacterByUserAndCampaign(userId, campaign.id);
  if (existingChar && input.id && input.id.trim() !== existingChar.id) {
    throw new AppError(
      409,
      'CHARACTER_LIMIT_PER_CAMPAIGN',
      `Limite atingido: Voce ja possui "${existingChar.name}" vinculado a esta campanha (maximo 1 personagem por mesa).`,
    );
  }
  const targetId = existingChar?.id ?? (input.id?.trim() || generateId('chr'));

  const existingSystems = await repo.listSystems();
  const safeSystemId = existingSystems.some((s) => s.id === input.system_id)
    ? input.system_id
    : 'sys_universal';

  const nowIso = new Date().toISOString();
  const character = {
    id: targetId,
    user_id: userId,
    campaign_id: campaign.id,
    name: input.name.trim(),
    title: input.title.trim(),
    system_id: safeSystemId,
    level: input.level,
    attributes_json: JSON.stringify({
      corpo: input.corpo,
      mente: input.mente,
      espirito: input.espirito,
      ...(input.custom_data?.attributes as Record<string, unknown> | undefined ?? {}),
    }),
    slots_json: JSON.stringify(input.slots),
    statuses_json: JSON.stringify({
      hp_current: input.hp_current,
      hp_max: input.hp_max,
      anima_current: input.anima_current,
      anima_max: input.anima_max,
      exhaustion: input.exhaustion,
      ...(input.custom_data ?? {}),
    }),
    updated_at: nowIso,
  };

  await repo.upsertCharacter(character);
  return { ok: true, character };
}
