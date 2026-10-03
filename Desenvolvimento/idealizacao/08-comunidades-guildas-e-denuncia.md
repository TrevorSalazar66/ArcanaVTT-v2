# ArcanaVTT — Módulo 08: Comunidades, Guildas (Shared Worlds) & Denúncia Universal

---

## 🏰 4. Comunidades (Mural da Taverna, Guildas, Fóruns & Clãs)

- **Localização:** 4º item da Barra Inferior (Bottom Navigation Bar).
- **Finalidade:** O grande polo de interação social do ArcanaVTT, integrando a dinâmica de Fóruns do Reddit, múltiplos canais e grupos do Discord, mensageria ágil do WhatsApp e um ecossistema profundo de Guildas e Cenários Compartilhados.

```
┌────────────────────────────────────────────────────────┐
│ [Logo ArcanaVTT]               [🔍 Buscar] [➕ Criar*] │ (Top Bar)
├────────────────────────────────────────────────────────┤
│ [ 📢 Anúncios ] [ 🏰 Guildas ] [ 📜 Fórum ] [ 💬 Grupos ]│ (Segmentos)
├────────────────────────────────────────────────────────┤
│                                                        │
│ 📢 ANÚNCIOS OFICIAIS DA ADMINISTRAÇÃO                  │
│ ┌────────────────────────────────────────────────────┐ │
│ │ 🛡️ Atualização de Segurança & Novo Módulo Guildas   │ │
│ │ Publicado por: @superadmin • Há 2 horas             │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ 🏰 GUILDAS & CENÁRIOS COMPARTILHADOS (Em Alta)         │
│ ┌────────────────────────────────────────────────────┐ │
│ │ 🖼️ [BANNER DA GUILDA]                               │ │
│ │ 👑 "A Ordem do Dragão Astral" — Nível 3 (Prog: 65%) │ │
│ │ 👑 Anfitrião: @mestre_valen • 👥 48/60 Membros       │ │
│ │ ⚔️ 6 Mesas Ativas • 📜 Sistema: AlphaD6 • 🏰 3 Clãs │ │
│ │ 💰 Barra de Nível: [████████████░░░░] R$ 130/R$ 200 │ │
│ │ 📜 Lore: "Universo persistente de fantasia arcana..."│ │
│ │ ────────────────────────────────────────────────── │ │
│ │ [ 📜 Ver Cenário ] [ 💬 Canais ] [ 🚪 Pedir Entrada ]│ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ 📜 FÓRUM DA TAVERNA (Estilo Reddit / Tópicos)          │
│ ┌────────────────────────────────────────────────────┐ │
│ │ 🔼 142 | 💬 38 • [ #dúvidas-regras ] [ #alphad6 ]   │ │
│ │ "Como balancear o dano das armas de pólvora?"       │ │
│ │ Autor: @lucas_bard • Última resposta há 15 min      │ │
│ └────────────────────────────────────────────────────┘ │
│ ┌────────────────────────────────────────────────────┐ │
│ │ 🔼 89  | 💬 19 • [ #recrutamento ] [ #d20 ]         │ │
│ │ "Mesa de Terror Investigativo busca 2 jogadores"    │ │
│ │ Autor: @mestre_gabriel • 📅 Sábados às 20h          │ │
│ └────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```

---

### 🧩 Módulos, Regras & Componentes da Tela de Comunidades

- **🏛️ Arquitetura de Comunicação Tripla (Reddit + Discord + WhatsApp):**
  - **📜 Fórum Comunitário (Estilo Reddit):** Publicações divididas por tópicos temáticos (`#recrutamento`, `#regras`, `#worldbuilding`, `#homebrew`, `#historias`), com sistema de votos positivos/negativos (Upvotes/Downvotes), respostas aninhadas e filtros por engajamento (*Em Alta*, *Mais Recentes*, *Mais Votados*).
  - **💬 Grupos & Canais Comunitários (Estilo Discord):** Espaços sociais com múltiplos canais de texto e chat temático por interesses.
  - **📱 Mensagens Privadas 1-a-1 (Estilo WhatsApp):** Chat direto de alta velocidade, recibos visuais de leitura, histórico criptografado e rolador rápido de dados embutido.

- **📢 Canal Oficial de Anúncios da Taverna:**
  - Espaço exclusivo onde **Admins e Superadmins** publicam avisos de sistema, notas de versão (*patch notes*), comunicados de segurança e eventos globais da plataforma.

- **🏰 Sistema Avançado de Guildas & Cenários Compartilhados (*Shared Worlds*):**
  - Permite a criação de grandes universos persistentes onde múltiplos Mestres e Grupos de Jogadores compartilham o mesmo cenário, sistema de regras e linha temporal.
  - **👑 O Cargo de "Anfitrião" (*Host*):**
    - Cargo supremo e exclusivo do criador da Guilda. Somente o Anfitrião (ou cargos com permissões delegadas) pode aceitar novos membros, promover Mestres e gerenciar os recursos centrais.
  - **💰 Criação & Evolução por Nível Coletivo (*Crowdfunding de Nível / Guild Boost*):**
    - **Criação Inicial (Nível 1):** O usuário com cargo `Mestre` paga uma taxa única para forjar a Guilda.
    - **Evolução Coletiva:** Não apenas o criador, mas **qualquer membro da guilda** pode contribuir financeiramente para "Melhorar a Guilda" com qualquer valor superior à taxa da operadora de pagamentos.
    - **Mecânica de Barra de Progresso:** Ao atingir a meta financeira estipulada para o próximo nível, a Guilda sobe de nível instantaneamente, a barra reseta para `0%` e uma nova meta de aprimoramento é iniciada.
  - **📈 Benefícios Desbloqueados por Nível da Guilda:**
    1. **Capacidade de Membros:** Limite máximo de jogadores aceitos na guilda;
    2. **Vagas de Mestres:** Número de mestres autorizados a criar campanhas dentro do universo da guilda;
    3. **Canais de Chat:** Quantidade de canais de texto liberados na guilda (estilo Discord);
    4. **Número de Clãs (Facções):** Quantidade máxima de Clãs/Subgrupos que podem ser fundados dentro da guilda;
    5. **Cargos Personalizados:** Quantidade de títulos e cargos customizáveis permitidos.
  - **🛡️ Clãs Internos (Facções da Guilda):**
    - Subgrupos que representam facções, ordens de cavaleiros ou corporações dentro da mesma Guilda.
    - Cada Clã herda a mesma cota de cargos personalizados disponíveis na guilda. O Líder do Clã ou o Anfitrião pode programar **gatilhos automáticos de progressão de cargos** (ex: ao completar X missões, ganha a insígnia e privilégios do cargo).
  - **🗺️ Aba de Cenário Compartilhado (*World Wiki*):**
    - Aba exclusiva na guilda onde todos os mestres autorizados colaboram adicionando artigos de cidades, facções, NPCs lendários, artefatos e acontecimentos históricos que moldam o universo compartilhado.
  - **🔍 Visualização Dupla:** As Guildas são listadas tanto na aba **Comunidades** quanto na aba **Campanhas** (com visualização das mesas ativas daquela guilda).

---

### 🚨 Botão de Denúncia Universal (*Global Report* — Regra Global de Moderação Ubíqua)

- **CONCEITO UNIVERSAL:** O Botão de Denúncia não é um ponto único isolado, mas uma **opção padronizada e ubíqua presente em absolutamente todas as interfaces** onde existam conteúdos criados por usuários (desde mensagens de chat individuais até sistemas inteiros de RPG, fichas, campanhas e guildas).
- **Mapeamento Exaustivo dos 7 Grupos de Conteúdo:**
  1. **Perfis de Usuário:** Nome de exibição, `@nickname`, imagem de avatar, banner heráldico e texto de biografia;
  2. **Comunicações & Chat:** Mensagens do Chat da Mesa, mensagens de DMs privadas (1-a-1), mensagens nos canais de texto de Guildas, tópicos criados no Fórum e respostas/comentários de tópicos;
  3. **Campanhas:** Nome da campanha, imagem de capa/banner, ícone/avatar da mesa, sinopse/lore narrativa e tags da mesa;
  4. **Fichas de Personagem:** Nome do personagem, história/background, ilustração/avatar e anotações públicas do jogador;
  5. **Elementos de Compêndio:** NPCs, Ameaças/Monstros, Armas, Equipamentos/Itens, Rituais, Magias, Pistas e Tabelas de Encontros;
  6. **Sistemas de RPG & Pacotes Homebrew:** Nome do sistema de RPG, descrição de regras personalizadas, nomes de perícias e pacotes de expansão homebrew;
  7. **Guildas & Clãs:** Nome da guilda, banner, descrição narrativa, nome de clãs/facções, títulos de cargos personalizados e artigos da Wiki de Cenário (*World Wiki*).

- **📝 Fluxo de Envio pelo Usuário (Modal Obrigatório):**
  - Ao acionar o botão de denúncia em qualquer item, abre-se um modal onde o usuário deve fornecer obrigatoriamente:
    1. **Mensagem Explicativa:** Texto descritivo detalhando o motivo da denúncia;
    2. **Tag Simples da Infração:** Seleção ou digitação da tag de classificação (`#conteudo-improprio`, `#discurso-de-odio`, `#pirataria`, `#assedio`, `#spam`).

- **🏷️ Anexação Automática de Tags de Contexto para Moderadores:**
  - Ao chegar na Central de Moderação do Painel Admin, o sistema anexa **automaticamente uma Tag de Entidade** identificando com precisão o elemento denunciado: `[🏷️ TIPO: USUÁRIO]`, `[🏷️ TIPO: MENSAGEM_CHAT]`, `[🏷️ TIPO: CAMPANHA]`, `[🏷️ TIPO: FICHA_PERSONAGEM]`, `[🏷️ TIPO: SISTEMA_RPG]`, `[🏷️ TIPO: PACOTE_HOMEBREW]`, `[🏷️ TIPO: GUILDA]`, `[🏷️ TIPO: CLÃ]`, `[🏷️ TIPO: TOPICO_FORUM]`, `[🏷️ TIPO: ARTIGO_WIKI]`.

- **Envio de Evidências:** O relatório gera um pacote inviolável contendo a cópia do conteúdo, carimbo de data/hora, identificadores do denunciado e telemetria de hardware (*Device Fingerprint*).

- **🛡️ Anti-Spam & Moderação Descentralizada:**
  - Sistema inteligente de *rate limiting* e cooldowns para mensagens repetitivas ou disparo em massa nos fóruns e chats comunitários (padrão Discord).
  - As diretrizes de publicação em fóruns e chats de guildas são gerenciadas de forma autônoma pelos respectivos anfitriões/criadores.
