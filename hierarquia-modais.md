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
│   │   ├── 🛠️ Aba 5: Oficina do Mestre (Hub Central de Criação em 3 Macro Módulos Fullscreen - GM)
│   │   │   ├── 🎬 [Macro Módulo Fullscreen] Gerenciamento de Cenas (Até 18 Cenas)
│   │   │   │   ├── 🎨 [Editor/Visualizador] Pintura 2D (3 Layers, Snap, Raycasting, Fog), Mahjong, Cofres, etc.
│   │   │   │   └── ⚡ [Editor de Gatilhos] Construtor No-Code [QUANDO] ➔ [SE] ➔ [ENTÃO] com 🎯 Capturar Alvo
│   │   │   ├── 📚 [Macro Módulo Fullscreen] Gerenciamento de Compêndio (As 5 Categorias Universais)
│   │   │   │   ├── 📜 [Sub-modal] Descrição Completa do Elemento (Leitura por Blocos com RoleGate RBAC)
│   │   │   │   └── ➕ [Sub-modal] Forja / Edição de Elemento em Blocos No-Code (Herança Delta & target_variable_id)
│   │   │   └── 🌍 [Macro Módulo Fullscreen] Gerenciamento de Mundo (Worldbuilding & Cronologia)
│   │   │       ├── 🗺️ [Sub-modal] Atlas Overworld Hexagonal (Até 25 Mapas com Notas Hiperlinkadas)
│   │   │       ├── ⏳ [Sub-modal] Relógio & Calendário Procedural do Zero (Controle Narrativo)
│   │   │       ├── 🏛️ [Sub-modal] Gestor de Facções & Reputação (-100 a +100)
│   │   │       └── 📜 [Sub-modal] Bloco de Notas Hierárquico do Mestre (4 Sub-Abas)
│   │   ├── 📄 Aba 6: Personagens
│   │   │   └── 📜 [Sub-modal] Ficha Completa do Herói
│   │   └── ⚙️ Aba 7: Configurações da Mesa (GM)
│   │       ├── 👥 [Sub-modal] Gestão de Membros & Permissões Locais (Master-Level Ban)
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
│   ├── ✋ [Modal] Candidatura / Solicitação ao Mestre
│   └── 🚪 [Modal] Modal Geral da Campanha (As 7 Sub-Abas) [Mesmo fluxo]
│
├── 📜 Sistemas (Catálogo & Compêndio)
│   ├── 🔍 [Modal] Filtro Dinâmico de Categorias (Oculta vazias)
│   ├── 👁️ [Modal] Pré-visualização de Sistema / Pacote Homebrew (5 Categorias Universais)
│   └── 🛠️ [Modal] Forja de Sistema Próprio (Requer Key)
│
├── 🏰 Comunidades (Guildas, Fóruns & Clãs)
│   ├── 🏰 [Modal] Painel de Guilda / Shared World
│   │   ├── ➕ [Sub-modal] Criação de Campanha Vinculada à Guilda (GM Autorizado)
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

### 🚪 Modal Geral da Campanha (As 7 Sub-Abas da Mesa)

1. **Aba Geral:** Exibe sinopse, sistema, membros, mural de avisos e horários.
2. **Aba Chats:** Até 3 canais de texto com rolagens, macros e presença online.
3. **Aba Cenas:** Acesso às cenas ativas conforme o estado da mesa (Ao Vivo, Agendada, Free Time).
4. **Aba Diário da Jornada:** Memória viva da campanha (crônicas, notas, mapa e facções).
5. **Aba Oficina do Mestre (GM):** Hub Central de criação fullscreen dividido em 3 macro módulos:
   - *Gerenciamento de Cenas:* Editor e simulador dos 6 modelos com construtor no-code `[QUANDO] ➔ [SE] ➔ [ENTÃO]` e botão `🎯 Capturar Alvo`.
   - *Gerenciamento de Compêndio:* As **5 Categorias Universais Fixas** (*Itens, Equipamentos com slots corporais, Seres, Poderes, Pistas*), com limite de 100 homebrews por categoria por sistema, herança delta, interpretador inteligente com parsing de range numérico `{min, max}`, mapeamento `target_variable_id`, modal de **Descrição Completa** e destaque cromático RBAC (vermelho translúcido para Mestre).
   - *Gerenciamento de Mundo:* Atlas Overworld Hex Grid (até 25 mapas), Relógio e Calendário procedural narrativo, Facções (-100 a +100) e Bloco de Notas em 4 sub-abas.
6. **Aba Personagens:** Fichas resumidas e completas dos jogadores sincronizadas em tempo real via P2P Mesh.
7. **Aba Configurações da Mesa (GM):** Gestão de membros, banimento em nível de Mestre (*Master-Level Ban*), automação de ações, ritmo de XP e integrações Discord.
