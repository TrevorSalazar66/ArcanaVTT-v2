import type { IArcanaRepository } from '../../data/interfaces';

export async function getSocialOverviewUseCase(
  userId: string,
  repo: IArcanaRepository,
) {
  const [friends, notifications] = await Promise.all([
    repo.listFriendships(userId),
    repo.listNotifications(userId),
  ]);

  return {
    ok: true,
    friends,
    notifications,
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

