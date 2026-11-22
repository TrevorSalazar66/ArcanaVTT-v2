# Tarefa Atual — ArcanaVTT

**Versão:** `v0.2.0-universal` (Fase 1 Integral + Fase 2 + Motor Universal Agnóstico)
**Branch Ativa:** `fase-1` / `main`

## Escopo Concluído
- **Backend Cloudflare Workers + D1 (`Desenvolvimento/arcana_backend`):**
  - Migration `0003_universal_engine_and_phase2.sql` aplicada no banco D1 remoto (`arcana_vtt_db`) e Worker implantado em `https://arcana-vtt-backend.testgamingdev.workers.dev`.
  - Motor Universal Agnóstico (`universal_rpg_engine.ts`): fórmulas `XdY+Z`, `2d20kh1/kl1`, pools `XdY>=T` com dificuldade e desempate, `1d100<=Alvo`, `parseDiceRange`, `mergeCompendiumDelta` e comandos universais (`/roll`, `/gmroll`, `/opposed`, `/w`, `/me`, `/ooc`, `/gm`, `/npc`, `/rest`, `/heal`, `/init`, cards de aprovação).
  - Catálogo inicial zero sistemas (`sys_alphad6_v24` removido), Key de Criação (`KEY-ARC-*`), barreira `PROFILE_INCOMPLETE`, Sigilo de E-mail LGPD em `social.get_profile`, DMs 1-a-1 isoladas + auditoria Superadmin, Banimento em Nível de Mestre, limite rígido 1 ficha/campanha e 18 cenas/campanha com gatilhos No-Code, Guild Boost Nv.1..5 e Votação Colegiada de 3 Admins.
  - Verificado: `npm run typecheck` (0 erros) e `npm test` (12/12 aprovados).

- **Aplicativo Android Flutter (`Desenvolvimento/arcana_app`):**
  - Integração completa com o Motor Universal, zero sistemas hardcoded em `ArcanaSeedData`, fingerprint persistente único em `LocalStorageDatasource` e tratamento unificado de erros/preferências em `AppController`.
  - Telas e Modais atualizados sem seleção prévia de cargo, sem exposição de URL/Client ID nem e-mail privado: `MainHubScreen`, 4 abas principais, `SocialProfileModal` (3 abas Discord + Drill-Down + 8 contatos), `DirectMessageModal`, `FriendsManagementModal`, `NotificationsModal` (convite direto vs Quick Join), `TutorialsCentralModal` Sandbox, `GeneralSettingsModal`, `AdminGovernanceModal` (5 módulos), `HeroSheetHighlightModal`, `CampaignGeneralModal` (7 sub-abas) e `workshop_and_scenes_modals.dart` (Oficina do Mestre + 6 Modelos de Cena + No-Code Builder).
  - Verificado: `dart analyze` (`No issues found!`) e `flutter test` (11/11 aprovados nas 3 camadas).
