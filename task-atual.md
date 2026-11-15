# ArcanaVTT — Task Atual & Status de Desenvolvimento

---

## 1. Função deste Arquivo
Este documento atua como o **ponto de ancoragem e sincronização viva do projeto ArcanaVTT**, mantendo o histórico consolidado do que já foi entregue e os próximos passos do roadmap.

---

## 2. Estado Atual
**Fase 1 Concluída (`v0.1.0-fase-1`)**: Backend Edge Cloudflare Workers/D1, Aplicativo Mobile Flutter (Tela de Login 100% Google OAuth 2.0 + Hub Central + 4 Abas Principais + Modais Primários Interativos), Testes em 3 Camadas (Backend + Flutter), Build APK Release e sincronização GitHub concluídos.

---

## 3. Resumo das Entregas da Fase 1

1. **Backend Cloudflare Workers + D1 (`Desenvolvimento/arcana_backend`):**
   - Hono.js + TypeScript + Zod + D1 (16 tabelas + seed oficial `AlphaD6 Core v2.4`).
   - `/api/auth` (Google OAuth 2.0, barreira `< 16 anos`, Hardware Ban, Lockout Total) e `/api/sync` (RBAC Zero-Trust, Compêndio inteligente, Denúncia com autotags, Chat 3d6 e Sinalização P2P).
   - Validado via `npm run typecheck`, `npm test` (10/10) e `npx wrangler deploy --dry-run`.
2. **Aplicativo Mobile Flutter (`Desenvolvimento/arcana_app`):**
   - Clean Architecture em 4 camadas, 100% ícones vetoriais SVG (`assets/icons/`), Zero Emojis, 3 Temas Oficiais e escala tipográfica `80%–150%`.
   - Login Google OAuth 2.0 + Hub Central + 4 Abas + Modais funcionais (incluindo Chat Comunitário Híbrido WhatsApp + Discord com bolhas, duplo check e rolagem `3d6` ao vivo).
   - Validado via `dart analyze` (0 issues), `flutter test` (9/9) e geração do APK Release (`52.4 MB`).

---

## 4. Próximo Passo (Fase 2)
- Implementar o Tabuleiro Tático P2P em Tempo Real (Grid Tático 2D, Mahjong, Cofres e Fog of War) consumindo o endpoint `sync.presence` e `sync.signal` do backend Cloudflare, além do deploy definitivo do Worker na nuvem Cloudflare.
