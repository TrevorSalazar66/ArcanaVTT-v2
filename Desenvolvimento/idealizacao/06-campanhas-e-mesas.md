# ArcanaVTT — Módulo 06: Campanhas (Mesas de RPG, Candidatura & Sub-Abas)

---

## 🎲 2. Campanhas (Mesas de RPG)

- **Localização:** 2º item da Barra Inferior (Bottom Navigation Bar).
- **Finalidade:** Central de comando para busca universal de mesas, acompanhamento de partidas ativas (como jogador, assistente ou mestre) e gerenciamento de campanhas.

```
┌────────────────────────────────────────────────────────┐
│ [Logo ArcanaVTT]               [🔍 Buscar] [➕ Criar*]│ (Top Bar)
├────────────────────────────────────────────────────────┤
│  [ ⚔️ Jogando (3) ]  [ 🛡️ Auxiliar (1) ]  [ 🧙‍♂️ Mestre (2) ]│ (Segmentos)
├────────────────────────────────────────────────────────┤
│                                                        │
│ 🔍 BARRA DE PESQUISA UNIVERSAL & FILTROS MULTICAMADA   │
│ [ 🔎 Pesquisar por nome, lore, mestre, regras... ]     │
│ Tags: [ #terror ] [ #alphad6 ] [ #investigacao ] [ + ] │
│                                                        │
│ 📋 LISTA DE CAMPANHAS (Cards Ricos & Interativos)      │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │ 🖼️ [BANNER DE CAPA]                                │ │
│ │ 🔴 AO VIVO | "A Torre das Sombras"                 │ │
│ │ [Ícone] Sistema: AlphaD6 • Mestre: @gabriel_mestre │ │
│ │ 📜 Lore: "Um mal ancestral desperta sob as ruínas..."│ │
│ │ 👥 Vagas: 4/5 • 📅 Sessões: Sábados às 20:00       │ │
│ │ 🏷️ Tags: #investigacao #terror #darkfantasy        │ │
│ │ Meu Papel: ⚔️ Jogador (Herói: Valen Mago Nv. 3)    │ │
│ │ ────────────────────────────────────────────────── │ │
│ │ [ 🚪 Entrar no Modal da Campanha ]                 │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │ 🖼️ [BANNER DE CAPA]                                │ │
│ │ 📅 AGENDADA | "O Chamado das Profundezas"          │ │
│ │ [Ícone] Sistema: D&D 5e • Mestre: @lucas_gm        │ │
│ │ 👥 Vagas: 2/5 • 📅 Sessões: Terças às 19:30        │ │
│ │ 🏷️ Tags: #dnd5e #medieval #iniciantes              │ │
│ │ Meu Papel: 🔍 Não Participa (Campanha Pública)     │ │
│ │ ────────────────────────────────────────────────── │ │
│ │ [ ✋ Candidatar-se ]                               │ │
│ └────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

---

### 🧩 Módulos, Regras & Componentes da Tela de Campanhas

- **🔍 Barra de Pesquisa Universal & Segmentação por Papel:**
  - A ferramenta de busca pesquisa em **todas as campanhas da plataforma**, permitindo filtrar por qualquer campo do card (nome, lore/sinopse, mestre, sistema, tags ou horário).
  - **Identificação Visual Segmentada do Usuário:**
    - ⚔️ *Como Jogador:* Campanhas onde o usuário é um herói ativo com ficha vinculada;
    - 🛡️ *Como Assistente de Mestre:* Campanhas onde possui permissões delegadas pelo Mestre;
    - 🧙‍♂️ *Como Mestre:* Campanhas criadas e lideradas pelo usuário;
    - 🔍 *Campanhas Disponíveis:* Campanhas do ecossistema que o usuário ainda não integra.

- **🖼️ Anatomia do Card de Campanha:**
  - **Avatar/Ícone da Mesa:** Ícone temático selecionado da galeria integrada (SVG/WEBP) ou link externo.
  - **Banner de Capa:** Imagem panorâmica de cabeçalho da mesa.
  - **Lore Básica / Sinopse:** Resumo narrativo do enredo e proposta da mesa.
  - **Sistema de RPG Base:** Identificação do motor de regras daquela história.
  - **Contador de Vagas:** Exibição clara de vagas ocupadas vs limite máximo (máx global de 12 jogadores).
  - **Data e Horário das Sessões:** Cronograma semanal/mensal das partidas.
  - **Indicação do Mestre:** `@nickname` do criador (clicável para visualizar o perfil e abrir DM direta).
  - **Tag Geral de "Estado da Sessão" (`estadoDaSessao`):**
    1. 📅 **`Agendada`:** A campanha só tem partidas ativas nas datas e horários estipulados no calendário;
    2. 🔴 **`Ao Vivo`:** A sessão está ocorrendo no momento com jogadores ativos, **exclusivamente quando o Mestre está online com a campanha aberta no app**;
    3. 🟢 **`Free Time` (Tempo Livre):** Acesso contínuo onde os jogadores podem entrar e interagir nas cenas a qualquer hora, com ou sem a presença do Mestre (ideal para puzzles assíncronos, exploração, mineração no Mahjong e roleplay textual).
  - **Tags Personalizadas:** Até 24 caracteres por tag, sem espaços em branco (ex: `#terror`, `#alphad6`, `#sandbox`, `#iniciantes`), facilitando buscas e categorização.

- **👑 Botão [➕ Criar Campanha] (Fluxo de Criação em 4 Etapas Conectadas):**
  - Renderizado **exclusivamente para usuários com cargo `Mestre`, `Admin` ou `Superadmin`**. Usuários com cargo `Jogador` não possuem o botão na interface nem permissão de chamada no backend.
  - **Fluxo em 4 Etapas Conectadas:**
    1. **Etapa 1 — Identidade Visual & Nome:** Definição do Nome da campanha, upload/seleção do Ícone/Logo e Banner de Capa personalizado.
    2. **Etapa 2 — Sistema, Vagas & Restrições:** Seleção do Sistema de RPG base, definição do número máximo de jogadores (máximo global fixo de **12 usuários por mesa**), Faixa Etária (ex: `Livre`, `14+`, `16+`, `18+`) e cadastro de Tags livres (#).
    3. **Etapa 3 — Narrativa, Status & Agendamento:** Registro da Sinopse/lore inicial, definição do Estado da Campanha (`Agendada`, `Ao Vivo`, `Free Time`) e especificação de datas e horários das sessões.
    4. **Etapa 4 — Visibilidade & Acesso:** Definir se a campanha é **Pública** (visível em buscas e listagens gerais da Taverna, onde qualquer usuário pode enviar candidatura) ou **Privada** (oculta de buscas, permitindo ingresso exclusivamente via código aleatório de 6 dígitos ou QR Code).

- **✋ Regra de Candidatura ao Mestre (`[ ✋ Candidatar-se ]`):**
  - Quando o usuário visualiza uma mesa que **não participa**, o card exibe o botão **`[ ✋ Candidatar-se ]`**.
  - Ao clicar, abre-se o **Modal de Candidatura / Solicitação ao Mestre**:
    - O candidato digita uma mensagem de apresentação de **até 200 caracteres** explicando seu interesse e perfil de jogador.
    - **REGRA RÍGIDA DE CRIAÇÃO DE PERSONAGEM:** O personagem **NÃO é forjado nem vinculado durante a candidatura**. Apenas **APÓS o Mestre aceitar formalmente o jogador na campanha** é que a funcionalidade de criação e vinculação do personagem é liberada dentro da mesa.

- **📌 Estrutura dos Modais Internos da Campanha (As 7 Sub-abas do Modal Geral da Campanha):**
  Ao tocar no botão `[ 🚪 Entrar no Modal da Campanha ]` em qualquer mesa na qual o usuário **já participa** (como Mestre, Assistente ou Jogador), abre-se a interface geral da mesa dividida em **7 sub-abas dedicadas**:

  1. **Aba 1: Geral:**
     - Sinopse completa da história e proposta da mesa.
     - Sistema de RPG base selecionado.
     - Lista de usuários membros com seus respectivos cargos (`Mestre`, `Assistente de Mestre`, `Jogador`).
     - Datas e horários oficiais das sessões.
     - Mural de Avisos cadastrados pelo Mestre.
     - Faixa etária da campanha.
     - Número máximo de jogadores (limite global fixo de 12 usuários).
     - Logo e Banner personalizados da campanha.
     - Contador numérico de sessões que já ocorreram.
  2. **Aba 2: Chats (Comunicação, Rolagens & Cards Interativos):**
     - Contém **até 3 chats independentes** criados, nomeados e configurados pelo Mestre da campanha (ex: `#geral-mesa`, `#off-topic`, `#segredos-sussurros`).
     - **Seletor de Persona ("Falar Como..."):** Dropdown no rodapé de digitação permitindo alternar rapidamente a identidade da mensagem:
       - 🛡️ *Meu Personagem Ativo (In-Character / IC):* Fala narrativa identificada pelo avatar e nome do herói;
       - 💬 *Jogador (Out-of-Character / OOC):* Marcado com a tag `[OOC]` e avatar do usuário;
       - 👑 *Mestre / Narrador:* Borda ornamentada dourada e tipografia solene para narrações de cena;
       - 🎭 *NPC Personalizado (Exclusivo Mestre):* Mini-modal rápido para escolher nome e retrato de qualquer PNJ.
     - **Cards Interativos de Moderação de Ações:**
       - Comandos de ação crítica disparados por jogadores (como descansos, curas ou transições de estado) geram cards visuais no chat.
       - Se a regra de aprovação estiver ativa, o card exibe botões **`[ 🟢 Aceitar ]`** e **`[ 🔴 Recusar ]`** operáveis exclusivamente pelo Mestre ou Assistente de Mestre.
     - **Barra de Dados Rápidos (*Dice Toolbar*):**
       - Acesso instantâneo a rolagens de 1 toque (D6, D20, atributos da ficha, iniciativa e descansos).
     - **Comandos & Governança de Chat:**
       - Suporte a `/w @jogador` (sussurros privados e seguros), `/gmroll` (rolagens ocultas do mestre visíveis apenas para a liderança da mesa), `/me` (ações narrativas em itálico iluminado), além de comandos de exclusão e limpeza autorizados para o Mestre.
     - Lista de usuários online no aplicativo e "jogando" naquela campanha específica (interface estilizada no formato de canais do Discord).
  3. **Aba 3: Cenas:**
     - Cards com as cenas que o Mestre criou e configurou como "ativas" na campanha.
     - **Reação Direta ao Status da Campanha:**
       - *🔴 Ao Vivo:* Jogadores só interagem na ficha, chats e cenas ativas quando o Mestre está presente online na mesa;
       - *📅 Agendada:* Jogadores só interagem durante a Janela de Horário oficial da sessão agendada;
       - *🟢 Free Time:* Jogadores podem entrar e interagir nas cenas a qualquer momento (24/7).
  4. **Aba 4: Diário da Jornada (Crônicas, Lore & Reputação de Facções):**
     - **Hierarquia de Notas:**
       - *Crônicas da Campanha:* Resumos oficiais das sessões editáveis por Mestre, Assistente ou Jogador-Escriba;
       - *Diário Pessoal do Aventureiro:* Anotações privadas de cada jogador sobre pistas, objetivos e memórias;
       - *Anotações Secretas do Mestre:* Lore oculta, roteiros de encontros futuros e estatísticas de bastidores.
     - **Linha do Tempo Cronológica (World Timeline):**
       - Registro histórico dos acontecimentos ancorados na data oficial do Relógio da Campanha.
     - **Matriz de Relacionamento com Facções & NPCs:**
       - Painel de organizações e guildas com barra de reputação dinâmica (de `-100 Hostil` a `+100 Reverenciado`), permitindo gatilhos no-code em cenas.
     - *Organização:* Tudo estruturado em camadas de modais interligados exibidos como cards clicáveis.
  5. **Aba 5: Oficina do Mestre (Hub Central de Criação em 3 Macro Módulos Fullscreen):**
     - Ambiente de criação exclusivo do Mestre criador da campanha, subdividido em 3 grandes interfaces modais em tela cheia:
       1. **🎬 Gerenciamento de Cenas (Até 18 Cenas por Campanha):**
          - Construtor e gerenciador dos 6 modelos de cena (Grid 2D, Mahjong & Minas, Senha/Cofre, Menus Conectados, Combate JRPG, Terminal).
          - Split drawer lateral com cards compactos, moldura dourada na cena selecionada para edição, chave On/Off de visibilidade (Ativa/Oculta) e 3 sub-abas no editor:
            - *Geral:* Nome, descrição narrativa, limite de jogadores simultâneos e documentação do modelo;
            - *Visualizar / Editor:* Seletor duplo para alternar entre modo de pintura/edição e modo visualizador para simular a gameplay do jogador antes da sessão;
            - *Gatilhos & Automação No-Code:* Construtor por blocos `[QUANDO] ➔ [SE] ➔ [ENTÃO]` com botão `🎯 Capturar Alvo`.
       2. **📚 Gerenciamento de Compêndio (Até 100 Homebrews por Tipo):**
          - Biblioteca de elementos customizados (Itens Consumíveis, Equipamentos/Armas, Criaturas/NPCs, Poderes, Pistas), baseada em **Herança Delta semi-dependente** (armazena apenas as alterações feitas pelo mestre em relação ao registro pai).
          - Assets fixos por tipo base e modal de inspeção com **controle granular de visibilidade de variáveis** (`is_visible: boolean` por campo) e gatilhos de revelação progressiva.
       3. **🌍 Gerenciamento de Mundo (Cronologia, Overworld & Lore):**
          - **🗺️ Atlas Global em Grids Hexagonais (*Overworld Hex Grid*):**
            - Matriz visual baseada em hexágonos com terrenos vetoriais SVG (montanhas, vilarejos, ruínas, florestas, rios).
            - *Interatividade Hexágono ➔ Nota:* Ao tocar em qualquer hexágono do mapa, abre-se instantaneamente a **Nota de Lore** vinculada àquele território.
            - *Névoa de Guerra & Visibilidade Individual:* Chave On/Off global do mapa e individual por hexágono (os jogadores só enxergam as notas e terrenos que o mestre liberar).
            - *Capacidade Rígida:* Limite de até **25 Mapas Globais por Campanha**.
          - **🔗 Wiki Interna com Hiperlinks Interconectados:**
            - Sistema de links rápidos dentro das notas que abrem diretamente **outras notas específicas** ou **cards do Compêndio** (armas, monstros, NPCs, leis) em camadas modais sobrepostas.
          - **⏳ Relógio do Mundo & Calendário Procedural do Zero:**
            - *Criação de Calendários Cósmicos:* O mestre define dias e semanas por mês, número de meses no ano, horas do dia, proporção de **Luz / Escuridão (ciclo Sol/Lua)** e estações do ano com sua duração.
            - *Geração Procedural de Meses:* Botão `[ + Adicionar Mês ]` e cadastro de eventos astronômicos e feriados fixos/recorrentes (solstícios, luas de sangue, eclipses).
            - *Relógio Narrativo por Eventos:* O tempo **nunca avança sozinho em tempo real**; avança exclusivamente com ações dos jogadores (descansos de 2h/6h/8h ou restaurações de 24h) ou comando manual do Mestre (`+1h`, `+1 dia`, `Amanhecer`, `Anoitecer`), podendo disparar gatilhos no-code em datas específicas.
            - *Linha do Tempo (Cronologia):* Painel visual para o mestre registrar a história do **Passado** (lore antiga) e o planejamento do **Futuro** da campanha.
          - **🏛️ Facções, Reputação & Influência:**
            - Cadastro de organizações (reinos, guildas, cultos, ordens de cavalaria) com **Barra de Reputação manual** variando de **`-100 Hostil`** a **`0 Neutro`** a **`+100 Aliado/Reverenciado`**.
            - Integração direta com condicionais do motor no-code: `[SE reputacao_guilda >= 50] ➔ Desbloquear passagem`.
          - **📜 Bloco de Notas Hierárquico do Mestre (4 Sub-Abas):**
            1. *Anotações Secretas do Mestre:* Segredos de bastidores, planos e rascunhos (100% privadas);
            2. *Diário dos Jogadores:* Anotações dos aventureiros com moderação do mestre;
            3. *Gestão de Visibilidade On/Off:* Controle individual de quais notas são públicas para a mesa;
            4. *Criação de Roteiros de Sessão:* Planejamento encadeado de encontros, diálogos e arcos narrativos futuros.
  6. **Aba 6: Personagens:**
     - Exibição de cards clicáveis com as fichas resumidas e completas dos jogadores da campanha, sempre atualizadas em tempo real via P2P Mesh.
  7. **Aba 7: Configurações da Campanha & Governança da Mesa:**
     - Painel exclusivo do Mestre criador para configurar todos os aspectos operacionais da mesa:
       - **Gestão de Participantes & Solicitações:** Aceitar/negar candidaturas, expulsar aventureiros da mesa e promover/rebaixar para o cargo de *Assistente de Mestre*.
       - **👑 Banimento em Nível de Mestre (*Master-Level Ban*):** O Mestre pode banir um jogador infrator não apenas da mesa atual, mas de **todas as suas campanhas atuais e futuras**. O usuário banido é expulso de todas as mesas daquele mestre e impedido de se candidatar novamente, com tela dedicada para o mestre gerenciar e revogar desbanimentos quando desejar.
       - **Automação de Ações (`auto_approve_actions`):** Toggle que define se descansos e curas são aplicados instantaneamente ou se exigem aprovação manual do Mestre/Assistente via card no chat.
       - **Acesso a Cenas Ativas (`scene_access_mode`):** Modo *Livre* (qualquer jogador entra nas cenas ativas) vs *Sob Convocação/Aprovação* (jogadores aguardam autorização do mestre).
       - **Multiplicador de Ritmo de XP ($M$):** Seletor de velocidade de progressão (Rápido $0.75\times$, Normal $1.0\times$, Desafiador $1.5\times$).
       - **Comunicação & Integração Discord:** Campo para link direto da sala de voz Discord (com botão de 1 toque no app) e Webhook para notificações de sessão.
  - **🚪 Botão de Sair da Campanha:**
     - Botão destacado no rodapé da mesa que encerra a visualização e retorna o usuário instantaneamente para a aba inicial (Home) do aplicativo.

- **🧹 Política de Inatividade & Limpeza de Servidor (75 Dias):**
  - **Custo Zero & Otimização Cloudflare:** Se uma campanha ficar **mais de 75 dias consecutivos sem qualquer atividade** (sem acessos às cenas, sem novas mensagens no chat, sem rolagens ou atualizações de ficha):
    - A campanha é **automaticamente removida da base em nuvem (Cloudflare D1)** para não consumir recursos ociosos de banco.
    - **Backup Local Integral no Aparelho do Mestre:** A campanha permanece 100% preservada na memória local do celular do Mestre, marcada com o selo visual `[💾 Desativada por Inatividade / Salva Localmente]`.
    - **Reativação em 1 Toque:** O Mestre pode clicar no botão destacado **`[ ⚡ Reativar Campanha no Servidor ]`** a qualquer momento para subir o estado de volta para a nuvem e retomar as sessões.
