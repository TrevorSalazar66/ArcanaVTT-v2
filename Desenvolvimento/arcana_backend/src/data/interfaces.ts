import type {
  AccountStatus,
  CompendiumCategory,
  ThemePreference,
  UserRole,
} from '../types/env';

export interface UserRecord {
  id: string;
  google_sub: string;
  email: string;
  birth_date: string;
  role: UserRole;
  account_status: AccountStatus;
  lockout_token_hash: string | null;
  created_at: string;
  updated_at: string;
}

export interface UserProfileRecord {
  user_id: string;
  username: string;
  display_name: string;
  bio: string;
  avatar_icon: string;
  preferred_role: string;
  reputation_points: number;
  theme_preference: ThemePreference;
  font_scale: number;
  onboarding_completed: number;
  updated_at: string;
}

export interface DeviceSecurityRecord {
  device_fingerprint: string;
  user_id: string | null;
  android_id_hash: string;
  is_trusted: number;
  is_hardware_banned: number;
  ban_reason: string | null;
  trusted_until: string | null;
  last_ip: string | null;
  updated_at: string;
}

export interface SessionRecord {
  id: string;
  user_id: string;
  device_fingerprint: string;
  token_jti: string;
  expires_at: string;
  revoked: number;
  created_at: string;
}

export interface SystemRecord {
  id: string;
  author_id: string;
  name: string;
  version: string;
  category_type: 'oficiais' | 'proprios' | 'meus' | 'comunidade';
  dice_engine: string;
  description: string;
  rules_json: string;
  downloads_count: number;
  rating: number;
  is_official: number;
  created_at: string;
}

export interface CampaignRecord {
  id: string;
  owner_id: string;
  title: string;
  synopsis: string;
  system_id: string;
  quick_join_code: string;
  mode: 'ao_vivo' | 'tempo_livre' | 'agendada';
  schedule_text: string;
  max_slots: number;
  occupied_slots: number;
  visibility: 'publica' | 'privada' | 'guilda';
  state_json: string;
  created_at: string;
}

export interface CampaignMemberRecord {
  campaign_id: string;
  user_id: string;
  table_role: 'jogador' | 'assistente_mestre' | 'mestre';
  status: 'pending' | 'active' | 'rejected';
  application_pitch: string | null;
  character_id: string | null;
  joined_at: string;
}

export interface CompendiumItemRecord {
  id: string;
  system_id: string;
  campaign_id: string | null;
  category: CompendiumCategory;
  name: string;
  rarity: string;
  slots_weight: number;
  description: string;
  properties_json: string;
  created_at: string;
}

export interface GuildRecord {
  id: string;
  leader_id: string;
  name: string;
  tag: string;
  description: string;
  member_count: number;
  active_tables_count: number;
  boost_points: number;
  boost_goal: number;
  shared_world_json: string;
  created_at: string;
}

export interface ForumTopicRecord {
  id: string;
  author_id: string;
  author_handle: string;
  category: string;
  title: string;
  content: string;
  upvotes: number;
  replies_count: number;
  pinned: number;
  created_at: string;
}

export interface ChatMessageRecord {
  id: string;
  channel_id: string;
  sender_id: string;
  sender_handle: string;
  sender_role: string;
  content: string;
  reply_to_id: string | null;
  reply_preview: string | null;
  dice_roll_json: string | null;
  created_at: string;
}

export interface NotificationRecord {
  id: string;
  user_id: string;
  category: 'mesas' | 'social' | 'sistema';
  title: string;
  body: string;
  action_payload_json: string;
  is_read: number;
  created_at: string;
}

export interface FriendshipRecord {
  user_id: string;
  friend_id: string;
  friend_username?: string;
  friend_display_name?: string;
  status: 'pending' | 'accepted' | 'blocked';
  presence_status: 'online' | 'em_mesa' | 'ausente' | 'offline';
  presence_activity: string;
  updated_at: string;
}

export interface UniversalReportRecord {
  id: string;
  reporter_id: string;
  target_user_id: string | null;
  origin_type: 'chat' | 'campanha' | 'usuario' | 'sistema' | 'forum';
  origin_id: string;
  reason_category: string;
  description: string;
  auto_tags_json: string;
  evidence_snapshot_json: string;
  status: 'pending' | 'resolved' | 'dismissed';
  created_at: string;
}

export interface P2pSignalRecord {
  id: string;
  campaign_id: string;
  leader_user_id: string;
  from_peer_id: string;
  to_peer_id: string;
  signal_type: 'presence' | 'offer' | 'answer' | 'ice_candidate';
  payload_json: string;
  created_at: string;
}

export interface CharacterRecord {
  id: string;
  user_id: string;
  campaign_id: string | null;
  name: string;
  title: string;
  system_id: string;
  level: number;
  attributes_json: string;
  slots_json: string;
  statuses_json: string;
  updated_at: string;
}

export interface IArcanaRepository {
  findUserByGoogleSubOrEmail(googleSub: string, email: string): Promise<UserRecord | null>;
  findUserById(userId: string): Promise<UserRecord | null>;
  countRealUsers(): Promise<number>;
  createUserWithProfile(user: UserRecord, profile: UserProfileRecord): Promise<void>;
  updateUserRole(userId: string, role: UserRole): Promise<void>;
  updateUserStatusAndLockout(userId: string, status: AccountStatus, lockoutHash: string | null): Promise<void>;
  findProfileByUserId(userId: string): Promise<UserProfileRecord | null>;
  findProfileByUsername(username: string): Promise<UserProfileRecord | null>;
  updateProfile(profile: UserProfileRecord): Promise<void>;

  findDeviceSecurity(fingerprint: string): Promise<DeviceSecurityRecord | null>;
  upsertDeviceSecurity(record: DeviceSecurityRecord): Promise<void>;

  createSession(session: SessionRecord): Promise<void>;
  findSessionByJti(jti: string): Promise<SessionRecord | null>;
  revokeSessionByJti(jti: string): Promise<void>;
  revokeAllUserSessions(userId: string): Promise<void>;

  listCampaigns(): Promise<CampaignRecord[]>;
  listCampaignMembershipsByUser(userId: string): Promise<CampaignMemberRecord[]>;
  findCampaignByCode(code: string): Promise<CampaignRecord | null>;
  findCampaignById(id: string): Promise<CampaignRecord | null>;
  createCampaign(campaign: CampaignRecord, ownerMembership: CampaignMemberRecord): Promise<void>;
  upsertCampaignMember(member: CampaignMemberRecord): Promise<void>;
  incrementCampaignOccupiedSlots(campaignId: string): Promise<void>;

  listSystems(): Promise<SystemRecord[]>;
  createSystem(system: SystemRecord): Promise<void>;
  listCompendiumBySystem(systemId: string): Promise<CompendiumItemRecord[]>;

  listGuilds(): Promise<GuildRecord[]>;
  createGuild(guild: GuildRecord): Promise<void>;
  boostGuild(guildId: string, points: number): Promise<GuildRecord | null>;
  listForumTopics(): Promise<ForumTopicRecord[]>;
  createForumTopic(topic: ForumTopicRecord): Promise<void>;
  upvoteForumTopic(topicId: string): Promise<ForumTopicRecord | null>;
  listChatMessages(channelId: string): Promise<ChatMessageRecord[]>;
  findChatMessageById(messageId: string): Promise<ChatMessageRecord | null>;
  createChatMessage(message: ChatMessageRecord): Promise<void>;

  listFriendships(userId: string): Promise<FriendshipRecord[]>;
  addFriendship(record: FriendshipRecord): Promise<void>;
  listNotifications(userId: string): Promise<NotificationRecord[]>;
  createNotification(notification: NotificationRecord): Promise<void>;
  markNotificationsRead(userId: string, notificationId?: string): Promise<void>;

  listCharactersByUser(userId: string): Promise<CharacterRecord[]>;
  upsertCharacter(character: CharacterRecord): Promise<void>;

  createReport(report: UniversalReportRecord): Promise<void>;
  listReports(): Promise<UniversalReportRecord[]>;
  updateReportStatus(reportId: string, status: 'resolved' | 'dismissed'): Promise<void>;

  createP2pSignal(signal: P2pSignalRecord): Promise<void>;
  listP2pPresenceByCampaign(campaignId: string): Promise<P2pSignalRecord[]>;
  listMetricsSummary(): Promise<{
    users_count: number;
    campaigns_count: number;
    pending_reports_count: number;
    banned_devices_count: number;
  }>;
}

