import { z } from 'zod';

const compendiumCategorySchema = z.enum([
  'itens',
  'equipamentos',
  'seres',
  'poderes',
  'pistas',
]);

const sceneModelSchema = z.enum([
  'grid_2d',
  'mahjong',
  'password',
  'dialogue',
  'jrpg_combat',
  'terminal',
]);

export const profileSetupSchema = z.object({
  action: z.literal('profile.setup'),
  username: z
    .string()
    .regex(/^[a-z0-9_]{3,24}$/, 'Username deve ter 3-24 caracteres minusculos/numeros/_'),
  display_name: z.string().min(2).max(60),
  birth_date: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/, 'Data deve ser YYYY-MM-DD')
    .optional(),
  bio: z.string().max(500).default(''),
  avatar_icon: z.string().max(40).optional(),
  contacts: z
    .object({
      discord: z.string().max(60).optional(),
      twitch: z.string().max(60).optional(),
      youtube: z.string().max(80).optional(),
      steam: z.string().max(60).optional(),
      instagram: z.string().max(60).optional(),
      x_twitter: z.string().max(60).optional(),
      reddit: z.string().max(60).optional(),
      whatsapp: z.string().max(30).optional(),
    })
    .optional(),
  theme_preference: z
    .enum(['escuro_heraldico', 'oled', 'alto_contraste_solar'])
    .optional(),
  font_scale: z.number().min(0.8).max(1.5).optional(),
});

export const campaignsListSchema = z.object({
  action: z.literal('campaigns.list'),
  filter: z.enum(['jogando', 'auxiliar', 'mestre', 'explorar', 'todas']).default('todas'),
  search: z.string().max(100).optional(),
});

export const campaignsLookupCodeSchema = z.object({
  action: z.literal('campaigns.lookup_code'),
  code: z.string().min(4).max(8),
});

export const campaignsQuickJoinSchema = z.object({
  action: z.literal('campaigns.quick_join'),
  code: z.string().min(6).max(8),
});

export const campaignsCreateSchema = z.object({
  action: z.literal('campaigns.create'),
  title: z.string().min(3).max(80),
  synopsis: z.string().min(10).max(500),
  system_id: z.string().min(3).max(64).default('sys_universal'),
  mode: z.enum(['ao_vivo', 'tempo_livre', 'agendada']).default('ao_vivo'),
  schedule_text: z.string().min(2).max(60).default('Tempo Livre'),
  max_slots: z.number().int().min(1).max(12).default(5),
  visibility: z.enum(['publica', 'privada', 'guilda']).default('publica'),
  icon_name: z.string().max(40).default('swords'),
  banner_preset: z.string().max(160).default('cidadela_obsidiana'),
  age_rating: z.enum(['Livre', '14+', '16+', '18+']).default('16+'),
  tags: z.array(z.string().max(24)).max(8).default([]),
});

export const campaignsApplySchema = z.object({
  action: z.literal('campaigns.apply'),
  campaign_id: z.string().min(3).max(64),
  pitch: z.string().min(5).max(200),
});

export const campaignsInvitePlayerSchema = z.object({
  action: z.literal('campaigns.invite_player'),
  campaign_id: z.string().min(3).max(64),
  target_user_id: z.string().min(3).max(64),
});

export const campaignsAcceptInviteSchema = z.object({
  action: z.literal('campaigns.accept_invite'),
  invite_id: z.string().min(3).max(64),
  accept: z.boolean().default(true),
});

export const campaignsLeaveSchema = z.object({
  action: z.literal('campaigns.leave'),
  campaign_id: z.string().min(3).max(64),
});

export const campaignsListMembersSchema = z.object({
  action: z.literal('campaigns.list_members'),
  campaign_id: z.string().min(3).max(64),
});

export const campaignsManageMemberSchema = z.object({
  action: z.literal('campaigns.manage_member'),
  campaign_id: z.string().min(3).max(64),
  target_user_id: z.string().min(3).max(64),
  status: z.enum(['active', 'rejected', 'kicked', 'banned']).optional(),
  table_role: z.enum(['jogador', 'assistente_mestre']).optional(),
  ban_reason: z.string().max(200).optional(),
});

export const campaignsListBannedSchema = z.object({
  action: z.literal('campaigns.list_banned'),
});

export const campaignsUnbanPlayerSchema = z.object({
  action: z.literal('campaigns.unban_player'),
  player_id: z.string().min(3).max(64),
});

export const campaignsUpdateSettingsSchema = z.object({
  action: z.literal('campaigns.update_settings'),
  campaign_id: z.string().min(3).max(64),
  title: z.string().min(3).max(80).optional(),
  synopsis: z.string().min(10).max(500).optional(),
  visibility: z.enum(['publica', 'privada', 'guilda']).optional(),
  mode: z.enum(['ao_vivo', 'tempo_livre', 'agendada']).optional(),
  schedule_text: z.string().max(60).optional(),
  state_patch: z.record(z.string(), z.unknown()).optional(),
  reactivate_75d: z.boolean().optional(),
});

export const campaignsListCharactersSchema = z.object({
  action: z.literal('campaigns.list_characters'),
  campaign_id: z.string().min(3).max(64),
});

export const scenesListSchema = z.object({
  action: z.literal('scenes.list'),
  campaign_id: z.string().min(3).max(64),
});

export const scenesUpsertSchema = z.object({
  action: z.literal('scenes.upsert'),
  id: z.string().max(64).optional(),
  campaign_id: z.string().min(3).max(64),
  name: z.string().min(2).max(80),
  description: z.string().max(500).default(''),
  model_type: sceneModelSchema,
  is_active: z.boolean().default(false),
  max_players: z.number().int().min(1).max(12).default(12),
  model_data: z.record(z.string(), z.unknown()).default({}),
  rules_data: z.array(z.record(z.string(), z.unknown())).default([]),
  state_data: z.record(z.string(), z.unknown()).default({}),
});

export const scenesDeleteSchema = z.object({
  action: z.literal('scenes.delete'),
  campaign_id: z.string().min(3).max(64),
  scene_id: z.string().min(3).max(64),
});

export const scenesTriggerSchema = z.object({
  action: z.literal('scenes.trigger'),
  campaign_id: z.string().min(3).max(64),
  scene_id: z.string().min(3).max(64),
  character_id: z.string().max(64).optional(),
  trigger_type: z.string().min(2).max(64),
  params: z.record(z.string(), z.unknown()).default({}),
});

export const systemsListSchema = z.object({
  action: z.literal('systems.list'),
  segment: z.enum(['oficiais', 'proprios', 'meus', 'comunidade', 'todos']).default('todos'),
  search: z.string().max(100).optional(),
});

export const systemsCreateSchema = z.object({
  action: z.literal('systems.create'),
  name: z.string().min(3).max(80),
  version: z.string().min(1).max(20).default('v1.0'),
  dice_engine: z.string().min(2).max(32).default('universal'),
  description: z.string().min(10).max(500),
  attributes: z.array(z.string().min(2).max(30)).min(1).max(12),
  creation_key: z.string().max(40).optional(),
  is_official: z.boolean().default(false),
  rules_config: z.record(z.string(), z.unknown()).optional(),
});

export const systemsToggleFavoriteSchema = z.object({
  action: z.literal('systems.toggle_favorite'),
  system_id: z.string().min(3).max(64),
});

export const compendiumQuerySchema = z.object({
  action: z.literal('compendium.query'),
  system_id: z.string().min(3).max(64),
  category: compendiumCategorySchema.optional(),
  search: z.string().max(100).optional(),
});

export const compendiumUpsertSchema = z.object({
  action: z.literal('compendium.upsert'),
  id: z.string().max(64).optional(),
  system_id: z.string().min(3).max(64),
  campaign_id: z.string().max(64).optional(),
  parent_id: z.string().max(64).optional(),
  category: compendiumCategorySchema,
  name: z.string().min(2).max(80),
  rarity: z.string().max(40).default('Comum'),
  slots_weight: z.number().int().min(0).max(50).default(1),
  description: z.string().min(2).max(600),
  is_all_hidden: z.boolean().default(false),
  base_asset_id: z.string().max(60).default('shield'),
  equip_slot: z.string().max(40).optional(),
  blocks: z.record(z.string(), z.record(z.string(), z.unknown())).default({}),
  delta_changes: z.record(z.string(), z.unknown()).optional(),
});

export const communitiesOverviewSchema = z.object({
  action: z.literal('communities.overview'),
  channel_id: z.string().min(2).max(64).default('taverna-dos-mestres'),
});

export const announcementsCreateSchema = z.object({
  action: z.literal('announcements.create'),
  tag: z.string().min(2).max(24).default('OFICIAL'),
  title: z.string().min(4).max(120),
  summary: z.string().min(6).max(500),
});

export const forumCreateTopicSchema = z.object({
  action: z.literal('forum.create_topic'),
  category: z.string().min(2).max(40),
  title: z.string().min(5).max(120),
  content: z.string().min(10).max(1500),
});

export const forumUpvoteSchema = z.object({
  action: z.literal('forum.upvote'),
  topic_id: z.string().min(3).max(64),
  delta: z.number().int().min(-1).max(1).default(1),
});

export const forumGetTopicSchema = z.object({
  action: z.literal('forum.get_topic'),
  topic_id: z.string().min(3).max(64),
});

export const forumCommentSchema = z.object({
  action: z.literal('forum.comment'),
  topic_id: z.string().min(3).max(64),
  content: z.string().min(2).max(1000),
});

export const chatSendMessageSchema = z.object({
  action: z.literal('chat.send_message'),
  channel_id: z.string().min(2).max(80).default('taverna-dos-mestres'),
  content: z.string().min(1).max(600),
  reply_to_id: z.string().max(64).optional(),
  roll_label: z.string().max(60).optional(),
  with_3d6_roll: z.boolean().default(false),
  roll_expression: z.string().max(64).optional(),
  persona: z.enum(['ic', 'ooc', 'narrador', 'npc']).default('ic'),
  npc_name: z.string().max(60).optional(),
  campaign_id: z.string().max(64).optional(),
});

export const chatModerateActionCardSchema = z.object({
  action: z.literal('chat.moderate_action_card'),
  campaign_id: z.string().min(3).max(64),
  message_id: z.string().min(3).max(64),
  decision: z.enum(['approved', 'rejected']),
});

export const chatDeleteMessageSchema = z.object({
  action: z.literal('chat.delete_message'),
  message_id: z.string().min(3).max(64),
  campaign_id: z.string().max(64).optional(),
});

export const chatClearChannelSchema = z.object({
  action: z.literal('chat.clear_channel'),
  channel_id: z.string().min(2).max(80),
  campaign_id: z.string().min(3).max(64),
});

export const rpgRollUniversalSchema = z.object({
  action: z.literal('rpg.roll_universal'),
  expression: z.string().min(2).max(64),
  label: z.string().max(80).optional(),
  difficulty: z.number().int().min(1).max(50).optional(),
  opposed_expression: z.string().max(64).optional(),
});

export const guildsCreateSchema = z.object({
  action: z.literal('guilds.create'),
  name: z.string().min(3).max(60),
  tag: z.string().min(2).max(8),
  description: z.string().min(6).max(300),
  shared_world_name: z.string().min(2).max(60).default('Mundo Compartilhado'),
  current_season: z.string().min(2).max(60).default('Temporada I'),
});

export const guildsBoostSchema = z.object({
  action: z.literal('guilds.boost'),
  guild_id: z.string().min(3).max(64),
  points: z.number().int().min(10).max(5000).default(50),
});

export const guildsUpdateWorldSchema = z.object({
  action: z.literal('guilds.update_world'),
  guild_id: z.string().min(3).max(64),
  world_patch: z.record(z.string(), z.unknown()),
});

export const socialOverviewSchema = z.object({
  action: z.literal('social.overview'),
});

export const socialGetProfileSchema = z.object({
  action: z.literal('social.get_profile'),
  user_id: z.string().max(64).optional(),
  username: z.string().max(32).optional(),
});

export const socialAddFriendSchema = z.object({
  action: z.literal('social.add_friend'),
  username: z.string().min(3).max(32),
});

export const socialRespondFriendSchema = z.object({
  action: z.literal('social.respond_friend'),
  friend_user_id: z.string().min(3).max(64),
  decision: z.enum(['accept', 'reject', 'remove', 'block']),
});

export const dmListMessagesSchema = z.object({
  action: z.literal('dm.list_messages'),
  peer_user_id: z.string().min(3).max(64),
});

export const dmSendMessageSchema = z.object({
  action: z.literal('dm.send_message'),
  peer_user_id: z.string().min(3).max(64),
  content: z.string().min(1).max(600),
  roll_expression: z.string().max(64).optional(),
});

export const charactersUpsertSchema = z.object({
  action: z.literal('characters.upsert'),
  id: z.string().max(64).optional(),
  campaign_id: z.string().min(3).max(64),
  name: z.string().min(2).max(60),
  title: z.string().min(2).max(60),
  system_id: z.string().min(3).max(64).default('sys_universal'),
  level: z.number().int().min(1).max(99).default(1),
  corpo: z.number().int().min(0).max(20).default(2),
  mente: z.number().int().min(0).max(20).default(2),
  espirito: z.number().int().min(0).max(20).default(2),
  hp_current: z.number().int().min(0).max(999).default(20),
  hp_max: z.number().int().min(1).max(999).default(20),
  anima_current: z.number().int().min(0).max(999).default(10),
  anima_max: z.number().int().min(1).max(999).default(10),
  exhaustion: z.number().int().min(0).max(10).default(0),
  slots: z.array(z.string().max(120)).max(24).default([]),
  custom_data: z.record(z.string(), z.unknown()).optional(),
});

export const notificationsMarkReadSchema = z.object({
  action: z.literal('notifications.mark_read'),
  notification_id: z.string().max(64).optional(),
});

export const reportSubmitSchema = z.object({
  action: z.literal('report.submit'),
  origin_type: z.enum([
    'chat',
    'dm',
    'campanha',
    'usuario',
    'ficha_personagem',
    'compendio',
    'sistema',
    'homebrew',
    'guilda',
    'cla',
    'forum',
    'wiki',
  ]),
  origin_id: z.string().min(2).max(80),
  target_user_id: z.string().max(64).optional(),
  reason_category: z.string().min(3).max(60),
  description: z.string().min(10).max(600),
  context_session: z.string().max(64).default('sessao_hub'),
});

export const adminOverviewSchema = z.object({
  action: z.literal('admin.overview'),
});

export const adminUpdateRoleSchema = z.object({
  action: z.literal('admin.update_role'),
  target_user_id: z.string().min(3).max(64),
  role: z.enum(['jogador', 'mestre', 'admin']),
});

export const adminModerateSchema = z.object({
  action: z.literal('admin.moderate'),
  report_id: z.string().min(3).max(64),
  decision: z.enum([
    'resolved',
    'dismissed',
    'warning',
    'unpublish',
    'suspend_24h',
    'suspend_7d',
    'suspend_30d',
    'hardware_ban',
  ]),
  ban_device_fingerprint: z.string().max(128).optional(),
  ban_reason: z.string().max(200).optional(),
});

export const adminUnbanDeviceSchema = z.object({
  action: z.literal('admin.unban_device'),
  device_fingerprint: z.string().min(4).max(128),
});

export const adminGenerateCreationKeySchema = z.object({
  action: z.literal('admin.generate_creation_key'),
  assigned_to_user_id: z.string().max(64).optional(),
});

export const adminAuditDmsSchema = z.object({
  action: z.literal('admin.audit_dms'),
  user_a: z.string().min(3).max(64),
  user_b: z.string().min(3).max(64),
});

export const syncPresenceSchema = z.object({
  action: z.literal('sync.presence'),
  campaign_id: z.string().min(3).max(64),
  peer_id: z.string().min(3).max(64),
  latency_ms: z.number().int().min(1).max(5000).default(42),
  battery_pct: z.number().int().min(1).max(100).default(85),
});

export const syncSignalSchema = z.object({
  action: z.literal('sync.signal'),
  campaign_id: z.string().min(3).max(64),
  from_peer_id: z.string().min(3).max(64),
  to_peer_id: z.string().min(3).max(64),
  signal_type: z.enum(['offer', 'answer', 'ice_candidate']),
  payload_json: z.string().min(2).max(4096),
});

export const syncPayloadSchema = z.discriminatedUnion('action', [
  profileSetupSchema,
  campaignsListSchema,
  campaignsLookupCodeSchema,
  campaignsQuickJoinSchema,
  campaignsCreateSchema,
  campaignsApplySchema,
  campaignsInvitePlayerSchema,
  campaignsAcceptInviteSchema,
  campaignsLeaveSchema,
  campaignsListMembersSchema,
  campaignsManageMemberSchema,
  campaignsListBannedSchema,
  campaignsUnbanPlayerSchema,
  campaignsUpdateSettingsSchema,
  campaignsListCharactersSchema,
  scenesListSchema,
  scenesUpsertSchema,
  scenesDeleteSchema,
  scenesTriggerSchema,
  systemsListSchema,
  systemsCreateSchema,
  systemsToggleFavoriteSchema,
  compendiumQuerySchema,
  compendiumUpsertSchema,
  communitiesOverviewSchema,
  announcementsCreateSchema,
  forumCreateTopicSchema,
  forumUpvoteSchema,
  forumGetTopicSchema,
  forumCommentSchema,
  chatSendMessageSchema,
  chatModerateActionCardSchema,
  chatDeleteMessageSchema,
  chatClearChannelSchema,
  rpgRollUniversalSchema,
  guildsCreateSchema,
  guildsBoostSchema,
  guildsUpdateWorldSchema,
  socialOverviewSchema,
  socialGetProfileSchema,
  socialAddFriendSchema,
  socialRespondFriendSchema,
  dmListMessagesSchema,
  dmSendMessageSchema,
  charactersUpsertSchema,
  notificationsMarkReadSchema,
  reportSubmitSchema,
  adminOverviewSchema,
  adminUpdateRoleSchema,
  adminModerateSchema,
  adminUnbanDeviceSchema,
  adminGenerateCreationKeySchema,
  adminAuditDmsSchema,
  syncPresenceSchema,
  syncSignalSchema,
]);

export type SyncPayload = z.infer<typeof syncPayloadSchema>;
