import type { z } from 'zod';
import type { IArcanaRepository } from '../../data/interfaces';
import { AppError } from '../../middlewares/error_handler';
import type {
  charactersUpsertSchema,
  socialAddFriendSchema,
} from '../../schemas/sync_schemas';
import { generateId } from '../../utils/crypto_jwt';

export async function getSocialOverviewUseCase(
  userId: string,
  repo: IArcanaRepository,
) {
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
  const cleanHandle = input.username
    .replace(/^@+/, '')
    .trim()
    .toLowerCase();

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
    throw new AppError(
      400,
      'SELF_FRIEND_INVALID',
      'Voce nao pode adicionar a si mesmo como aliado.',
    );
  }

  const nowIso = new Date().toISOString();
  const friendship = {
    user_id: userId,
    friend_id: targetProfile.user_id,
    friend_username: targetProfile.username,
    friend_display_name: targetProfile.display_name,
    status: 'accepted' as const,
    presence_status: 'online' as const,
    presence_activity: 'Na Taverna',
    updated_at: nowIso,
  };

  await repo.addFriendship(friendship);

  await repo.createNotification({
    id: generateId('not'),
    user_id: targetProfile.user_id,
    category: 'social',
    title: 'Novo Aliado na Taverna',
    body: `@${requesterProfile?.username ?? 'aventureiro'} adicionou voce como aliado.`,
    action_payload_json: JSON.stringify({ friend_user_id: userId }),
    is_read: 0,
    created_at: nowIso,
  });

  return { ok: true, friendship };
}

export async function upsertCharacterUseCase(
  userId: string,
  input: z.infer<typeof charactersUpsertSchema>,
  repo: IArcanaRepository,
) {
  const nowIso = new Date().toISOString();
  const character = {
    id: input.id && input.id.trim().length > 0 ? input.id.trim() : generateId('chr'),
    user_id: userId,
    campaign_id: input.campaign_id ?? null,
    name: input.name.trim(),
    title: input.title.trim(),
    system_id: input.system_id,
    level: input.level,
    attributes_json: JSON.stringify({
      corpo: input.corpo,
      mente: input.mente,
      espirito: input.espirito,
    }),
    slots_json: JSON.stringify(input.slots),
    statuses_json: JSON.stringify({
      hp_current: input.hp_current,
      hp_max: input.hp_max,
      anima_current: input.anima_current,
      anima_max: input.anima_max,
      exhaustion: input.exhaustion,
    }),
    updated_at: nowIso,
  };

  await repo.upsertCharacter(character);
  return { ok: true, character };
}

