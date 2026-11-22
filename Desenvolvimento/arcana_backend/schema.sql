-- ArcanaVTT — Schema D1 (SQLite Edge) Limpo & Motor Universal Agnóstico
-- Zero sistemas de RPG pré-cadastrados/hardcoded; compatível com `wrangler d1 migrations apply`.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  google_sub TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  birth_date TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'jogador' CHECK (role IN ('jogador', 'assistente_mestre', 'mestre', 'admin', 'superadmin')),
  account_status TEXT NOT NULL DEFAULT 'active' CHECK (account_status IN ('active', 'locked', 'banned')),
  suspended_until TEXT,
  lockout_token_hash TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS user_profiles (
  user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  username TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  bio TEXT NOT NULL DEFAULT '',
  avatar_icon TEXT NOT NULL DEFAULT 'crown',
  preferred_role TEXT NOT NULL DEFAULT 'jogador',
  contacts_json TEXT NOT NULL DEFAULT '{}',
  reputation_points INTEGER NOT NULL DEFAULT 100,
  theme_preference TEXT NOT NULL DEFAULT 'escuro_heraldico' CHECK (theme_preference IN ('escuro_heraldico', 'oled', 'alto_contraste_solar')),
  font_scale REAL NOT NULL DEFAULT 1.0,
  onboarding_completed INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS device_security (
  device_fingerprint TEXT PRIMARY KEY,
  user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
  android_id_hash TEXT NOT NULL,
  is_trusted INTEGER NOT NULL DEFAULT 0,
  is_hardware_banned INTEGER NOT NULL DEFAULT 0,
  ban_reason TEXT,
  trusted_until TEXT,
  last_ip TEXT,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_fingerprint TEXT NOT NULL,
  token_jti TEXT NOT NULL UNIQUE,
  expires_at TEXT NOT NULL,
  revoked INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS systems (
  id TEXT PRIMARY KEY,
  author_id TEXT NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  version TEXT NOT NULL,
  category_type TEXT NOT NULL CHECK (category_type IN ('oficiais', 'proprios', 'meus', 'comunidade')),
  dice_engine TEXT NOT NULL DEFAULT 'universal',
  description TEXT NOT NULL,
  rules_json TEXT NOT NULL,
  downloads_count INTEGER NOT NULL DEFAULT 0,
  rating REAL NOT NULL DEFAULT 5.0,
  is_official INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS system_creation_keys (
  code TEXT PRIMARY KEY,
  created_by TEXT NOT NULL REFERENCES users(id),
  assigned_to_user_id TEXT,
  used_by_user_id TEXT,
  is_used INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS system_favorites (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  system_id TEXT NOT NULL REFERENCES systems(id) ON DELETE CASCADE,
  created_at TEXT NOT NULL,
  PRIMARY KEY (user_id, system_id)
);

CREATE TABLE IF NOT EXISTS campaigns (
  id TEXT PRIMARY KEY,
  owner_id TEXT NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  synopsis TEXT NOT NULL,
  system_id TEXT NOT NULL REFERENCES systems(id),
  quick_join_code TEXT NOT NULL UNIQUE,
  mode TEXT NOT NULL DEFAULT 'ao_vivo' CHECK (mode IN ('ao_vivo', 'tempo_livre', 'agendada')),
  schedule_text TEXT NOT NULL DEFAULT 'Tempo Livre',
  max_slots INTEGER NOT NULL DEFAULT 5,
  occupied_slots INTEGER NOT NULL DEFAULT 1,
  visibility TEXT NOT NULL DEFAULT 'publica' CHECK (visibility IN ('publica', 'privada', 'guilda')),
  state_json TEXT NOT NULL DEFAULT '{}',
  is_inactive_archived INTEGER NOT NULL DEFAULT 0,
  last_activity_at TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS campaign_members (
  campaign_id TEXT NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  table_role TEXT NOT NULL CHECK (table_role IN ('jogador', 'assistente_mestre', 'mestre')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('pending', 'active', 'rejected')),
  application_pitch TEXT,
  character_id TEXT,
  joined_at TEXT NOT NULL,
  PRIMARY KEY (campaign_id, user_id)
);

CREATE TABLE IF NOT EXISTS campaign_invites (
  id TEXT PRIMARY KEY,
  campaign_id TEXT NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  target_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  invited_by_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS gm_banned_players (
  gm_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  player_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  PRIMARY KEY (gm_id, player_id)
);

CREATE TABLE IF NOT EXISTS campaign_scenes (
  id TEXT PRIMARY KEY,
  campaign_id TEXT NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  model_type TEXT NOT NULL CHECK (model_type IN ('grid_2d', 'mahjong', 'password', 'dialogue', 'jrpg_combat', 'terminal')),
  is_active INTEGER NOT NULL DEFAULT 0,
  max_players INTEGER NOT NULL DEFAULT 12,
  model_data_json TEXT NOT NULL DEFAULT '{}',
  rules_data_json TEXT NOT NULL DEFAULT '[]',
  state_data_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS characters (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  campaign_id TEXT REFERENCES campaigns(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  title TEXT NOT NULL,
  system_id TEXT NOT NULL REFERENCES systems(id),
  level INTEGER NOT NULL DEFAULT 1,
  attributes_json TEXT NOT NULL,
  slots_json TEXT NOT NULL,
  statuses_json TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS compendium_items (
  id TEXT PRIMARY KEY,
  system_id TEXT NOT NULL REFERENCES systems(id) ON DELETE CASCADE,
  campaign_id TEXT REFERENCES campaigns(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('itens', 'equipamentos', 'seres', 'poderes', 'pistas')),
  name TEXT NOT NULL,
  rarity TEXT NOT NULL DEFAULT 'Comum',
  slots_weight INTEGER NOT NULL DEFAULT 1,
  description TEXT NOT NULL,
  properties_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS guilds (
  id TEXT PRIMARY KEY,
  leader_id TEXT NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  tag TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  member_count INTEGER NOT NULL DEFAULT 1,
  active_tables_count INTEGER NOT NULL DEFAULT 0,
  boost_points INTEGER NOT NULL DEFAULT 0,
  boost_goal INTEGER NOT NULL DEFAULT 1000,
  shared_world_json TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS forum_topics (
  id TEXT PRIMARY KEY,
  author_id TEXT NOT NULL REFERENCES users(id),
  author_handle TEXT NOT NULL,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  upvotes INTEGER NOT NULL DEFAULT 1,
  replies_count INTEGER NOT NULL DEFAULT 0,
  pinned INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS forum_comments (
  id TEXT PRIMARY KEY,
  topic_id TEXT NOT NULL REFERENCES forum_topics(id) ON DELETE CASCADE,
  author_id TEXT NOT NULL REFERENCES users(id),
  author_handle TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS announcements (
  id TEXT PRIMARY KEY,
  author_id TEXT NOT NULL REFERENCES users(id),
  tag TEXT NOT NULL,
  title TEXT NOT NULL,
  summary TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS chat_messages (
  id TEXT PRIMARY KEY,
  channel_id TEXT NOT NULL,
  sender_id TEXT NOT NULL REFERENCES users(id),
  sender_handle TEXT NOT NULL,
  sender_role TEXT NOT NULL,
  content TEXT NOT NULL,
  reply_to_id TEXT,
  reply_preview TEXT,
  dice_roll_json TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS friendships (
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'accepted' CHECK (status IN ('pending', 'accepted', 'blocked')),
  presence_status TEXT NOT NULL DEFAULT 'online' CHECK (presence_status IN ('online', 'em_mesa', 'ausente', 'offline')),
  presence_activity TEXT NOT NULL DEFAULT 'Na Taverna',
  updated_at TEXT NOT NULL,
  PRIMARY KEY (user_id, friend_id)
);

CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('mesas', 'social', 'sistema')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  action_payload_json TEXT NOT NULL DEFAULT '{}',
  is_read INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS universal_reports (
  id TEXT PRIMARY KEY,
  reporter_id TEXT NOT NULL REFERENCES users(id),
  target_user_id TEXT,
  origin_type TEXT NOT NULL CHECK (origin_type IN ('chat', 'campanha', 'usuario', 'sistema', 'forum')),
  entity_type TEXT NOT NULL DEFAULT '',
  origin_id TEXT NOT NULL,
  reason_category TEXT NOT NULL,
  description TEXT NOT NULL,
  auto_tags_json TEXT NOT NULL,
  evidence_snapshot_json TEXT NOT NULL,
  votes_json TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'resolved', 'dismissed')),
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS p2p_signals (
  id TEXT PRIMARY KEY,
  campaign_id TEXT NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  leader_user_id TEXT NOT NULL,
  from_peer_id TEXT NOT NULL,
  to_peer_id TEXT NOT NULL,
  signal_type TEXT NOT NULL CHECK (signal_type IN ('presence', 'offer', 'answer', 'ice_candidate')),
  payload_json TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sessions_jti ON sessions(token_jti);
CREATE INDEX IF NOT EXISTS idx_campaigns_code ON campaigns(quick_join_code);
CREATE INDEX IF NOT EXISTS idx_compendium_system_cat ON compendium_items(system_id, category);
CREATE INDEX IF NOT EXISTS idx_chat_channel ON chat_messages(channel_id, created_at);
CREATE INDEX IF NOT EXISTS idx_reports_status ON universal_reports(status, created_at);
CREATE INDEX IF NOT EXISTS idx_p2p_campaign ON p2p_signals(campaign_id, created_at);
CREATE INDEX IF NOT EXISTS idx_scenes_campaign ON campaign_scenes(campaign_id);
CREATE INDEX IF NOT EXISTS idx_forum_comments_topic ON forum_comments(topic_id, created_at);

-- Conta técnica interna e Âncora Agnóstica (Zero sistemas de RPG visíveis inicialmente)
INSERT OR IGNORE INTO users (id, google_sub, email, birth_date, role, account_status, created_at, updated_at)
VALUES
  ('usr_system_official', 'sub_system_official', 'system@arcanavtt.app', '1990-01-01', 'superadmin', 'active', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z');

INSERT OR IGNORE INTO user_profiles (user_id, username, display_name, bio, avatar_icon, preferred_role, reputation_points, theme_preference, font_scale, onboarding_completed, updated_at)
VALUES
  ('usr_system_official', 'arcanavtt_oficial', 'ArcanaVTT Oficial', 'Mantenedor técnico da plataforma e do Motor Universal.', 'crown', 'superadmin', 0, 'escuro_heraldico', 1.0, 1, '2026-01-01T00:00:00.000Z');

INSERT OR IGNORE INTO systems (id, author_id, name, version, category_type, dice_engine, description, rules_json, downloads_count, rating, is_official, created_at)
VALUES
  ('sys_universal', 'usr_system_official', 'Motor Universal', 'v1.0', 'oficiais', 'universal', 'Âncora interna do Motor Universal agnóstico para mesas sem sistema vinculado.', '{"universal":true}', 0, 5.0, 0, '2026-01-01T00:00:00.000Z');
