import type {
  AccountStatus,
  CompendiumCategory,
  SceneModelType,
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
  suspended_until?: string | null;
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
  contacts_json?: string;
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

export interface SystemCreationKeyRecord {
  code: string;
  created_by: string;
  assigned_to_user_id: string | null;
  used_by_user_id: string | null;
  is_used: number;
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
  is_inactive_archived?: number;
  last_activity_at?: string;
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

export interface CampaignInviteRecord {
  id: string;
  campaign_id: string;
  target_user_id: string;
  invited_by_user_id: string;
  status: 'pending' | 'accepted' | 'declined';
  created_at: string;
}

export interface GmBanRecord {
  gm_id: string;
  player_id: string;
  reason: string;
  created_at: string;
  player_username?: string;
  player_display_name?: string;
}

export interface CampaignSceneRecord {
  id: string;
  campaign_id: string;
  name: string;
  description: string;
  model_type: SceneModelType;
  is_active: number;
  max_players: number;
  model_data_json: string;
  rules_data_json: string;
  state_data_json: string;
  created_at: string;
  updated_at: string;
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

export interface ForumCommentRecord {
  id: string;
  topic_id: string;
  author_id: string;
  author_handle: string;
  content: string;
  created_at: string;
}

export interface AnnouncementRecord {
  id: string;
  author_id: string;
  tag: string;
  title: string;
  summary: string;
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
  entity_type?: string;
  origin_id: string;
  reason_category: string;
  description: string;
  auto_tags_json: string;
  evidence_snapshot_json: string;
  votes_json?: string;
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

export interface AdminUserSummaryRecord {
  id: string;
  email: string;
  birth_date: string;
  role: UserRole;
  account_status: AccountStatus;
  suspended_until?: string | null;
  created_at: string;
  username: string;
  display_name: string;
}

export interface CampaignMemberDetailRecord extends CampaignMemberRecord {
  username?: string;
  display_name?: string;
}

export interface IArcanaRepository {
  findUserByGoogleSubOrEmail(googleSub: string, email: string): Promise<UserRecord | null>;
  findUserById(userId: string): Promise<UserRecord | null>;
  countRealUsers(): Promise<number>;
  createUserWithProfile(user: UserRecord, profile: UserProfileRecord): Promise<void>;
  updateUserRole(userId: string, role: UserRole): Promise<void>;
  updateUserBirthDate(userId: string, birthDate: string): Promise<void>;
  updateUserSuspension(userId: string, suspendedUntil: string | null): Promise<void>;
  updateUserStatusAndLockout(userId: string, status: AccountStatus, lockoutHash: string | null): Promise<void>;
  listUsersWithProfiles(): Promise<AdminUserSummaryRecord[]>;
  findProfileByUserId(userId: string): Promise<UserProfileRecord | null>;
  findProfileByUsername(username: string): Promise<UserProfileRecord | null>;
  updateProfile(profile: UserProfileRecord): Promise<void>;

  findDeviceSecurity(fingerprint: string): Promise<DeviceSecurityRecord | null>;
  findLatestDeviceByUserId(userId: string): Promise<DeviceSecurityRecord | null>;
  upsertDeviceSecurity(record: DeviceSecurityRecord): Promise<void>;
  listBannedDevices(): Promise<DeviceSecurityRecord[]>;

  createSession(session: SessionRecord): Promise<void>;
  findSessionByJti(jti: string): Promise<SessionRecord | null>;
  revokeSessionByJti(jti: string): Promise<void>;
  revokeAllUserSessions(userId: string): Promise<void>;

  listCampaigns(): Promise<CampaignRecord[]>;
  listCampaignMembershipsByUser(userId: string): Promise<CampaignMemberRecord[]>;
  listCampaignMembersByCampaign(campaignId: string): Promise<CampaignMemberDetailRecord[]>;
  findCampaignMember(campaignId: string, userId: string): Promise<CampaignMemberRecord | null>;
  findCampaignByCode(code: string): Promise<CampaignRecord | null>;
  findCampaignById(id: string): Promise<CampaignRecord | null>;
  createCampaign(campaign: CampaignRecord, ownerMembership: CampaignMemberRecord): Promise<void>;
  updateCampaign(campaign: CampaignRecord): Promise<void>;
  upsertCampaignMember(member: CampaignMemberRecord): Promise<void>;
  incrementCampaignOccupiedSlots(campaignId: string): Promise<void>;
  decrementCampaignOccupiedSlots(campaignId: string): Promise<void>;

  createCampaignInvite(invite: CampaignInviteRecord): Promise<void>;
  findCampaignInvite(inviteId: string): Promise<CampaignInviteRecord | null>;
  updateCampaignInviteStatus(inviteId: string, status: 'pending' | 'accepted' | 'declined'): Promise<void>;

  banPlayerFromGM(gmId: string, playerId: string, reason: string): Promise<void>;
  unbanPlayerFromGM(gmId: string, playerId: string): Promise<void>;
  isPlayerBannedByGM(gmId: string, playerId: string): Promise<boolean>;
  listGMBannedPlayers(gmId: string): Promise<GmBanRecord[]>;

  listScenesByCampaign(campaignId: string): Promise<CampaignSceneRecord[]>;
  findSceneById(sceneId: string): Promise<CampaignSceneRecord | null>;
  upsertScene(scene: CampaignSceneRecord): Promise<void>;
  deleteScene(sceneId: string): Promise<void>;

  listSystems(): Promise<SystemRecord[]>;
  createSystem(system: SystemRecord): Promise<void>;
  listCompendiumBySystem(systemId: string): Promise<CompendiumItemRecord[]>;
  findCompendiumItemById(itemId: string): Promise<CompendiumItemRecord | null>;
  upsertCompendiumItem(item: CompendiumItemRecord): Promise<void>;

  createSystemKey(record: SystemCreationKeyRecord): Promise<void>;
  findSystemKey(code: string): Promise<SystemCreationKeyRecord | null>;
  markSystemKeyUsed(code: string, usedByUserId: string): Promise<void>;
  listSystemKeys(): Promise<SystemCreationKeyRecord[]>;

  listFavoriteSystemIds(userId: string): Promise<string[]>;
  toggleFavoriteSystem(userId: string, systemId: string): Promise<string[]>;

  listGuilds(): Promise<GuildRecord[]>;
  createGuild(guild: GuildRecord): Promise<void>;
  updateGuild(guild: GuildRecord): Promise<void>;
  boostGuild(guildId: string, points: number): Promise<GuildRecord | null>;
  listForumTopics(): Promise<ForumTopicRecord[]>;
  createForumTopic(topic: ForumTopicRecord): Promise<void>;
  upvoteForumTopic(topicId: string, delta?: number): Promise<ForumTopicRecord | null>;
  listForumComments(topicId: string): Promise<ForumCommentRecord[]>;
  createForumComment(comment: ForumCommentRecord): Promise<void>;
  listAnnouncements(): Promise<AnnouncementRecord[]>;
  createAnnouncement(announcement: AnnouncementRecord): Promise<void>;

  listChatMessages(channelId: string): Promise<ChatMessageRecord[]>;
  findChatMessageById(messageId: string): Promise<ChatMessageRecord | null>;
  createChatMessage(message: ChatMessageRecord): Promise<void>;
  deleteChatMessage(messageId: string): Promise<void>;
  clearChatChannel(channelId: string): Promise<void>;

  listFriendships(userId: string): Promise<FriendshipRecord[]>;
  addFriendship(record: FriendshipRecord): Promise<void>;
  removeFriendship(userId: string, friendId: string): Promise<void>;
  listNotifications(userId: string): Promise<NotificationRecord[]>;
  createNotification(notification: NotificationRecord): Promise<void>;
  markNotificationsRead(userId: string, notificationId?: string): Promise<void>;

  listCharactersByUser(userId: string): Promise<CharacterRecord[]>;
  listCharactersByCampaign(campaignId: string): Promise<CharacterRecord[]>;
  findCharacterByUserAndCampaign(userId: string, campaignId: string): Promise<CharacterRecord | null>;
  upsertCharacter(character: CharacterRecord): Promise<void>;

  createReport(report: UniversalReportRecord): Promise<void>;
  listReports(): Promise<UniversalReportRecord[]>;
  findReportById(reportId: string): Promise<UniversalReportRecord | null>;
  updateReportVotes(reportId: string, votesJson: string, status?: 'pending' | 'resolved' | 'dismissed'): Promise<void>;
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
