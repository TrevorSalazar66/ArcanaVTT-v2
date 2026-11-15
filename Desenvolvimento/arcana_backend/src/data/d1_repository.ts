import type { D1Database } from '@cloudflare/workers-types';
import type {
  CampaignMemberRecord,
  CampaignRecord,
  ChatMessageRecord,
  CompendiumItemRecord,
  DeviceSecurityRecord,
  ForumTopicRecord,
  FriendshipRecord,
  GuildRecord,
  IArcanaRepository,
  NotificationRecord,
  P2pSignalRecord,
  SessionRecord,
  SystemRecord,
  UniversalReportRecord,
  UserProfileRecord,
  UserRecord,
} from './interfaces';
import type { AccountStatus } from '../types/env';

/**
 * Repositório de produção sobre Cloudflare D1 utilizando 100% Prepared Statements parametrizados.
 */
export class CloudflareD1Repository implements IArcanaRepository {
  constructor(private readonly db: D1Database) {}

  async findUserByGoogleSubOrEmail(
    googleSub: string,
    email: string,
  ): Promise<UserRecord | null> {
    return this.db
      .prepare('SELECT * FROM users WHERE google_sub = ?1 OR email = ?2 LIMIT 1')
      .bind(googleSub, email)
      .first<UserRecord>();
  }

  async findUserById(userId: string): Promise<UserRecord | null> {
    return this.db
      .prepare('SELECT * FROM users WHERE id = ?1 LIMIT 1')
      .bind(userId)
      .first<UserRecord>();
  }

  async createUserWithProfile(
    user: UserRecord,
    profile: UserProfileRecord,
  ): Promise<void> {
    await this.db.batch([
      this.db
        .prepare(
          `INSERT INTO users (id, google_sub, email, birth_date, role, account_status, lockout_token_hash, created_at, updated_at)
           VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)`,
        )
        .bind(
          user.id,
          user.google_sub,
          user.email,
          user.birth_date,
          user.role,
          user.account_status,
          user.lockout_token_hash,
          user.created_at,
          user.updated_at,
        ),
      this.db
        .prepare(
          `INSERT INTO user_profiles (user_id, username, display_name, bio, avatar_icon, preferred_role, reputation_points, theme_preference, font_scale, onboarding_completed, updated_at)
           VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)`,
        )
        .bind(
          profile.user_id,
          profile.username,
          profile.display_name,
          profile.bio,
          profile.avatar_icon,
          profile.preferred_role,
          profile.reputation_points,
          profile.theme_preference,
          profile.font_scale,
          profile.onboarding_completed,
          profile.updated_at,
        ),
    ]);
  }

  async updateUserStatusAndLockout(
    userId: string,
    status: AccountStatus,
    lockoutHash: string | null,
  ): Promise<void> {
    await this.db
      .prepare(
        'UPDATE users SET account_status = ?1, lockout_token_hash = ?2, updated_at = ?3 WHERE id = ?4',
      )
      .bind(status, lockoutHash, new Date().toISOString(), userId)
      .run();
  }

  async findProfileByUserId(userId: string): Promise<UserProfileRecord | null> {
    return this.db
      .prepare('SELECT * FROM user_profiles WHERE user_id = ?1 LIMIT 1')
      .bind(userId)
      .first<UserProfileRecord>();
  }

  async findProfileByUsername(username: string): Promise<UserProfileRecord | null> {
    return this.db
      .prepare('SELECT * FROM user_profiles WHERE username = ?1 LIMIT 1')
      .bind(username)
      .first<UserProfileRecord>();
  }

  async updateProfile(profile: UserProfileRecord): Promise<void> {
    await this.db
      .prepare(
        `UPDATE user_profiles
         SET username = ?1, display_name = ?2, bio = ?3, preferred_role = ?4,
             theme_preference = ?5, font_scale = ?6, onboarding_completed = ?7, updated_at = ?8
         WHERE user_id = ?9`,
      )
      .bind(
        profile.username,
        profile.display_name,
        profile.bio,
        profile.preferred_role,
        profile.theme_preference,
        profile.font_scale,
        profile.onboarding_completed,
        profile.updated_at,
        profile.user_id,
      )
      .run();
  }

  async findDeviceSecurity(
    fingerprint: string,
  ): Promise<DeviceSecurityRecord | null> {
    return this.db
      .prepare('SELECT * FROM device_security WHERE device_fingerprint = ?1 LIMIT 1')
      .bind(fingerprint)
      .first<DeviceSecurityRecord>();
  }

  async upsertDeviceSecurity(record: DeviceSecurityRecord): Promise<void> {
    await this.db
      .prepare(
        `INSERT INTO device_security (device_fingerprint, user_id, android_id_hash, is_trusted, is_hardware_banned, ban_reason, trusted_until, last_ip, updated_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
         ON CONFLICT(device_fingerprint) DO UPDATE SET
           user_id = excluded.user_id,
           is_trusted = excluded.is_trusted,
           is_hardware_banned = excluded.is_hardware_banned,
           ban_reason = excluded.ban_reason,
           trusted_until = excluded.trusted_until,
           last_ip = excluded.last_ip,
           updated_at = excluded.updated_at`,
      )
      .bind(
        record.device_fingerprint,
        record.user_id,
        record.android_id_hash,
        record.is_trusted,
        record.is_hardware_banned,
        record.ban_reason,
        record.trusted_until,
        record.last_ip,
        record.updated_at,
      )
      .run();
  }

  async createSession(session: SessionRecord): Promise<void> {
    await this.db
      .prepare(
        `INSERT INTO sessions (id, user_id, device_fingerprint, token_jti, expires_at, revoked, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)`,
      )
      .bind(
        session.id,
        session.user_id,
        session.device_fingerprint,
        session.token_jti,
        session.expires_at,
        session.revoked,
        session.created_at,
      )
      .run();
  }

  async findSessionByJti(jti: string): Promise<SessionRecord | null> {
    return this.db
      .prepare('SELECT * FROM sessions WHERE token_jti = ?1 LIMIT 1')
      .bind(jti)
      .first<SessionRecord>();
  }

  async revokeSessionByJti(jti: string): Promise<void> {
    await this.db
      .prepare('UPDATE sessions SET revoked = 1 WHERE token_jti = ?1')
      .bind(jti)
      .run();
  }

  async revokeAllUserSessions(userId: string): Promise<void> {
    await this.db
      .prepare('UPDATE sessions SET revoked = 1 WHERE user_id = ?1')
      .bind(userId)
      .run();
  }

  async listCampaigns(): Promise<CampaignRecord[]> {
    const res = await this.db
      .prepare('SELECT * FROM campaigns ORDER BY created_at DESC')
      .all<CampaignRecord>();
    return res.results;
  }

  async listCampaignMembershipsByUser(
    userId: string,
  ): Promise<CampaignMemberRecord[]> {
    const res = await this.db
      .prepare('SELECT * FROM campaign_members WHERE user_id = ?1')
      .bind(userId)
      .all<CampaignMemberRecord>();
    return res.results;
  }

  async findCampaignByCode(code: string): Promise<CampaignRecord | null> {
    return this.db
      .prepare('SELECT * FROM campaigns WHERE UPPER(quick_join_code) = UPPER(?1) LIMIT 1')
      .bind(code)
      .first<CampaignRecord>();
  }

  async findCampaignById(id: string): Promise<CampaignRecord | null> {
    return this.db
      .prepare('SELECT * FROM campaigns WHERE id = ?1 LIMIT 1')
      .bind(id)
      .first<CampaignRecord>();
  }

  async createCampaign(
    campaign: CampaignRecord,
    ownerMembership: CampaignMemberRecord,
  ): Promise<void> {
    await this.db.batch([
      this.db
        .prepare(
          `INSERT INTO campaigns (id, owner_id, title, synopsis, system_id, quick_join_code, mode, schedule_text, max_slots, occupied_slots, visibility, state_json, created_at)
           VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13)`,
        )
        .bind(
          campaign.id,
          campaign.owner_id,
          campaign.title,
          campaign.synopsis,
          campaign.system_id,
          campaign.quick_join_code,
          campaign.mode,
          campaign.schedule_text,
          campaign.max_slots,
          campaign.occupied_slots,
          campaign.visibility,
          campaign.state_json,
          campaign.created_at,
        ),
      this.db
        .prepare(
          `INSERT INTO campaign_members (campaign_id, user_id, table_role, status, application_pitch, character_id, joined_at)
           VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)`,
        )
        .bind(
          ownerMembership.campaign_id,
          ownerMembership.user_id,
          ownerMembership.table_role,
          ownerMembership.status,
          ownerMembership.application_pitch,
          ownerMembership.character_id,
          ownerMembership.joined_at,
        ),
    ]);
  }

  async upsertCampaignMember(member: CampaignMemberRecord): Promise<void> {
    await this.db
      .prepare(
        `INSERT INTO campaign_members (campaign_id, user_id, table_role, status, application_pitch, character_id, joined_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
         ON CONFLICT(campaign_id, user_id) DO UPDATE SET
           table_role = excluded.table_role,
           status = excluded.status,
           application_pitch = excluded.application_pitch`,
      )
      .bind(
        member.campaign_id,
        member.user_id,
        member.table_role,
        member.status,
        member.application_pitch,
        member.character_id,
        member.joined_at,
      )
      .run();
  }

  async incrementCampaignOccupiedSlots(campaignId: string): Promise<void> {
    await this.db
      .prepare('UPDATE campaigns SET occupied_slots = occupied_slots + 1 WHERE id = ?1')
      .bind(campaignId)
      .run();
  }

  async listSystems(): Promise<SystemRecord[]> {
    const res = await this.db
      .prepare('SELECT * FROM systems ORDER BY is_official DESC, downloads_count DESC')
      .all<SystemRecord>();
    return res.results;
  }

  async createSystem(system: SystemRecord): Promise<void> {
    await this.db
      .prepare(
        `INSERT INTO systems (id, author_id, name, version, category_type, dice_engine, description, rules_json, downloads_count, rating, is_official, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12)`,
      )
      .bind(
        system.id,
        system.author_id,
        system.name,
        system.version,
        system.category_type,
        system.dice_engine,
        system.description,
        system.rules_json,
        system.downloads_count,
        system.rating,
        system.is_official,
        system.created_at,
      )
      .run();
  }

  async listCompendiumBySystem(systemId: string): Promise<CompendiumItemRecord[]> {
    const res = await this.db
      .prepare('SELECT * FROM compendium_items WHERE system_id = ?1 ORDER BY name ASC')
      .bind(systemId)
      .all<CompendiumItemRecord>();
    return res.results;
  }

  async listGuilds(): Promise<GuildRecord[]> {
    const res = await this.db
      .prepare('SELECT * FROM guilds ORDER BY member_count DESC')
      .all<GuildRecord>();
    return res.results;
  }

  async listForumTopics(): Promise<ForumTopicRecord[]> {
    const res = await this.db
      .prepare('SELECT * FROM forum_topics ORDER BY pinned DESC, created_at DESC')
      .all<ForumTopicRecord>();
    return res.results;
  }

  async createForumTopic(topic: ForumTopicRecord): Promise<void> {
    await this.db
      .prepare(
        `INSERT INTO forum_topics (id, author_id, author_handle, category, title, content, upvotes, replies_count, pinned, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)`,
      )
      .bind(
        topic.id,
        topic.author_id,
        topic.author_handle,
        topic.category,
        topic.title,
        topic.content,
        topic.upvotes,
        topic.replies_count,
        topic.pinned,
        topic.created_at,
      )
      .run();
  }

  async upvoteForumTopic(topicId: string): Promise<ForumTopicRecord | null> {
    await this.db
      .prepare('UPDATE forum_topics SET upvotes = upvotes + 1 WHERE id = ?1')
      .bind(topicId)
      .run();
    return this.db
      .prepare('SELECT * FROM forum_topics WHERE id = ?1 LIMIT 1')
      .bind(topicId)
      .first<ForumTopicRecord>();
  }

  async listChatMessages(channelId: string): Promise<ChatMessageRecord[]> {
    const res = await this.db
      .prepare('SELECT * FROM chat_messages WHERE channel_id = ?1 ORDER BY created_at ASC')
      .bind(channelId)
      .all<ChatMessageRecord>();
    return res.results;
  }

  async findChatMessageById(messageId: string): Promise<ChatMessageRecord | null> {
    return this.db
      .prepare('SELECT * FROM chat_messages WHERE id = ?1 LIMIT 1')
      .bind(messageId)
      .first<ChatMessageRecord>();
  }

  async createChatMessage(message: ChatMessageRecord): Promise<void> {
    await this.db
      .prepare(
        `INSERT INTO chat_messages (id, channel_id, sender_id, sender_handle, sender_role, content, reply_to_id, reply_preview, dice_roll_json, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)`,
      )
      .bind(
        message.id,
        message.channel_id,
        message.sender_id,
        message.sender_handle,
        message.sender_role,
        message.content,
        message.reply_to_id,
        message.reply_preview,
        message.dice_roll_json,
        message.created_at,
      )
      .run();
  }

  async listFriendships(userId: string): Promise<FriendshipRecord[]> {
    const res = await this.db
      .prepare(
        `SELECT f.*, up.username AS friend_username, up.display_name AS friend_display_name
         FROM friendships f
         LEFT JOIN user_profiles up ON up.user_id = f.friend_id
         WHERE f.user_id = ?1`,
      )
      .bind(userId)
      .all<FriendshipRecord>();
    return res.results;
  }

  async listNotifications(userId: string): Promise<NotificationRecord[]> {
    const res = await this.db
      .prepare('SELECT * FROM notifications WHERE user_id = ?1 ORDER BY created_at DESC')
      .bind(userId)
      .all<NotificationRecord>();
    return res.results;
  }

  async markNotificationsRead(userId: string, notificationId?: string): Promise<void> {
    if (notificationId) {
      await this.db
        .prepare('UPDATE notifications SET is_read = 1 WHERE user_id = ?1 AND id = ?2')
        .bind(userId, notificationId)
        .run();
      return;
    }
    await this.db
      .prepare('UPDATE notifications SET is_read = 1 WHERE user_id = ?1')
      .bind(userId)
      .run();
  }

  async createReport(report: UniversalReportRecord): Promise<void> {
    await this.db
      .prepare(
        `INSERT INTO universal_reports (id, reporter_id, target_user_id, origin_type, origin_id, reason_category, description, auto_tags_json, evidence_snapshot_json, status, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11)`,
      )
      .bind(
        report.id,
        report.reporter_id,
        report.target_user_id,
        report.origin_type,
        report.origin_id,
        report.reason_category,
        report.description,
        report.auto_tags_json,
        report.evidence_snapshot_json,
        report.status,
        report.created_at,
      )
      .run();
  }

  async listReports(): Promise<UniversalReportRecord[]> {
    const res = await this.db
      .prepare('SELECT * FROM universal_reports ORDER BY created_at DESC')
      .all<UniversalReportRecord>();
    return res.results;
  }

  async updateReportStatus(
    reportId: string,
    status: 'resolved' | 'dismissed',
  ): Promise<void> {
    await this.db
      .prepare('UPDATE universal_reports SET status = ?1 WHERE id = ?2')
      .bind(status, reportId)
      .run();
  }

  async createP2pSignal(signal: P2pSignalRecord): Promise<void> {
    await this.db
      .prepare(
        `INSERT INTO p2p_signals (id, campaign_id, leader_user_id, from_peer_id, to_peer_id, signal_type, payload_json, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)`,
      )
      .bind(
        signal.id,
        signal.campaign_id,
        signal.leader_user_id,
        signal.from_peer_id,
        signal.to_peer_id,
        signal.signal_type,
        signal.payload_json,
        signal.created_at,
      )
      .run();
  }

  async listP2pPresenceByCampaign(campaignId: string): Promise<P2pSignalRecord[]> {
    const res = await this.db
      .prepare(
        "SELECT * FROM p2p_signals WHERE campaign_id = ?1 AND signal_type = 'presence' ORDER BY created_at DESC",
      )
      .bind(campaignId)
      .all<P2pSignalRecord>();
    return res.results;
  }

  async listMetricsSummary(): Promise<{
    users_count: number;
    campaigns_count: number;
    pending_reports_count: number;
    banned_devices_count: number;
  }> {
    const users = await this.db.prepare('SELECT COUNT(*) AS total FROM users').first<{ total: number }>();
    const campaigns = await this.db.prepare('SELECT COUNT(*) AS total FROM campaigns').first<{ total: number }>();
    const reports = await this.db
      .prepare("SELECT COUNT(*) AS total FROM universal_reports WHERE status = 'pending'")
      .first<{ total: number }>();
    const bans = await this.db
      .prepare('SELECT COUNT(*) AS total FROM device_security WHERE is_hardware_banned = 1')
      .first<{ total: number }>();

    return {
      users_count: users?.total ?? 0,
      campaigns_count: campaigns?.total ?? 0,
      pending_reports_count: reports?.total ?? 0,
      banned_devices_count: bans?.total ?? 0,
    };
  }
}

