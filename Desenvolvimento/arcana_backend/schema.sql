-- ArcanaVTT — Schema D1 (SQLite Edge) & Seed Oficial v0.1.0-fase-1
-- Compatível com `wrangler d1 migrations apply` e execução idempotente.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  google_sub TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  birth_date TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'jogador' CHECK (role IN ('jogador', 'assistente_mestre', 'mestre', 'admin', 'superadmin')),
  account_status TEXT NOT NULL DEFAULT 'active' CHECK (account_status IN ('active', 'locked', 'banned')),
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
  dice_engine TEXT NOT NULL DEFAULT '3d6',
  description TEXT NOT NULL,
  rules_json TEXT NOT NULL,
  downloads_count INTEGER NOT NULL DEFAULT 0,
  rating REAL NOT NULL DEFAULT 5.0,
  is_official INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
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
  origin_id TEXT NOT NULL,
  reason_category TEXT NOT NULL,
  description TEXT NOT NULL,
  auto_tags_json TEXT NOT NULL,
  evidence_snapshot_json TEXT NOT NULL,
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

-- Seed Idempotente Oficial (AlphaD6 Core v2.4 & Ecossistema Inicial)
INSERT OR IGNORE INTO users (id, google_sub, email, birth_date, role, account_status, created_at, updated_at)
VALUES
  ('usr_admin_thorin', 'sub_admin_thorin', 'thorin@arcanavtt.app', '1992-05-14', 'superadmin', 'active', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z'),
  ('usr_mestre_cypher', 'sub_mestre_cypher', 'cypher@arcanavtt.app', '1995-08-21', 'mestre', 'active', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z'),
  ('usr_valen_bard', 'sub_valen_bard', 'valen@arcanavtt.app', '2001-03-10', 'jogador', 'active', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z');

INSERT OR IGNORE INTO user_profiles (user_id, username, display_name, bio, avatar_icon, preferred_role, reputation_points, theme_preference, font_scale, onboarding_completed, updated_at)
VALUES
  ('usr_admin_thorin', 'admin_thorin', 'Thorin Guardiao', 'Arquiteto do Sistema Oficial AlphaD6 e guardiao da Taverna.', 'crown', 'superadmin', 990, 'escuro_heraldico', 1.0, 1, '2026-01-01T00:00:00.000Z'),
  ('usr_mestre_cypher', 'mestre_cypher', 'Mestre Cypher', 'Cronista de masmorras taticas e cenarios com nevoa.', 'scroll', 'mestre', 640, 'escuro_heraldico', 1.0, 1, '2026-01-01T00:00:00.000Z'),
  ('usr_valen_bard', 'valen_bard', 'Valen Voss', 'Explorador das Terras Cinzentas e duelista de AlphaD6.', 'swords', 'jogador', 320, 'escuro_heraldico', 1.0, 1, '2026-01-01T00:00:00.000Z');

INSERT OR IGNORE INTO systems (id, author_id, name, version, category_type, dice_engine, description, rules_json, downloads_count, rating, is_official, created_at)
VALUES
  ('sys_alphad6_v24', 'usr_admin_thorin', 'AlphaD6 Core', 'v2.4', 'oficiais', '3d6', 'Sistema oficial Dark Fantasy baseado em rolagem de 3d6 (Corpo, Mente, Espirito), inventario em 12 slots fisicos e reserva de Anima.', '{"attributes":["Corpo","Mente","Espirito"],"inventory_slots":12,"success_threshold":5}', 12480, 4.9, 1, '2026-01-01T00:00:00.000Z'),
  ('sys_lamina_carmesim', 'usr_mestre_cypher', 'Lamina Carmesim', 'v1.2', 'comunidade', '3d6', 'Adaptacao letal focada em duelos de esgrima e alquimia de sangue.', '{"attributes":["Acuidade","Engenho","Vontade"],"inventory_slots":10,"success_threshold":5}', 3120, 4.7, 0, '2026-01-05T00:00:00.000Z');

INSERT OR IGNORE INTO campaigns (id, owner_id, title, synopsis, system_id, quick_join_code, mode, schedule_text, max_slots, occupied_slots, visibility, state_json, created_at)
VALUES
  ('cmp_valen_01', 'usr_mestre_cypher', 'A Maldicao de Valen', 'Os sinos da Capela Submersa voltaram a tocar apos tres seculos de silencio.', 'sys_alphad6_v24', 'ARC774', 'ao_vivo', 'Sab 20h', 5, 4, 'publica', '{"chapter":"Ato II - As Criptas de Basalto"}', '2026-01-10T00:00:00.000Z'),
  ('cmp_cinza_02', 'usr_mestre_cypher', 'Cronicas de Cinza', 'Campanha assincrona de investigacao arcana e intriga politica.', 'sys_alphad6_v24', 'CIN882', 'tempo_livre', 'Tempo Livre', 6, 3, 'publica', '{"chapter":"Prologo - O Selo Quebrado"}', '2026-01-12T00:00:00.000Z');

INSERT OR IGNORE INTO compendium_items (id, system_id, campaign_id, category, name, rarity, slots_weight, description, properties_json, created_at)
VALUES
  ('item_espada_runica', 'sys_alphad6_v24', NULL, 'equipamentos', 'Espada Runica de Ferro Negro', 'Raro', 2, 'Lamina forjada com runas que brilham em azul diante de espectros.', '{"damage":"+1 sucesso contra mortos-vivos"}', '2026-01-01T00:00:00.000Z'),
  ('item_elixir_anima', 'sys_alphad6_v24', NULL, 'itens', 'Elixir de Anima Concentrada', 'Incomum', 1, 'Restaura 4 pontos de Anima imediatamente durante combate.', '{"restore_anima":4}', '2026-01-01T00:00:00.000Z'),
  ('item_sentinela_cinza', 'sys_alphad6_v24', NULL, 'seres', 'Sentinela das Cinzas', 'Epico', 0, 'Automato de armadura oca movido por brasas arcanas.', '{"hp":18,"armor":2}', '2026-01-01T00:00:00.000Z'),
  ('item_selo_chama', 'sys_alphad6_v24', NULL, 'poderes', 'Selo da Chama Eterna', 'Raro', 0, 'Conjura um escudo circular dourado que reduz dano em 2.', '{"anima_cost":2}', '2026-01-01T00:00:00.000Z'),
  ('item_pergaminho_valen', 'sys_alphad6_v24', NULL, 'pistas', 'Pergaminho do Pacto de Valen', 'Unico', 1, 'Documento rasgado revelando o nome verdadeiro do arquimago.', '{"clue_tier":3}', '2026-01-01T00:00:00.000Z');

INSERT OR IGNORE INTO guilds (id, leader_id, name, tag, description, member_count, active_tables_count, boost_points, boost_goal, shared_world_json, created_at)
VALUES
  ('gld_chama_cinzenta', 'usr_mestre_cypher', 'Ordem da Chama Cinzenta', 'CHAMA', 'Guilda de mundo compartilhado dedicada a campanhas interligadas no continente de Valen.', 42, 6, 780, 1000, '{"world":"Continente de Valen","season":"Era das Brasas"}', '2026-01-03T00:00:00.000Z');

INSERT OR IGNORE INTO forum_topics (id, author_id, author_handle, category, title, content, upvotes, replies_count, pinned, created_at)
VALUES
  ('top_balanceamento_3d6', 'usr_mestre_cypher', '@mestre_cypher', 'Regras & Oficina', 'Guia de balanceamento de encontros 3d6 para grupos de 4 jogadores', 'Quando utilizar sentinelas de elite, mantenha o limiar de sucesso em 5 ou 6 e limite recargas de Anima.', 29, 8, 1, '2026-01-14T18:00:00.000Z'),
  ('top_worldbuilding_valen', 'usr_valen_bard', '@valen_bard', 'Narrativa', 'Mapa colaborativo das rotas comerciais de Basalto', 'Compartilho nossas notas sobre as guildas mercantes e passagens secretas.', 17, 4, 0, '2026-01-15T11:30:00.000Z');

INSERT OR IGNORE INTO chat_messages (id, channel_id, sender_id, sender_handle, sender_role, content, reply_to_id, reply_preview, dice_roll_json, created_at)
VALUES
  ('msg_01', 'taverna-dos-mestres', 'usr_mestre_cypher', '@mestre_cypher', 'mestre', 'Alguem ja testou o encontro na cripta com nevoa densa e 20% de armadilhas?', NULL, NULL, NULL, '2026-01-15T14:22:00.000Z'),
  ('msg_02', 'taverna-dos-mestres', 'usr_valen_bard', '@valen_bard', 'jogador', 'Rodei um teste de Mente agora ha pouco na mesa!', 'msg_01', '@mestre_cypher: Alguem ja testou o encontro...', '{"label":"TESTE DE MENTE (3D6)","dice":[5,6,2],"successes":2,"outcome":"Sucesso"}', '2026-01-15T14:25:00.000Z'),
  ('msg_03', 'taverna-dos-mestres', 'usr_admin_thorin', '@admin_thorin', 'admin', 'Perfeito! O dano reduzido pela Anima sincroniza via P2P sem latencia no aparelho.', NULL, NULL, NULL, '2026-01-15T14:28:00.000Z');

