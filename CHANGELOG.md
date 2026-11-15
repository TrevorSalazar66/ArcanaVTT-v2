# Changelog — ArcanaVTT

Todas as mudanças notáveis deste projeto serão documentadas neste arquivo seguindo o padrão Keep a Changelog e Versionamento Semântico (SemVer).

## [0.1.1-fase-1] — Remoção Total de Mocks, Google OAuth 2.0 Real & Sincronização Cloudflare D1

### Alterado
- **Backend Cloudflare Workers + D1 (`Desenvolvimento/arcana_backend`):**
  - Removidos todos os registros fictícios dos arquivos `schema.sql`, `migrations/0001_initial_schema.sql` e do repositório padrão em memória, mantendo apenas o usuário institucional do sistema (`system@arcanavtt.app`), o sistema oficial **AlphaD6 Core v2.4** (`sys_alphad6_v24`) e seus 5 itens oficiais de compêndio.
  - Adicionada validação real de `id_token` Google via `tokeninfo` com verificação opcional de `GOOGLE_CLIENT_ID`, promoção automática do primeiro usuário real cadastrado para `superadmin`, preservação de cargo em `profile.setup`, e novas ações D1 para Guildas (`guilds.create`, `guilds.boost`) e Fichas de Herói (`characters.list`, `characters.upsert`).
  - Validado com `npm run typecheck` (0 erros), `npm test` (11/11 aprovados) e `npx wrangler deploy --dry-run`.
- **Aplicativo Mobile Android (`Desenvolvimento/arcana_app`):**
  - Removidos todos os dados mockados embutidos em `ArcanaSeedData` e `AppController` (campanhas, heróis, guildas, tópicos, chat, amigos, notificações e denúncias agora iniciam vazios e são hidratados diretamente do Cloudflare D1).
  - Integrado pacote `google_sign_in` com seletor real de Conta Google no Android, seletor de data de nascimento (LGPD >= 16 anos), seleção de papel inicial (`Jogador`, `Auxiliar`, `Mestre`) e card configurável para URL do Worker Cloudflare e Google Client ID (`Configurações Gerais` e `LoginScreen`).
  - Implementados estados vazios interativos no Hub Central, Campanhas, Guildas, Fórum, Chat Comunitário, Amigos, Notificações e Governança, além do formulário completo de criação/edição da Ficha de Herói AlphaD6 (`HeroSheetHighlightModal`) e fundação de guildas (`CreateGuildModal`).
  - Atualizada a suíte Flutter em 3 camadas (`dart analyze` com `No issues found!` e `flutter test` com 10/10 aprovados).

## [0.1.0-fase-1] — Fase 1: Login OAuth, Hub Central, Modais Primários & Backend Cloudflare Workers/D1

### Adicionado
- **Backend Serverless Edge (`Desenvolvimento/arcana_backend`):**
  - API em **Hono.js + TypeScript Strict + Zod (Fail-Fast)** preparada para **Cloudflare Workers + D1 SQLite**.
  - Schema relacional completo (`schema.sql` e `migrations/0001_initial_schema.sql`) com 16 tabelas e seed idempotente do sistema oficial **AlphaD6 Core v2.4**.
  - Autenticação 100% Google OAuth 2.0 (`/api/auth`) com verificação etária LGPD (`>= 16 anos`), registro de Dispositivo Confiável (15–30 dias), Hardware Ban (`device_security`), JWT WebCrypto HMAC-SHA256 e Lockout Total com código de recuperação via Resend/Brevo.
  - Gateway `/api/sync` Zero-Trust RBAC (`jogador`, `assistente_mestre`, `mestre`, `admin`, `superadmin`) com SQL 100% parametrizado, Compêndio com ocultação de categorias vazias, Denúncia Universal com autotags automáticas e Sinalização P2P com Eleição Dinâmica de Líder.
  - Suíte automatizada Vitest em 3 camadas (Unitário, Integração e E2E HTTP — 10/10 aprovados) + verificação `wrangler deploy --dry-run`.
- **Aplicativo Mobile Android (`Desenvolvimento/arcana_app`):**
  - Arquitetura Limpa em 4 camadas (`Presentation -> Controllers -> Domain -> Data`) + núcleo visual Dark Fantasy Heráldico (**SVG-First / Zero Emojis**).
  - Motor dinâmico dos **3 Temas Oficiais** (*Modo Escuro Heráldico*, *OLED `#000000`*, *Alto Contraste Solar*) e multiplicador tipográfico (`80%–150%`).
  - **LoginScreen** 100% Google OAuth 2.0 (sem campos de senha) com inspeção interativa dos estados Padrão, Erro/Bloqueio e Sucesso + Onboarding.
  - **MainHubScreen** responsivo (`BottomNavigationBar` <600dp / `NavigationRail` >=600dp), Drawer com Widget Tree Pruning RBAC e as 4 abas principais (*Início*, *Campanhas*, *Sistemas*, *Comunidades*).
  - Modais primários interativos funcionais: Chat Comunitário Híbrido (**WhatsApp + Discord** com bolhas, duplo check e rolagem `3d6` embutida), Quick Join 6 dígitos/QR, Ficha em Destaque AlphaD6 `3d6`, Wizard de Campanha 4 etapas, Painel de Guilda & Guild Boost, Fórum com upvotes, Tutoriais Sandbox, Configurações Gerais com Mixer de Áudio de 4 canais, Painel Admin, Logout Seguro e Denúncia Universal.
  - Suíte Flutter em 3 camadas (`dart analyze` com 0 issues e `flutter test` 9/9 aprovados) e geração do APK Release (`app-release.apk`).

