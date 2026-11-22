-- Migração 0003 — Motor Universal Agnóstico, Fase 1 Completa & Fase 2 (Oficina, Cenas, Keys, Banimentos e Votação Colegiada)

-- 1. Remove sistema hardcoded anterior e registra âncora técnica agnóstica invisível ao catálogo público
DELETE FROM compendium_items WHERE system_id = 'sys_alphad6_v24';
DELETE FROM systems WHERE id = 'sys_alphad6_v24';

INSERT OR IGNORE INTO systems (id, author_id, name, version, category_type, dice_engine, description, rules_json, downloads_count, rating, is_official, created_at)
VALUES
  ('sys_universal', 'usr_system_official', 'Motor Universal', 'v1.0', 'oficiais', 'universal', 'Âncora interna do Motor Universal agnóstico para mesas sem sistema vinculado.', '{"universal":true}', 0, 5.0, 0, '2026-01-01T00:00:00.000Z');

-- 2. Evolução segura de colunas existentes
ALTER TABLE users ADD COLUMN suspended_until TEXT;
ALTER TABLE campaigns ADD COLUMN is_inactive_archived INTEGER NOT NULL DEFAULT 0;
ALTER TABLE campaigns ADD COLUMN last_activity_at TEXT NOT NULL DEFAULT '';
ALTER TABLE universal_reports ADD COLUMN entity_type TEXT NOT NULL DEFAULT '';
ALTER TABLE universal_reports ADD COLUMN votes_json TEXT NOT NULL DEFAULT '[]';

-- 3. Novas tabelas relacionais
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

CREATE INDEX IF NOT EXISTS idx_scenes_campaign ON campaign_scenes(campaign_id);
CREATE INDEX IF NOT EXISTS idx_forum_comments_topic ON forum_comments(topic_id, created_at);
