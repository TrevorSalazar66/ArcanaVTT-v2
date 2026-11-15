# ArcanaVTT — Planejamento Estruturado & Arquitetura

## 1. Divisão em Fases do Projeto

- **Fase 1 (Atual — Base Segura, Edge Backend, Autenticação, Hub Central & Comunidades):**
  - **Ciclo 1:** Governança documental, Tríade de Especificação, schema SQLite/D1 e Backend Serverless Cloudflare Worker (`/api/health`, `/api/auth`, `/api/sync`) com testes em 3 camadas.
  - **Ciclo 2:** Setup do projeto Flutter, biblioteca de 50+ ícones SVG, Motor de Temas (Escuro Heráldico, OLED, Alto Contraste Solar) com escala tipográfica (`80%–150%`) e Módulo de Login 100% Google OAuth 2.0.
  - **Ciclo 3:** Hub Central adaptativo, Drawer com Widget Tree Pruning (RBAC), as 4 abas principais (*Início*, *Campanhas*, *Sistemas*, *Comunidades*) e os 20 modais primários interativos.
  - **Ciclo 4:** Testes automatizados em 3 camadas (Unitários, Controllers e Widgets), análise estática zero-erros, geração do APK Android Release e publicação no GitHub via branch `fase-1` -> `main` com tag `v0.1.0-fase-1`.
- **Fase 2 (Futura — Tabuleiro Tático WebSocket/WebRTC P2P em Tempo Real):** Integrará o canvas 2D interativo na sub-aba do VTT ao vivo (Grid Tático, Mahjong, Cofres e Fog of War) consumindo a sinalização P2P já implementada no backend na Fase 1.
- **Fase 3 (Futura — Áudio Procedural & Compartilhamento de Mapas em Nuvem):** Expandirá o Mixer de 4 Canais com sintetizador ambiente offline e compartilhamento comunitário em CDN.

---

## 2. Explicação Detalhada dos Pilares Arquiteturais

### 2.1. Arquitetura Clean em 4 Camadas (Cliente Flutter)
A aplicação mobile adota estritamente 4 camadas isoladas (`Presentation -> Controllers -> Domain -> Data`), impedindo acoplamento de regras de negócio ou chamadas HTTP dentro de widgets:
- **Core (`lib/core/`):** Temas, paleta cromática, constantes de ícones SVG e guardas Zero-Trust RBAC.
- **Domain (`lib/domain/`):** Entidades imutáveis (`UserAccount`, `Campaign`, `HeroCharacter`, `RpgSystem`, `CompendiumItem`, `Guild`, `ForumTopic`, `ChatMessage`, `UniversalReport`) e Casos de Uso puros (rolagem `3d6`, filtragem inteligente de compêndio sem categorias vazias, geração de autotags de denúncia e fluxo OAuth).
- **Data (`lib/data/`):** Cliente HTTP para o Cloudflare Worker (`CloudflareEdgeClient`), persistência local Offline-First (`LocalStorageDatasource`) e `ArcanaRepositoryImpl` sincronizando deltas.
- **Controllers (`lib/controllers/`):** `AppController` reativo (`ChangeNotifier`) orquestrando sessões, papéis, temas, campanhas, sistemas, comunidades e notificações.
- **Presentation (`lib/presentation/`):** Widgets base heráldicos (`HeraldicCard`, `HeraldicSectionDivider`, `SvgIconWidget`), Telas (`LoginScreen`, `MainHubScreen`, 4 Abas) e os 20 Modais Primários.

### 2.2. Arquitetura Edge Serverless (Cloudflare Worker + D1)
Para manter latência sub-50ms e custo zero na escala inicial, o backend é um Worker ES Modules TypeScript sem estado (Stateless) apoiado no Cloudflare D1 (SQLite distribuído):
- **Autenticação (`/api/auth`):** Validação de identidade Google OAuth 2.0, barreira etária LGPD (`>= 16 anos`), verificação de `device_security` (Hardware Ban / Trusted Device 15–30 dias) e protocolo de **Lockout Total** via WebCrypto + e-mail transacional.
- **Gateway Unificado (`/api/sync`):** Todas as operações autenticadas passam por validação **Zod Fail-Fast**, middleware JWT + verificação ativa de conta não bloqueada, matriz **RBAC Zero-Trust** (`jogador`, `assistente_mestre`, `mestre`, `admin`, `superadmin`) e queries SQL **100% parametrizadas**.
- **Sinalização P2P & Eleição Dinâmica de Líder:** O servidor apenas coordena presença e sinais WebRTC (`offer`, `answer`, `ice_candidate`), delegando a execução pesada da mesa para o dispositivo eleito como Líder P2P.

