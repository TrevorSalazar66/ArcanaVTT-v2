# ArcanaVTT Backend — Cloudflare Workers + D1

API serverless Edge construída com **Hono.js**, **TypeScript Strict**, **Zod (Fail-Fast)** e **Cloudflare D1 (SQLite)**.

## Endpoints Disponíveis
- `GET /api/health` — Diagnóstico público de saúde do Worker.
- `POST /api/auth` — Autenticação 100% Google OAuth 2.0 (verificação `>= 16 anos`, Hardware Ban em `device_security`, Dispositivo Confiável 15–30 dias, Lockout Total com código via Resend/Brevo e Logout global).
- `POST /api/sync` — Gateway autenticado Zero-Trust (Perfil/Onboarding, Campanhas/Quick Join, Sistemas/Compêndio sem categorias vazias, Comunidades/Guildas/Fórum/Chat 3d6, Social/Notificações, Denúncia Universal com autotags, Governança Admin e Sinalização P2P).

## Como Implantar na Cloudflare
1. Instale dependências:
   ```bash
   npm install
   ```
2. Crie o banco D1 na sua conta Cloudflare:
   ```bash
   npx wrangler d1 create arcana_vtt_db
   ```
3. Copie o `database_id` gerado para `wrangler.toml`.
4. Aplique o schema inicial no banco local e remoto:
   ```bash
   npm run db:migrate:local
   npm run db:migrate:remote
   ```
5. Cadastre os segredos de produção na Cloudflare:
   ```bash
   npx wrangler secret put JWT_SECRET
   npx wrangler secret put GOOGLE_CLIENT_ID
   npx wrangler secret put RESEND_API_KEY
   ```
6. Publique o Worker:
   ```bash
   npm run deploy
   ```

