# ArcanaVTT — Especificação Técnica de Funções & Contratos (Fase 1)

## 1. Endpoints do Backend Cloudflare Worker (`arcana_backend`)

### 1.1. `GET /api/health`
- **Responsabilidade:** Healthcheck público do Worker e verificação de disponibilidade da camada D1.
- **Saída (`200 OK`):** `{ ok: true, service: "arcana-vtt-backend", version: "0.1.0-fase-1", timestamp_utc: string }`.

### 1.2. `POST /api/auth`
- **Validação (Zod):** Discriminated union por `action`:
  - `oauth_google`: `{ action, id_token_or_sub, email, display_name, birth_date, device_fingerprint, trust_device, simulated_role? }`
    - **Pré-condições:** `birth_date` válido (`YYYY-MM-DD`).
    - **Regras:** Calcula idade UTC; se `< 16 anos`, retorna `403 AGE_RESTRICTED`. Consulta `device_security` por `device_fingerprint`; se `is_hardware_banned == 1`, retorna `403 HARDWARE_BANNED`. Se usuário existir com `account_status == 'locked'`, retorna `423 ACCOUNT_LOCKED`. Caso válido, emite JWT HMAC-SHA256 com TTL de 30 dias (Trusted) ou 1 dia e registra sessão no D1.
  - `lockout_trigger`: `{ action, user_id, reason }` — Revoga todas as sessões ativas no D1, define `account_status = 'locked'`, gera código de desbloqueio de 6 dígitos (hash SHA-256 salvo no banco) e prepara disparo Resend/Brevo.
  - `lockout_verify`: `{ action, email, recovery_code, device_fingerprint }` — Valida hash SHA-256 do código; se válido, restaura `account_status = 'active'` e revoga dispositivos não confiáveis.
  - `logout`: `{ action, scope: 'current' | 'global' }` — Revoga `token_jti` atual ou todas as sessões do usuário no D1.

### 1.3. `POST /api/sync` (Autenticado via Bearer JWT)
- **Middleware Zero-Trust:** Valida JWT, confirma que sessão não está revogada (`revoked = 0`) e conta está `'active'`.
- **Ações Suportadas (`action`):**
  1. `profile.setup`: Atualiza `@username` único (regex `^[a-z0-9_]{3,24}$`), `display_name`, `bio`, `theme_preference`, `font_scale`.
  2. `campaigns.list`: Retorna campanhas segregadas pelo contexto (`jogando`, `auxiliar`, `mestre`, `explorar`) + filtros de busca.
  3. `campaigns.quick_join`: Recebe `code` alfanumérico de 6 caracteres (normalizado sem hífen, ex.: `ARC774`) e vincula jogador como membro ativo se houver vaga disponível.
  4. `campaigns.create`: **RBAC estrito (`mestre`, `admin`, `superadmin`)**. Cria campanha com código Quick Join único e registra dono como `mestre`.
  5. `campaigns.apply`: Registra candidatura de jogador com ficha escolhida e mensagem ao mestre.
  6. `systems.list`: Lista os 4 segmentos (`oficiais`, `proprios`, `meus`, `comunidade`) e dados completos do `AlphaD6 Core v2.4`.
  7. `systems.create`: Forja sistema próprio armazenando regras em JSON Delta.
  8. `compendium.query`: Retorna itens filtrados e lista de **categorias não vazias** (regra de ocultação automática dentre `itens`, `equipamentos`, `seres`, `poderes`, `pistas`).
  9. `communities.overview`: Retorna anúncios, guildas (Shared World + Guild Boost), tópicos do fórum e canais de chat.
  10. `forum.create_topic` & `forum.upvote`: Cria tópicos e contabiliza votos.
  11. `chat.send_message`: Envia mensagem de texto com suporte a `reply_to_id` e objeto opcional `roll_3d6: { label, dice: [d1, d2, d3], successes }` validado no servidor.
  12. `social.overview`, `social.add_friend`, `notifications.list`, `notifications.mark_read`: Gerencia rede de amizades e avisos.
  13. `report.submit`: Recebe denúncia universal e anexa **Autotags Automáticas** (`#origem`, `#sessao`, `#timestamp_utc`, `#reporter_role`).
  14. `admin.overview` & `admin.moderate`: **RBAC estrito (`admin`, `superadmin`)**. Permite banimento de hardware (`device_security.is_hardware_banned = 1`) e resolução de denúncias.
  15. `sync.presence` & `sync.signal`: Coordena presença e **Eleição Dinâmica de Líder P2P** (peso por cargo + latência/bateria) e encaminha sinais WebRTC.

---

## 2. Casos de Uso & Módulos do App Flutter (`arcana_app`)

1. **`Roll3d6UseCase` (`lib/domain/usecases/roll_3d6_usecase.dart`):** Executa rolagem justa client-side de 3 dados d6 (`Random.secure()`), conta sucessos (`valor >= 5`), classifica Resultado (`Falha Crítica` se soma 3, `Sucesso Crítico` se todos 6, `Sucesso` se >= 1 acerto, senão `Falha`) e devolve objeto pronto para bolha de chat ou ficha.
2. **`FilterCompendiumCategoriesUseCase`:** Agrupa os itens de `CompendiumItem` nas 5 categorias universais (`itens`, `equipamentos`, `seres`, `poderes`, `pistas`) e **remove qualquer categoria cuja contagem seja zero**, garantindo UI limpa em sistemas minimalistas ou específicos.
3. **`BuildUniversalReportUseCase`:** Recebe tipo de origem (`chat`, `campanha`, `usuario`, `sistema`, `forum`), ID do alvo e descrição, anexando automaticamente as autotags de rastreabilidade sem exposição de dados sensíveis do denunciante.
4. **`RbacGuard` (`lib/core/security/rbac_guard.dart`):** Proíbe renderização na árvore de widgets (`Widget Tree Pruning`) de botões de *Painel Admin* para não-admins e *Forjar Campanha* para jogadores comuns.
5. **`ArcanaTheme` (`lib/core/theme/arcana_theme.dart`):** Gera dinamicamente `ThemeData` para os 3 temas oficiais aplicando `fontScale` (`0.8` a `1.5`) sobre toda a hierarquia tipográfica.
6. **`AppController` (`lib/controllers/app_controller.dart`):** Controla o fluxo de sessão, troca reativa de aba, envio de mensagens no chat híbrido WhatsApp+Discord, rolagem 3d6 ao vivo, criação de campanhas no wizard de 4 etapas, troca de tema em tempo real e simulação segura dos estados de erro/lockout no login.

