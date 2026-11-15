import { z } from 'zod';

const compendiumCategorySchema = z.enum([
  'itens',
  'equipamentos',
  'seres',
  'poderes',
  'pistas',
]);

export const profileSetupSchema = z.object({
  action: z.literal('profile.setup'),
  username: z
    .string()
    .regex(/^[a-z0-9_]{3,24}$/, 'Username deve ter 3-24 caracteres minusculos/numeros/_'),
  display_name: z.string().min(2).max(60),
  bio: z.string().max(280).default(''),
  preferred_role: z.string().min(2).max(40).optional(),
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

export const campaignsQuickJoinSchema = z.object({
  action: z.literal('campaigns.quick_join'),
  code: z.string().min(6).max(8),
});

export const campaignsCreateSchema = z.object({
  action: z.literal('campaigns.create'),
  title: z.string().min(3).max(80),
  synopsis: z.string().min(10).max(500),
  system_id: z.string().min(3).max(64).default('sys_alphad6_v24'),
  mode: z.enum(['ao_vivo', 'tempo_livre', 'agendada']).default('ao_vivo'),
  schedule_text: z.string().min(2).max(60).default('Tempo Livre'),
  max_slots: z.number().int().min(1).max(12).default(5),
  visibility: z.enum(['publica', 'privada', 'guilda']).default('publica'),
});

export const campaignsApplySchema = z.object({
  action: z.literal('campaigns.apply'),
  campaign_id: z.string().min(3).max(64),
  character_name: z.string().min(2).max(60),
  pitch: z.string().min(5).max(300),
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
  dice_engine: z.string().min(2).max(20).default('3d6'),
  description: z.string().min(10).max(500),
  attributes: z.array(z.string().min(2).max(30)).min(1).max(8),
});

export const compendiumQuerySchema = z.object({
  action: z.literal('compendium.query'),
  system_id: z.string().min(3).max(64).default('sys_alphad6_v24'),
  category: compendiumCategorySchema.optional(),
  search: z.string().max(100).optional(),
});

export const communitiesOverviewSchema = z.object({
  action: z.literal('communities.overview'),
  channel_id: z.string().min(2).max(64).default('taverna-dos-mestres'),
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
});

export const chatSendMessageSchema = z.object({
  action: z.literal('chat.send_message'),
  channel_id: z.string().min(2).max(64).default('taverna-dos-mestres'),
  content: z.string().min(1).max(600),
  reply_to_id: z.string().max(64).optional(),
  roll_label: z.string().max(60).optional(),
  with_3d6_roll: z.boolean().default(false),
});

export const guildsCreateSchema = z.object({
  action: z.literal('guilds.create'),
  name: z.string().min(3).max(60),
  tag: z.string().min(2).max(8),
  description: z.string().min(6).max(300),
  shared_world_name: z.string().min(2).max(60).default('Continente de Valen'),
  current_season: z.string().min(2).max(60).default('Temporada I'),
});

export const guildsBoostSchema = z.object({
  action: z.literal('guilds.boost'),
  guild_id: z.string().min(3).max(64),
  points: z.number().int().min(10).max(500).default(50),
});

export const socialOverviewSchema = z.object({
  action: z.literal('social.overview'),
});

export const socialAddFriendSchema = z.object({
  action: z.literal('social.add_friend'),
  username: z.string().min(3).max(32),
});

export const charactersUpsertSchema = z.object({
  action: z.literal('characters.upsert'),
  id: z.string().max(64).optional(),
  campaign_id: z.string().max(64).nullable().optional(),
  name: z.string().min(2).max(60),
  title: z.string().min(2).max(60),
  system_id: z.string().min(3).max(64).default('sys_alphad6_v24'),
  level: z.number().int().min(1).max(99).default(1),
  corpo: z.number().int().min(1).max(20).default(3),
  mente: z.number().int().min(1).max(20).default(3),
  espirito: z.number().int().min(1).max(20).default(3),
  hp_current: z.number().int().min(0).max(999).default(20),
  hp_max: z.number().int().min(1).max(999).default(20),
  anima_current: z.number().int().min(0).max(999).default(10),
  anima_max: z.number().int().min(1).max(999).default(10),
  exhaustion: z.number().int().min(0).max(10).default(0),
  slots: z.array(z.string().max(120)).max(12).default([]),
});

export const notificationsMarkReadSchema = z.object({
  action: z.literal('notifications.mark_read'),
  notification_id: z.string().max(64).optional(),
});

export const reportSubmitSchema = z.object({
  action: z.literal('report.submit'),
  origin_type: z.enum(['chat', 'campanha', 'usuario', 'sistema', 'forum']),
  origin_id: z.string().min(2).max(80),
  target_user_id: z.string().max(64).optional(),
  reason_category: z.string().min(3).max(60),
  description: z.string().min(10).max(600),
  context_session: z.string().max(64).default('sessao_hub'),
});

export const adminOverviewSchema = z.object({
  action: z.literal('admin.overview'),
});

export const adminModerateSchema = z.object({
  action: z.literal('admin.moderate'),
  report_id: z.string().min(3).max(64),
  decision: z.enum(['resolved', 'dismissed', 'hardware_ban']),
  ban_device_fingerprint: z.string().max(128).optional(),
  ban_reason: z.string().max(200).optional(),
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
  campaignsQuickJoinSchema,
  campaignsCreateSchema,
  campaignsApplySchema,
  systemsListSchema,
  systemsCreateSchema,
  compendiumQuerySchema,
  communitiesOverviewSchema,
  guildsCreateSchema,
  guildsBoostSchema,
  forumCreateTopicSchema,
  forumUpvoteSchema,
  chatSendMessageSchema,
  socialOverviewSchema,
  socialAddFriendSchema,
  charactersUpsertSchema,
  notificationsMarkReadSchema,
  reportSubmitSchema,
  adminOverviewSchema,
  adminModerateSchema,
  syncPresenceSchema,
  syncSignalSchema,
]);

export type SyncPayload = z.infer<typeof syncPayloadSchema>;

