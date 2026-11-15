# ArcanaVTT — Tarefas da Fase 1 (`tarefas.md`)

## Ciclo 1: Governança Documental & Backend Cloudflare Workers / D1
- [x] Criar branch `fase-1` e atualizar `.gitignore` para builds/segredos/APKs
- [x] Criar Tríade de Especificação (`idealizacao.md`, `planejamento.md`, `funcoes.md`) e `estrutura-pastas.md`
- [x] Criar schema D1 e migração inicial (`schema.sql` + `migrations/0001_initial_schema.sql`) com 16 tabelas e seed `AlphaD6 Core v2.4`
- [x] Implementar middlewares (`security_headers`, `rate_limiter`, `auth_middleware` Zero-Trust RBAC) e WebCrypto JWT
- [x] Implementar schemas Zod (`auth_schemas.ts`, `sync_schemas.ts`)
- [x] Implementar todos os Casos de Uso em `src/domain/usecases/` (OAuth Google 100%, `<16 anos`, Hardware Ban, Lockout Total, Campanhas, Sistemas/Compêndio sem categorias vazias, Comunidades/Chat/Fórum, Social, Denúncia Universal com autotags, Admin Governance e Sinalização P2P)
- [x] Implementar e aprovar 100% dos testes em 3 camadas do backend (`npm test`, `npm run typecheck`, `wrangler deploy --dry-run`)

## Ciclo 2: Setup Flutter, Design System Heráldico (SVG-First) & Login Google OAuth
- [x] Configurar Flutter SDK para JDK 17 e Android SDK usando caminhos curtos ASCII / unidade virtual `W:`
- [x] Criar projeto `Desenvolvimento/arcana_app` e copiar os ícones SVG vetoriais para `assets/icons/`
- [x] Implementar `ArcanaColors` e `ArcanaThemeBuilder` com os **3 Temas Oficiais** e escala tipográfica dinâmica (`80%–150%`)
- [x] Implementar `SvgIconWidget` e componentes base heráldicos com **Zero Emojis**
- [x] Implementar `LoginScreen` 100% Google OAuth 2.0 com toggle Dispositivo Confiável e estados Padrão, Erro (`<16 anos`, Hardware Ban, Lockout) e Sucesso + Onboarding

## Ciclo 3: Hub Central, 4 Abas Principais & 20 Modais Primários
- [x] Implementar `MainHubScreen` com Top AppBar, Drawer com Widget Tree Pruning (RBAC) e Navegação Adaptativa (`<600dp` BottomBar, `>=600dp` Rail)
- [x] Implementar Aba **Início** (Saudação, Quick Join 6 dígitos/QR, Carrossel Continuar Jornada, Herói em Destaque, Mural de Novidades)
- [x] Implementar Aba **Campanhas** (Busca, filtros por papel, badges ao vivo e wizard de 4 etapas)
- [x] Implementar Aba **Sistemas** (4 segmentos, `AlphaD6 Core v2.4`, ocultação automática de categorias vazias no Compêndio)
- [x] Implementar Aba **Comunidades** (Anúncios, Guildas com Guild Boost, Fórum com upvotes e Grupos/Chat)
- [x] Implementar todos os modais primários interativos, incluindo **Chat Comunitário Híbrido (WhatsApp + Discord)** com bolhas esquerda/direita, duplo check e rolagem `3d6` ao vivo

## Ciclo 4: Testes em 3 Camadas Flutter, APK Release & GitHub Push
- [x] Implementar testes em 3 camadas em `Desenvolvimento/arcana_app/test/` (Unitários, Controllers e Widgets UI + RBAC Pruning)
- [x] Aprovar `dart analyze` com `No issues found!` e `flutter test` com 100% de aprovação (9/9)
- [x] Gerar APK Release Android (`app-release.apk` — 52.4 MB)
- [x] Registrar logs de todos os ciclos em `Desenvolvimento/docs/historico-ciclos/`
- [x] Atualizar `CHANGELOG.md` e `task-atual.md`, commitar em PT-BR na branch `fase-1`, mesclar na `main`, criar tag `v0.1.0-fase-1` e realizar `git push`
