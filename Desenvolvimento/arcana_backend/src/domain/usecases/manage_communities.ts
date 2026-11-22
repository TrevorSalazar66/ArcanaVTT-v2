import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import { assertRole } from '../../middlewares/auth_middleware';
import { AppError } from '../../middlewares/error_handler';
import type {
  announcementsCreateSchema,
  chatModerateActionCardSchema,
  chatSendMessageSchema,
  communitiesOverviewSchema,
  forumCommentSchema,
  forumCreateTopicSchema,
  guildsBoostSchema,
  guildsCreateSchema,
  guildsUpdateWorldSchema,
} from '../../schemas/sync_schemas';
import type { AuthenticatedUser } from '../../types/env';
import { generateId } from '../../utils/crypto_jwt';
import { executeUniversalRoll, parseChatCommand } from './universal_rpg_engine';

function guildBenefitsForLevel(level: number) {
  return {
    level,
    max_members: 20 + (level - 1) * 20,
    max_masters: 2 + (level - 1) * 2,
    max_channels: 2 + level,
    max_clans: 1 + (level - 1) * 2,
    max_custom_roles: 3 + (level - 1) * 3,
  };
}

export async function getCommunitiesOverviewUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof communitiesOverviewSchema>,
  repo: IArcanaRepository,
) {
  if (input.channel_id.startsWith('dm:')) {
    throw new AppError(403, 'FORBIDDEN_DM_CHANNEL', 'Use o modulo privado de DMs para conversar 1-a-1.');
  }

  const [guilds, forumTopics, rawMessages, announcements] = await Promise.all([
    repo.listGuilds(),
    repo.listForumTopics(),
    repo.listChatMessages(input.channel_id),
    repo.listAnnouncements(),
  ]);

  const isPlatformAdmin = authUser.role === 'admin' || authUser.role === 'superadmin';
  const userProfile = await repo.findProfileByUserId(authUser.userId);
  const myHandle = userProfile?.username.toLowerCase() ?? '';

  const messages = rawMessages.filter((m) => {
    if (!m.dice_roll_json) return true;
    try {
      const meta = JSON.parse(m.dice_roll_json) as Record<string, unknown>;
      if (meta.msg_type === 'whisper') {
        const target = String(meta.whisper_target ?? '').toLowerCase();
        return m.sender_id === authUser.userId || target === myHandle || isPlatformAdmin;
      }
      if (meta.msg_type === 'gmroll') {
        return (
          m.sender_id === authUser.userId ||
          authUser.role === 'mestre' ||
          isPlatformAdmin
        );
      }
      return true;
    } catch {
      return true;
    }
  });

  return {
    ok: true,
    channel_id: input.channel_id,
    announcements,
    guilds,
    forum_topics: forumTopics,
    messages,
  };
}

export async function createAnnouncementUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof announcementsCreateSchema>,
  repo: IArcanaRepository,
) {
  assertRole(authUser.role, ['admin', 'superadmin']);
  const ann = {
    id: generateId('ann'),
    author_id: authUser.userId,
    tag: input.tag.trim().toUpperCase(),
    title: input.title.trim(),
    summary: input.summary.trim(),
    created_at: new Date().toISOString(),
  };
  await repo.createAnnouncement(ann);
  return { ok: true, announcement: ann };
}

export async function createForumTopicUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof forumCreateTopicSchema>,
  repo: IArcanaRepository,
) {
  const profile = await repo.findProfileByUserId(authUser.userId);
  const handle = profile ? `@${profile.username}` : `@${authUser.email.split('@')[0] ?? 'heroi'}`;
  const topic = {
    id: generateId('top'),
    author_id: authUser.userId,
    author_handle: handle,
    category: input.category,
    title: input.title,
    content: input.content,
    upvotes: 1,
    replies_count: 0,
    pinned: 0,
    created_at: new Date().toISOString(),
  };

  await repo.createForumTopic(topic);
  return { ok: true, topic };
}

export async function upvoteForumTopicUseCase(
  topicId: string,
  delta: number,
  repo: IArcanaRepository,
) {
  const updated = await repo.upvoteForumTopic(topicId, delta);
  if (!updated) {
    throw new AppError(404, 'TOPIC_NOT_FOUND', 'Topico nao localizado.');
  }
  return { ok: true, topic: updated };
}

export async function getForumTopicDetailUseCase(
  topicId: string,
  repo: IArcanaRepository,
) {
  const [topics, comments] = await Promise.all([
    repo.listForumTopics(),
    repo.listForumComments(topicId),
  ]);
  const topic = topics.find((t) => t.id === topicId);
  if (!topic) throw new AppError(404, 'TOPIC_NOT_FOUND', 'Topico nao localizado.');
  return { ok: true, topic, comments };
}

export async function createForumCommentUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof forumCommentSchema>,
  repo: IArcanaRepository,
) {
  const profile = await repo.findProfileByUserId(authUser.userId);
  const handle = profile ? `@${profile.username}` : '@heroi';
  const comment = {
    id: generateId('cmt'),
    topic_id: input.topic_id,
    author_id: authUser.userId,
    author_handle: handle,
    content: input.content.trim(),
    created_at: new Date().toISOString(),
  };
  await repo.createForumComment(comment);
  const comments = await repo.listForumComments(input.topic_id);
  return { ok: true, comment, comments };
}

export async function sendChatMessageUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof chatSendMessageSchema>,
  repo: IArcanaRepository,
) {
  if (input.channel_id.startsWith('dm:')) {
    throw new AppError(403, 'FORBIDDEN_DM_CHANNEL', 'Use dm.send_message para mensagens diretas 1-a-1.');
  }

  const profile = await repo.findProfileByUserId(authUser.userId);
  const senderHandle = profile
    ? `@${profile.username}`
    : `@${authUser.email.split('@')[0] ?? 'heroi'}`;

  let effectiveRole: string = authUser.role;
  let autoApprove = false;
  if (input.campaign_id) {
    const campaign = await repo.findCampaignById(input.campaign_id);
    if (campaign) {
      const mem = await repo.findCampaignMember(campaign.id, authUser.userId);
      if (campaign.owner_id === authUser.userId) effectiveRole = 'mestre';
      else if (mem?.table_role) effectiveRole = mem.table_role;
      try {
        const st = JSON.parse(campaign.state_json) as Record<string, unknown>;
        autoApprove = Boolean(st.auto_approve_actions);
      } catch {
        autoApprove = false;
      }
    }
  }

  let replyPreview: string | null = null;
  if (input.reply_to_id) {
    const parent = await repo.findChatMessageById(input.reply_to_id);
    if (parent) {
      replyPreview = `${parent.sender_handle}: ${parent.content.slice(0, 48)}`;
    }
  }

  const parsedCmd = parseChatCommand(input.content, senderHandle, effectiveRole);

  let rollData = parsedCmd.rollResult;
  if (!rollData && input.with_3d6_roll) {
    rollData = executeUniversalRoll({
      expression: input.roll_expression?.trim() || '3d6',
      label: input.roll_label ?? 'ROLAGEM NA TAVERNA',
    });
  }

  let finalActionCard = parsedCmd.actionCard;
  if (finalActionCard && autoApprove) {
    finalActionCard = { ...finalActionCard, status: 'approved' };
  }

  const metadata: Record<string, unknown> = {
    ...(rollData ?? {}),
    msg_type: parsedCmd.msgType === 'ic' && input.persona !== 'ic' ? input.persona : parsedCmd.msgType,
    persona: input.persona,
    ...(parsedCmd.npcName || input.npc_name
      ? { npc_name: parsedCmd.npcName ?? input.npc_name }
      : {}),
    ...(parsedCmd.whisperTargetHandle ? { whisper_target: parsedCmd.whisperTargetHandle } : {}),
    ...(finalActionCard ? { action_card: finalActionCard } : {}),
  };

  const hasMeta =
    Boolean(rollData) ||
    metadata.msg_type !== 'ic' ||
    input.persona !== 'ic' ||
    Boolean(finalActionCard);

  const message = {
    id: generateId('msg'),
    channel_id: input.channel_id,
    sender_id: authUser.userId,
    sender_handle: senderHandle,
    sender_role: authUser.role,
    content: parsedCmd.cleanContent,
    reply_to_id: input.reply_to_id ?? null,
    reply_preview: replyPreview,
    dice_roll_json: hasMeta ? JSON.stringify(metadata) : null,
    created_at: new Date().toISOString(),
  };

  await repo.createChatMessage(message);
  return { ok: true, message, dice_roll: rollData ?? null };
}

export async function moderateChatActionCardUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof chatModerateActionCardSchema>,
  repo: IArcanaRepository,
) {
  const campaign = await repo.findCampaignById(input.campaign_id);
  if (!campaign) throw new AppError(404, 'CAMPAIGN_NOT_FOUND', 'Campanha nao encontrada.');
  const member = await repo.findCampaignMember(campaign.id, authUser.userId);
  const canModerate =
    campaign.owner_id === authUser.userId ||
    member?.table_role === 'assistente_mestre' ||
    authUser.role === 'admin' ||
    authUser.role === 'superadmin';
  if (!canModerate) {
    throw new AppError(403, 'FORBIDDEN_TABLE_MASTER', 'Apenas Mestre ou Auxiliar pode aprovar acoes.');
  }

  const msg = await repo.findChatMessageById(input.message_id);
  if (!msg) throw new AppError(404, 'MESSAGE_NOT_FOUND', 'Mensagem nao localizada.');

  let meta: Record<string, unknown> = {};
  try {
    meta = JSON.parse(msg.dice_roll_json ?? '{}') as Record<string, unknown>;
  } catch {
    meta = {};
  }
  const card = (meta.action_card as Record<string, unknown> | undefined) ?? {};
  card.status = input.decision;
  meta.action_card = card;

  if (input.decision === 'approved' && Number(card.hours_advance ?? 0) > 0) {
    try {
      const cmpState = JSON.parse(campaign.state_json) as Record<string, unknown>;
      const clock = (cmpState.world_clock as Record<string, unknown> | undefined) ?? {
        hour: 8,
        day: 1,
        month: 1,
        year: 1,
      };
      const curHour = Number(clock.hour ?? 8) + Number(card.hours_advance ?? 0);
      clock.day = Number(clock.day ?? 1) + Math.floor(curHour / 24);
      clock.hour = curHour % 24;
      cmpState.world_clock = clock;
      await repo.updateCampaign({
        ...campaign,
        state_json: JSON.stringify(cmpState),
        last_activity_at: new Date().toISOString(),
      });
    } catch {
      // ignora erro de parse
    }
  }

  await repo.deleteChatMessage(msg.id);
  const updatedMsg = {
    ...msg,
    dice_roll_json: JSON.stringify(meta),
    content: `${msg.content} [${input.decision === 'approved' ? 'APROVADO' : 'RECUSADO'}]`,
  };
  await repo.createChatMessage(updatedMsg);
  return { ok: true, message: updatedMsg };
}

export async function deleteChatMessageUseCase(
  authUser: AuthenticatedUser,
  messageId: string,
  campaignId: string | undefined,
  repo: IArcanaRepository,
) {
  const msg = await repo.findChatMessageById(messageId);
  if (!msg) throw new AppError(404, 'MESSAGE_NOT_FOUND', 'Mensagem nao localizada.');

  let isTableMaster = false;
  if (campaignId) {
    const cmp = await repo.findCampaignById(campaignId);
    isTableMaster = cmp?.owner_id === authUser.userId;
  }

  if (
    msg.sender_id !== authUser.userId &&
    !isTableMaster &&
    authUser.role !== 'admin' &&
    authUser.role !== 'superadmin'
  ) {
    throw new AppError(403, 'FORBIDDEN', 'Sem permissao para apagar esta mensagem.');
  }
  await repo.deleteChatMessage(messageId);
  return { ok: true, deleted_id: messageId };
}

export async function clearChatChannelUseCase(
  authUser: AuthenticatedUser,
  channelId: string,
  campaignId: string,
  repo: IArcanaRepository,
) {
  const cmp = await repo.findCampaignById(campaignId);
  if (!cmp) throw new AppError(404, 'CAMPAIGN_NOT_FOUND', 'Campanha nao encontrada.');
  if (cmp.owner_id !== authUser.userId && authUser.role !== 'superadmin') {
    throw new AppError(403, 'FORBIDDEN_TABLE_MASTER', 'Apenas o Mestre dono da mesa pode limpar o historico.');
  }
  await repo.clearChatChannel(channelId);
  return { ok: true, channel_id: channelId };
}

export async function createGuildUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof guildsCreateSchema>,
  repo: IArcanaRepository,
) {
  assertRole(authUser.role, ['mestre', 'admin', 'superadmin']);
  const cleanTag = input.tag.replace(/[^A-Za-z0-9]/g, '').toUpperCase().slice(0, 8);
  if (cleanTag.length < 2) {
    throw new AppError(400, 'INVALID_GUILD_TAG', 'A tag da guilda precisa ter pelo menos 2 caracteres.');
  }

  const existing = await repo.listGuilds();
  if (existing.some((g) => g.tag.toUpperCase() === cleanTag)) {
    throw new AppError(409, 'GUILD_TAG_TAKEN', `A tag [${cleanTag}] ja esta em uso.`);
  }

  const benefits = guildBenefitsForLevel(1);
  const guild = {
    id: generateId('gld'),
    leader_id: authUser.userId,
    name: input.name.trim(),
    tag: cleanTag,
    description: input.description.trim(),
    member_count: 1,
    active_tables_count: 0,
    boost_points: 0,
    boost_goal: 1000,
    shared_world_json: JSON.stringify({
      world: input.shared_world_name.trim(),
      season: input.current_season.trim(),
      ...benefits,
      clans: [],
      wiki: [],
      channels: ['#taverna-guilda', '#world-wiki'],
    }),
    created_at: new Date().toISOString(),
  };

  await repo.createGuild(guild);
  return { ok: true, guild };
}

/**
 * Guild Boost real com subida automática de Nível (1 a 5) e desbloqueio de limites.
 */
export async function boostGuildUseCase(
  input: z.infer<typeof guildsBoostSchema>,
  repo: IArcanaRepository,
) {
  const all = await repo.listGuilds();
  const current = all.find((g) => g.id === input.guild_id);
  if (!current) {
    throw new AppError(404, 'GUILD_NOT_FOUND', 'Guilda nao localizada.');
  }

  let worldObj: Record<string, unknown> = {};
  try {
    worldObj = JSON.parse(current.shared_world_json) as Record<string, unknown>;
  } catch {
    worldObj = {};
  }

  let level = Number(worldObj.level ?? 1);
  let boostPoints = current.boost_points + input.points;
  let boostGoal = current.boost_goal;

  while (boostPoints >= boostGoal && level < 5) {
    boostPoints -= boostGoal;
    level += 1;
    boostGoal += 500;
  }
  if (level >= 5 && boostPoints > boostGoal) {
    boostPoints = boostGoal;
  }

  const nextWorld = {
    ...worldObj,
    ...guildBenefitsForLevel(level),
  };

  const updated = {
    ...current,
    boost_points: boostPoints,
    boost_goal: boostGoal,
    shared_world_json: JSON.stringify(nextWorld),
  };

  await repo.updateGuild(updated);
  return { ok: true, guild: updated, leveled_up_to: level };
}

export async function updateGuildWorldUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof guildsUpdateWorldSchema>,
  repo: IArcanaRepository,
) {
  const all = await repo.listGuilds();
  const current = all.find((g) => g.id === input.guild_id);
  if (!current) throw new AppError(404, 'GUILD_NOT_FOUND', 'Guilda nao localizada.');
  if (
    current.leader_id !== authUser.userId &&
    authUser.role !== 'mestre' &&
    authUser.role !== 'admin' &&
    authUser.role !== 'superadmin'
  ) {
    throw new AppError(403, 'FORBIDDEN', 'Apenas o Anfitriao ou Mestres autorizados editam a World Wiki / Clas.');
  }

  let prevWorld: Record<string, unknown> = {};
  try {
    prevWorld = JSON.parse(current.shared_world_json) as Record<string, unknown>;
  } catch {
    prevWorld = {};
  }

  const updated = {
    ...current,
    shared_world_json: JSON.stringify({ ...prevWorld, ...input.world_patch }),
  };
  await repo.updateGuild(updated);
  return { ok: true, guild: updated };
}
