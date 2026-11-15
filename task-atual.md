# ArcanaVTT — Task Atual & Status de Desenvolvimento

---

## 1. Função deste Arquivo
Este documento atua como o **ponto de ancoragem e sincronização viva do projeto ArcanaVTT**, mantendo o histórico consolidado do que já foi entregue e os próximos passos do roadmap.

---

## 2. Estado Atual
**Fase 1 Limpa & Funcional (`v0.1.1-fase-1`)**: Todos os dados fictícios/mockados removidos no Backend e no App. Backend Cloudflare Workers/D1 pronto (validação real de `id_token` Google, auto-`superadmin` ao primeiro usuário real, CRUD D1 completo de Fichas e Guildas), pacote `google_sign_in` integrado no Android, estados vazios interativos no Hub e testes das 3 camadas 100% aprovados.

---

## 3. Resumo das Entregas da Fase 1

1. **Backend Cloudflare Workers + D1 (`Desenvolvimento/arcana_backend`):**
   - Hono.js + TypeScript + Zod + D1 (16 tabelas + apenas sistema oficial `AlphaD6 Core v2.4`, zero registros fictícios).
   - `/api/auth` (`id_token` Google OAuth 2.0 real, barreira `< 16 anos`, Hardware Ban, Lockout Total, promoção do primeiro usuário real a `superadmin`) e `/api/sync` (RBAC Zero-Trust, Compêndio inteligente, Denúncia com autotags, Chat 3d6, Guildas, Fichas `characters` e Sinalização P2P).
   - Validado via `npm run typecheck` (0 erros), `npm test` (**11/11** aprovados) e `npx wrangler deploy --dry-run` (`278.11 KiB / gzip: 57.40 KiB`).
2. **Aplicativo Mobile Flutter (`Desenvolvimento/arcana_app`):**
   - Clean Architecture em 4 camadas, 100% ícones vetoriais SVG (`assets/icons/`), Zero Emojis, 3 Temas Oficiais e escala tipográfica `80%–150%`.
   - Autenticação real via `google_sign_in` + configuração in-app de URL do Cloudflare Worker e Client ID OAuth + sincronização completa D1 (`hydrateAllFromBackend()` e mutações `POST /api/sync`) + Hub limpo com criação de Ficha AlphaD6 e Fundação de Guildas.
   - Validado via `dart analyze` (`No issues found!`), `flutter test` (**10/10** aprovados) e geração do APK Release (`54.1 MB`).

---

## 4. Próximo Passo (Fase 2)
- Implementar o Tabuleiro Tático P2P em Tempo Real (Grid Tático 2D, Mahjong, Cofres e Fog of War) consumindo o endpoint `sync.presence` e `sync.signal` do backend Cloudflare, além do deploy definitivo do Worker na nuvem Cloudflare.
