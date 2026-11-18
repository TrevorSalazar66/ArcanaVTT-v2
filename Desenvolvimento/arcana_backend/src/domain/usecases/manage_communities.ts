import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import { assertRole } from '../../middlewares/auth_middleware';
import { AppError } from '../../middlewares/error_handler';
import type {
  chatSendMessageSchema,
  communitiesOverviewSchema,
  forumCreateTopicSchema,
  guildsBoostSchema,
  guildsCreateSchema,
} from '../../schemas/sync_schemas';
import type { AuthenticatedUser } from '../../types/env';
import { generateId } from '../../utils/crypto_jwt';

/**
 * Executa rolagem justa de 3d6 usando WebCrypto getRandomValues.
 */
export function roll3d6Engine(label = 'TESTE GERAL (3D6)'): {
  label: string;
  dice: [number, number, number];
  successes: number;
  outcome: string;
} {
  const bytes = new Uint8Array(3);
  crypto.getRandomValues(bytes);
  const d1 = ((bytes[0] ?? 0) % 6) + 1;
  const d2 = ((bytes[1] ?? 0) % 6) + 1;
  const d3 = ((bytes[2] ?? 0) % 6) + 1;
  const dice: [number, number, number] = [d1, d2, d3];
  const successes = dice.filter((value) => value >= 5).length;

  let outcome = 'Falha';
  if (d1 === 6 && d2 === 6 && d3 === 6) {
    outcome = 'Sucesso Critico!';
  } else if (d1 === 1 && d2 === 1 && d3 === 1) {
    outcome = 'Falha Critica';
  } else if (successes > 0) {
    outcome = successes === 1 ? '1 Sucesso' : `${successes} Sucessos!`;
  }

  return { label: label.toUpperCase(), dice, successes, outcome };
}

export async function getCommunitiesOverviewUseCase(
  input: z.infer<typeof communitiesOverviewSchema>,
  repo: IArcanaRepository,
) {
  const [guilds, forumTopics, messages] = await Promise.all([
    repo.listGuilds(),
    repo.listForumTopics(),
    repo.listChatMessages(input.channel_id),
  ]);

  const announcements = [
    {
      id: 'ann_v24',
      title: 'AlphaD6 Core v2.4 homologado para mesas competitivas',
      tag: 'OFICIAL',
      summary: 'Nova tabela de reserva de Anima e 12 slots de inventario.',
      published_at: '2026-01-15T10:00:00.000Z',
    },
    {
      id: 'ann_p2p',
      title: 'Sincronizacao P2P com Eleicao Dinamica de Lider ativa',
      tag: 'INFRA',
      summary: 'Zero latencia extra em celulares Android em sessoes cooperativas.',
      published_at: '2026-01-12T15:00:00.000Z',
    },
  ];

  return {
    ok: true,
    channel_id: input.channel_id,
    announcements,
    guilds,
    forum_topics: forumTopics,
    messages,
  };
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
  repo: IArcanaRepository,
) {
  const updated = await repo.upvoteForumTopic(topicId);
  if (!updated) {
    throw new AppError(404, 'TOPIC_NOT_FOUND', 'Topico nao localizado.');
  }
  return { ok: true, topic: updated };
}

export async function sendChatMessageUseCase(
  authUser: AuthenticatedUser,
  input: z.infer<typeof chatSendMessageSchema>,
  repo: IArcanaRepository,
) {
  const profile = await repo.findProfileByUserId(authUser.userId);
  const senderHandle = profile
    ? `@${profile.username}`
    : `@${authUser.email.split('@')[0] ?? 'heroi'}`;

  let replyPreview: string | null = null;
  if (input.reply_to_id) {
    const parent = await repo.findChatMessageById(input.reply_to_id);
    if (parent) {
      replyPreview = `${parent.sender_handle}: ${parent.content.slice(0, 48)}`;
    }
  }

  const diceRoll = input.with_3d6_roll
    ? roll3d6Engine(input.roll_label ?? 'ROLAGEM NA TAVERNA (3D6)')
    : null;

  const message = {
    id: generateId('msg'),
    channel_id: input.channel_id,
    sender_id: authUser.userId,
    sender_handle: senderHandle,
    sender_role: authUser.role,
    content: input.content,
    reply_to_id: input.reply_to_id ?? null,
    reply_preview: replyPreview,
    dice_roll_json: diceRoll ? JSON.stringify(diceRoll) : null,
    created_at: new Date().toISOString(),
  };

  await repo.createChatMessage(message);
  return { ok: true, message, dice_roll: diceRoll };
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
    }),
    created_at: new Date().toISOString(),
  };

  await repo.createGuild(guild);
  return { ok: true, guild };
}

export async function boostGuildUseCase(
  input: z.infer<typeof guildsBoostSchema>,
  repo: IArcanaRepository,
) {
  const updated = await repo.boostGuild(input.guild_id, input.points);
  if (!updated) {
    throw new AppError(404, 'GUILD_NOT_FOUND', 'Guilda nao localizada.');
  }
  return { ok: true, guild: updated };
}

