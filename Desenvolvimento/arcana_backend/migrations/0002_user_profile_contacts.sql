-- Migração 0002 — Contatos sociais opcionais do perfil (Discord, WhatsApp, Instagram)
ALTER TABLE user_profiles ADD COLUMN contacts_json TEXT NOT NULL DEFAULT '{}';
