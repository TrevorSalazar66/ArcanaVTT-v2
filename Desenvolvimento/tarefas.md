# Lista de Tarefas — ArcanaVTT

## Fase 1 — Infraestrutura, Autenticação Google OAuth & Hub Central
- [x] API Cloudflare Workers (Hono + TypeScript + Zod + D1) configurada e publicada em produção
- [x] Login 100% Google OAuth 2.0 (Android + Web Client IDs ocultos/protegidos, barreira LGPD >= 16 anos, Hardware Ban, Lockout Total 6 dígitos)
- [x] Papel inicial obrigatório `jogador` no onboarding + promoção automática do primeiro usuário real para `superadmin`
- [x] Hub Central responsivo (`BottomNavigationBar` / `NavigationRail` / Sidebar fixa `>=900dp`) com ícones SVG oficiais (Zero Emojis)
- [x] 3 Temas Dinâmicos (*Escuro Heráldico*, *OLED*, *Alto Contraste Solar*) + escala de fonte persistentes
- [x] Modais Sociais (Notificações com Convite Direto, Perfil Discord sem expor e-mail, Amigos, DMs 1-a-1, Tutoriais Sandbox, Configurações Gerais, Denúncia Universal com 5 autotags e Governança Admin)

## Fase 2 — Campanhas (7 Sub-abas), Oficina do Mestre & Motor Universal
- [x] Remoção total de sistemas pré-populados (`Zero Hardcoded RPG Systems`) + Keys de Criação (`KEY-ARC-*`)
- [x] Motor Universal Agnóstico (fórmulas, `kh/kl`, pools, `d100`, testes resistidos `/opposed`, comandos de chat `/roll`, `/gmroll`, `/w`, `/me`, `/ooc`, `/gm`, `/npc`, `/rest`, `/heal`, `/init`)
- [x] Compêndio Delta com Herança (`mergeCompendiumDelta`), `parseDiceRange` `{min, max}` e Blocos Visuais `RoleGate`
- [x] Wizard de Campanha em 4 etapas + Filtros Avançados + Hub da Campanha completo (7 sub-abas) + Ficha de Herói vinculada (máx 1 por mesa, 9 slots corporais, prata)
- [x] Oficina do Mestre (3 módulos fullscreen: Cenas até 18 + Construtor No-Code `[QUANDO]->[SE]->[ENTÃO]` + `Capturar Alvo`, Compêndio Delta, Mundo Overworld até 25 mapas + Relógio Procedural + Facções `-100..+100`)
- [x] 6 Modelos de Cena Jogáveis (Grid Tático 2D com Fog/Raycasting, Mahjong & Minas, Senha & Cofre, Menus/Diálogos, Combate JRPG por Turnos e Terminal CRT)
- [x] Suítes automatizadas de 3 camadas passando no backend (Vitest 12/12) e no Flutter (`dart analyze` 0 issues, `flutter test` 11/11) + APK Release compilado
