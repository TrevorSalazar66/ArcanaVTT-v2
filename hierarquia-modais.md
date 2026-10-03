# ArcanaVTT — Arquitetura e Hierarquia de Modais

Este documento é a referência viva e mandatória para a **organização, ergonomia e fluxo de navegação de todos os modais, bottom sheets e caixas de diálogo** do aplicativo ArcanaVTT.

---

## 🌳 1. Estrutura em Árvore Hierárquica de Modais

```text
ArcanaVTT (App Mobile Flutter)
├── 🔝 Top AppBar (Cabeçalho Global)
│   ├── 🔔 [Modal] Central de Notificações
│   └── 👤 [Modal] Perfil Social do Aventureiro (Estilo Discord)
│       ├── ✏️ [Sub-modal] Edição de Perfil Social & Bio
│       ├── 🔗 [Sub-modal] Conexão OAuth de Contas Externas
│       ├── 📊 [Sub-modal] Drill-Down da Vitrine de Métricas
│       ├── 💬 [Modal] Chat Privado / DM 1-a-1
│       │   └── 🎲 [Sub-modal] Rolador de Dados Rápido no Chat
│       └── 🤝 [Modal] Convidar para Campanha (Exclusivo GM)
│
├── 🏠 Início (Home / Dashboard)
│   ├── ⚡ [Modal] Quick Join (Código 6 Dígitos / Scanner QR)
│   ├── ✋ [Modal] Candidatura / Solicitação ao Mestre
│   ├── 🚪 [Modal] Modal Geral da Campanha (As 7 Sub-Abas)
│   │   ├── 📋 Aba 1: Geral
│   │   │   ├── 👥 [Sub-modal] Detalhes do Membro da Mesa
│   │   │   └── 📢 [Sub-modal] Editor do Mural de Avisos (GM)
│   │   ├── 💬 Aba 2: Chats (Até 3 Canais)
│   │   │   ├── ⚙️ [Sub-modal] Configurações de Acesso do Canal (GM)
│   │   │   └── 🎲 [Sub-modal] Rolador de Dados & Macros
│   │   ├── 🎭 Aba 3: Cenas (Os 6 Modelos)
│   │   │   └── 🔄 [Sub-modal] Transição & Seleção de Cena Ativa (GM)
│   │   ├── 📜 Aba 4: Diário da Jornada
│   │   │   ├── 📝 [Sub-modal] Editor de Lore & Resumo de Sessão
│   │   │   ├── 🗺️ [Sub-modal] Visualizador de Mapas com Zoom
│   │   │   ├── ⏰ [Sub-modal] Calendários, Relógios & Progresso
│   │   │   ├── 🎯 [Sub-modal] Detalhes de Missões
│   │   │   └── 🤝 [Sub-modal] Matriz de Facções & NPCs
│   │   ├── 🛠️ Aba 5: Oficina do Mestre (GM)
│   │   │   ├── 👤 [Sub-modal] Forja de NPCs & Monstros/Ameaças
│   │   │   ├── 🗡️ [Sub-modal] Forja de Itens, Armas & Rituais
│   │   │   └── 🎨 [Sub-modal] Editor/Montagem dos 6 Modelos de Cena
│   │   ├── 📄 Aba 6: Personagens
│   │   │   └── 📜 [Sub-modal] Ficha Completa do Herói
│   │   └── ⚙️ Aba 7: Configurações da Mesa (GM)
│   │       ├── 👥 [Sub-modal] Gestão de Membros & Permissões Locais
│   │       ├── 🌫️ [Sub-modal] Iluminação, Fog of War & Mídias
│   │       └── ⚡ [Sub-modal] Reativação de Campanha Inativa (75 dias)
│   ├── ➕ [Modal] Criação de Campanha em 4 Etapas (GM/Admin)
│   │   ├── 🖼️ [Sub-modal] Etapa 1: Identidade Visual & Nome (Nome, Ícone/Logo, Banner)
│   │   ├── ⚙️ [Sub-modal] Etapa 2: Sistema, Vagas (máx 12) & Restrições (Faixa Etária, Tags #)
│   │   ├── 📜 [Sub-modal] Etapa 3: Narrativa, Status (Agendada/Ao Vivo/Free Time) & Horários
│   │   └── 🔒 [Sub-modal] Etapa 4: Visibilidade & Acesso (Pública vs Privada)
│   └── 📄 [Modal] Ficha Completa do Herói em Destaque
│
├── 🎲 Campanhas (Mesas de RPG)
│   ├── 🔍 [Modal] Filtros Avançados de Busca de Mesas
│   ├── ➕ [Modal] Criação de Campanha em 4 Etapas (GM/Admin) [Mesmo fluxo de 4 etapas]
│   │   ├── 🖼️ [Sub-modal] Etapa 1: Identidade Visual & Nome
│   │   ├── ⚙️ [Sub-modal] Etapa 2: Sistema, Vagas (máx 12) & Restrições
│   │   ├── 📜 [Sub-modal] Etapa 3: Narrativa, Status & Agendamento
│   │   └── 🔒 [Sub-modal] Etapa 4: Visibilidade & Acesso
│   ├── ✋ [Modal] Candidatura / Solicitação ao Mestre
│   └── 🚪 [Modal] Modal Geral da Campanha (As 7 Sub-Abas) [Mesmo fluxo]
│
├── 📜 Sistemas (Catálogo & Compêndio)
│   ├── 🔍 [Modal] Filtro Dinâmico de Categorias (Oculta vazias)
│   ├── 👁️ [Modal] Pré-visualização de Sistema / Pacote Homebrew
│   └── 🛠️ [Modal] Forja de Sistema Próprio (Requer Key)
│
├── 🏰 Comunidades (Guildas, Fóruns & Clãs)
│   ├── 🏰 [Modal] Painel de Guilda / Shared World
│   │   ├── ➕ [Sub-modal] Criação de Campanha Vinculada à Guilda (GM Autorizado)
│   │   │   ├── 🖼️ [Sub-modal] Etapa 1: Identidade Visual & Nome
│   │   │   ├── ⚙️ [Sub-modal] Etapa 2: Vagas (máx 12) & Tags (Sistema Base Herdado)
│   │   │   ├── 📜 [Sub-modal] Etapa 3: Narrativa, Status & Agendamento
│   │   │   └── 🔒 [Sub-modal] Etapa 4: Visibilidade & Acesso
│   │   ├── 💰 [Sub-modal] Contribuição de Nível (Guild Boost)
│   │   ├── 🛡️ [Sub-modal] Fundação & Gestão de Clã/Facção
│   │   ├── 🗺️ [Sub-modal] Editor da World Wiki (GM)
│   │   └── 💬 [Sub-modal] Canais de Texto da Guilda
│   ├── 📝 [Modal] Criação de Tópico no Fórum
│   └── 💬 [Modal] Grupo Comunitário de Chat
│
├── 🚪 Navigation Drawer (Menu Lateral)
│   ├── 👤 [Modal] Meu Perfil Social
│   ├── 👥 [Modal] Gestão da Lista de Amigos
│   │   └── ➕ [Sub-modal] Adicionar Amigo por @nickname / QR
│   ├── 📖 [Modal] Central de Tutoriais (Sandboxed Mock Engine)
│   ├── ⚙️ [Modal/Tela] Configurações Gerais
│   │   └── 🚨 [Sub-modal] Confirmação de Lockout Total de Dispositivos
│   ├── 🛡️ [Modal] Painel de Administração (Admin/Superadmin)
│   │   ├── 📊 [Sub-modal] Telemetria Global & Monitoramento P2P Mesh
│   │   ├── 🚨 [Sub-modal] Fila da Denúncia Universal & Evidências
│   │   ├── ⚖️ [Sub-modal] Painel de Votação Colegiada de Punição
│   │   ├── 👥 [Sub-modal] Auditoria de Usuários & Banimento por Hardware
│   │   └── 👑 [Sub-modal] Governança Suprema & Gestão de Admins (Superadmin)
│   └── 🚪 [Modal] Confirmação de Logout Seguro
│
└── 🚨 Opção Ubíqua (Presente em todas as telas e conteúdos)
    └── 🚨 [Modal] Denúncia Universal (Global Report com justificativa e tag)
```

---

## 📋 2. Explicação Resumida dos Modais e Sub-Modais

### 🔝 Modais Globais e de Cabeçalho (Top AppBar)

- **Central de Notificações (`🔔`):**
  - *O que é:* Painel deslizante (*Bottom Sheet*) que lista convites para campanhas, pedidos de amizade, mensagens privadas não lidas e comunicados oficiais da administração.
- **Perfil Social do Aventureiro (Estilo Discord):**
  - *O que é:* Bottom sheet aberta ao tocar no avatar ou `@nickname` de qualquer usuário. Apresenta banner, avatar com status online/jogo, badge de cargo heráldico, biografia, selos de redes vinculadas, mesas em comum (*mutuals*) e atalhos para abrir DM ou convidar para campanha.
  - **Sub-modal: Edição de Perfil Social:** Permite ao dono da conta atualizar nome de exibição, avatar, banner e biografia (até 500 caracteres).
  - **Sub-modal: Conexão OAuth de Contas Externas:** Fluxo de autenticação oficial para vincular Discord, Twitch, YouTube, Steam, Instagram, X e Reddit.
  - **Sub-modal: Drill-Down da Vitrine:** Lista detalhada que se abre ao tocar em qualquer card numérico da vitrine (exibindo histórico de partidas, sistemas jogados e fichas associadas).
- **Chat Privado / Mensagem Direta (DM 1-a-1):**
  - *O que é:* Modal de tela cheia para conversa privada e confidencial entre 2 usuários, sincronizada em tempo real via WebSockets com criptografia em trânsito e isolada de terceiros (com auditoria exclusiva do Superadmin).
  - **Sub-modal: Rolador de Dados Rápido:** Mini-interface no campo de digitação para rolar dados em segredo no chat privado.
- **Convidar para Campanha (Exclusivo para Mestres):**
  - *O que é:* Lista rápida com as campanhas lideradas pelo Mestre para enviar um convite com 1 toque ao jogador visualizado.

---

### 🏠 Modais de Início & Campanhas (Home / Mesas)

- **Quick Join (Entrar com Código):**
  - *O que é:* Modal inferior com leitor de QR Code pela câmera e campo para digitação do código aleatório de 6 dígitos. Se o usuário já participa da mesa, abre o Modal Geral; se não participa, abre o Modal de Candidatura.
- **Candidatura / Solicitação ao Mestre:**
  - *O que é:* Caixa de diálogo onde o jogador digita uma mensagem de apresentação (até 200 caracteres) para a fila do GM. A criação de personagem fica bloqueada até que o Mestre aprove formalmente a entrada.
- **Criação de Campanha em 4 Etapas (GM/Admin):**
  - *O que é:* Modal em formato Wizard composto por **4 sub-modais/etapas conectadas**:
    1. **Sub-modal: Etapa 1 — Identidade Visual & Nome:** Definição do Nome da campanha, upload/seleção do Ícone/Logo e Banner de Capa personalizado.
    2. **Sub-modal: Etapa 2 — Sistema, Vagas & Restrições:** Seleção do Sistema de RPG base, definição de vagas (máx global de 12 jogadores), Faixa Etária (`Livre`, `14+`, `16+`, `18+`) e cadastro de tags personalizadas (#).
    3. **Sub-modal: Etapa 3 — Narrativa, Status & Agendamento:** Registro da Sinopse/lore inicial, definição do Estado da Sessão (`Agendada`, `Ao Vivo`, `Free Time`) e horários das sessões.
    4. **Sub-modal: Etapa 4 — Visibilidade & Acesso:** Configuração de visibilidade entre **Pública** (aberta a buscas e candidaturas) ou **Privada** (oculta, acesso apenas via código de 6 dígitos ou QR Code).
- **Ficha Completa do Herói em Destaque:**
  - *O que é:* Abre a ficha expandida do último personagem ativo do jogador direto da Home, sincronizada em tempo real com a respectiva campanha.
- **Filtros Avançados de Busca de Mesas:**
  - *O que é:* Modal de filtragem para refinar a busca por nome, lore, mestre, sistema, tags personalizadas (#), horários e status (Ao Vivo, Agendada, Free Time).

---

### 🚪 Modal Geral da Campanha (As 7 Sub-Abas da Mesa)

- **Modal Geral da Campanha:**
  - *O que é:* O centro operacional da mesa para quem já participa dela. É composto por 7 sub-abas completas:
  1. **Aba Geral:** Exibe sinopse, sistema, membros, mural de avisos e horários.
     - *Sub-modal: Detalhes do Membro:* Perfil rápido e cargo daquele integrante na mesa.
     - *Sub-modal: Editor do Mural (GM):* Cadastro de recados e avisos pelo Mestre.
  2. **Aba Chats:** Até 3 canais de texto com rolagens, macros e presença online.
     - *Sub-modal: Configurações de Acesso (GM):* Permissões individuais para cada canal.
     - *Sub-modal: Rolador de Dados & Macros:* Menu visual para rolagens de perícias e dados.
  3. **Aba Cenas:** Acesso às cenas ativas conforme o estado da mesa (Ao Vivo, Agendada, Free Time).
     - *Sub-modal: Transição de Cena Ativa (GM):* Painel para o Mestre ativar e alternar entre os 6 modelos de cena.
  4. **Aba Diário da Jornada:** Memória viva da campanha.
     - *Sub-modais:* Editor de Lore/Resumo, Visualizador de Mapas com Zoom, Calendários/Relógios de Progresso, Detalhes de Missões e Matriz de Facções.
  5. **Aba Oficina do Mestre (GM):** Ambiente criativo do Mestre.
     - *Sub-modais:* Forja de NPCs/Monstros, Forja de Itens/Armas/Rituais e Montagem dos 6 Modelos de Cena.
  6. **Aba Personagens:**
     - *Sub-modal: Ficha Completa do Herói:* Visualização e edição interativa de PV, PE, ânima, atributos, perícias e inventário.
  7. **Aba Configurações da Mesa (GM):**
     - *Sub-modais:* Gestão de membros/cargos locais, Fog of War/iluminação e Reativação de Mesa Inativa (após 75 dias).

---

### 📜 Modais de Sistemas & Compêndio

- **Filtro Dinâmico de Categorias:**
  - *O que é:* Menu de filtros que oculta automaticamente categorias vazias para não poluir a interface.
- **Pré-visualização de Sistema / Pacote Homebrew:**
  - *O que é:* Ficha técnica com regras, magias, itens, avaliações em estrelas, contador de mesas ativas e botão para baixar offline via rede P2P Mesh.
- **Forja de Sistema Próprio:**
  - *O que é:* Editor completo para criação de um novo motor de regras do zero (requer *Key de Criação*).

---

### 🏰 Modais de Comunidades (Guildas & Fóruns)

- **Painel de Guilda / Shared World:**
  - *O que é:* Hub do universo compartilhado com visualização de mestres, mesas ativas, clãs internos e canais.
  - **Sub-modal: Criação de Campanha Vinculada à Guilda (GM Autorizado):** Permite a um Mestre com vaga na guilda criar uma nova mesa de jogo inserida no cenário compartilhado, herdando automaticamente as regras da guilda e o vínculo com a World Wiki. Segue as 4 etapas de criação (Identidade, Vagas/Tags, Lore/Status e Visibilidade).
  - **Sub-modal: Contribuição de Nível (Guild Boost):** Painel de crowdfunding onde membros doam valores para subir o nível da guilda.
  - **Sub-modal: Fundação & Gestão de Clã:** Criação de facções internas com cotas de cargos personalizados.
  - **Sub-modal: Editor da World Wiki (GM):** Artigos colaborativos sobre a história, cidades e artefatos do cenário compartilhado.
  - **Sub-modal: Canais de Texto da Guilda:** Salas de conversa da guilda estilo Discord.
- **Criação de Tópico no Fórum:**
  - *O que é:* Editor com seleção de categoria (#), título, formatação markdown e tags livres.
- **Grupo Comunitário de Chat:**
  - *O que é:* Chat de texto temático para interação em tempo real de grupos de interesse.

---

### 🚪 Modais da Navigation Drawer (Menu Lateral)

- **Gestão da Lista de Amigos:**
  - *O que é:* Painel completo com abas de Amigos confirmados (com status online/ausente/em jogo), Solicitações recebidas/enviadas e botão para adicionar amigos por `@nickname` ou QR Code.
- **Central de Tutoriais Interativos:**
  - *O que é:* Experiência visual guiada com balões explicativos (*overlays*) e emulação 100% em memória local (*Sandboxed Mock Engine*) sem gravar dados no servidor.
- **Configurações Gerais & Lockout de Dispositivos:**
  - *O que é:* Ajuste de idiomas, temas (OLED), mixer de áudio e governança P2P.
  - **Sub-modal: Lockout Total:** Diálogo de segurança que revoga todas as sessões, tranca a conta e envia e-mail de revalidação gratuita via Resend/Brevo.
- **Painel de Administração (Admin / Superadmin):**
  - *O que é:* Painel blindado (*Tree Pruning + Zero-Trust Gateway*) dividido em 5 submódulos:
    1. *Telemetria P2P:* Monitoramento de recursos e nós ativos da rede.
    2. *Fila de Denúncias:* Lista com tags automáticas de entidade (`[🏷️ TIPO: ...]`) e pacote inviolável de evidências.
    3. *Votação Colegiada:* Sistema que exige 3 votos de Admins para punições graves.
    4. *Auditoria & Banimento por Hardware:* Consulta de e-mails privados OAuth e lista negra de identificadores de hardware (MAC, UUID, Widevine).
    5. *Governança Suprema (Superadmin):* Gestão de admins e auditoria total de mensagens privadas.
- **Confirmação de Logout Seguro:**
  - *O que é:* Caixa de diálogo que invalida o JWT no Cloudflare Worker, apaga as chaves no *Android Keystore* e reseta o estado local.

---

### 🚨 Modal Ubíquo: Denúncia Universal (Global Report)

- **Denúncia Universal:**
  - *O que é:* Caixa de diálogo padrão presente nos menus de 3 pontos em absolutamente todos os 7 grupos de conteúdo criados por usuários (Perfis, Chats/DMs, Campanhas, Fichas, Compêndio, Sistemas/Homebrews e Guildas/Clãs).
  - *Funcionamento:* Exige justificativa explicativa e tag da infração (`#conteudo-improprio`, `#discurso-de-odio`, `#pirataria`, `#assedio`, `#spam`), anexando automaticamente o pacote de telemetria e evidências para a moderação.
