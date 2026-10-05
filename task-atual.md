# 📌 ArcanaVTT — Task Atual & Status de Desenvolvimento

---

## 🎯 1. Função deste Arquivo
Este documento atua como o **ponto de ancoragem e sincronização viva do projeto ArcanaVTT**. Ele resume o contexto recente de trabalho, o estado atual das discussões de arquitetura, as decisões tomadas e os próximos passos imediatos para continuidade de desenvolvimento e refinamento por qualquer sessão ou agente.

---

## 🧭 2. Objetivo Atual
Refinar e especificar com máxima precisão ergonômica, mecânica e de dados as **7 sub-abas do Modal Geral da Campanha**, focando no momento na **Aba 5 (Oficina do Mestre)** e no seu macro módulo de **Gerenciamento de Compêndio** (listagem, modal de descrição completa e telas de forja/edição por blocos no-code).

---

## 📜 3. Contexto das Últimas Tarefas Realizadas

1. **Sincronização & Modularização da Documentação:**
   - Sincronização e organização de toda a pasta `Desenvolvimento/idealizacao/` (módulos 01 a 13) e criação do mapa de navegação em `hierarquia-modais.md`.
2. **Refinamento dos 6 Modelos de Cena na Oficina do Mestre:**
   - **🀄 Mahjong & Minas:** Tabuleiro configurável livremente em linhas $\times$ colunas (Modo Fixo até $100 \times 100$ vs Modo Progressivo por rodadas), controle de bombas (Fixo, `%` do total ou Progressivo), dano customizável em PV/Ânima e mapeamento numérico das 8 células adjacentes (Campo Minado).
   - **🔐 Senha & Cofres:** Capacidade livre de **1 a 50 slots** por puzzle, suporte a números, letras e runas SVG, modos de chave Fixa e Aleatória e Sistema Triplo de Dicas escalonado (Texto livre, Multiplicação Global com bordas coloridas e Semáforo RGB posicional por slot).
3. **Oficialização das 5 Categorias Universais do Compêndio:**
   - Todo e qualquer sistema de RPG cadastrado no ArcanaVTT é obrigatoriamente estruturado sobre **5 categorias fixas e imutáveis**:
     1. **`🧪 Itens`**: Consumíveis, poções, tochas, cordas, ferramentas, suprimentos, munições.
     2. **`⚔️ Equipamentos`**: Armas brancas, armas de distância, armaduras, escudos e acessórios vinculados a **slots corporais de equipamento** no estilo *Exiled Kingdoms* (`Cabeca`, `Peitoral`, `Luvas`, `Calcas`, `Botas`, `Mao_Principal`, `Mao_Secundaria`, `Capa`, `Amuleto`, `Anel_1`, `Anel_2`, `Cinto`).
     3. **`🐉 Seres`**: Bestiário completo com fichas de criaturas, monstros, ameaças, aliados e PNJs.
     4. **`✨ Poderes`**: Magias arcanas/divinas, dons sobrenaturais, técnicas marciais, habilidades ativas/passivas e rituais.
     5. **`📜 Pistas`**: Relíquias narrativas, documentos, cartas cifradas, enigmas investigativos e lore.
   - **Capacidade Fixa:** Limite rígido de **100 Homebrews por Categoria por Sistema de RPG** (total de 500 slots por sistema).
4. **Filosofia de Dados: Esqueleto Enxuto & Interpretador Inteligente (*Runtime Parser*):**
   - Banco de dados leve (SQLite/Cloudflare D1) armazenando blocos estruturados em formato enxuto.
   - **Extração de Range Numérico:** O interpretador converte automaticamente fórmulas de dados (ex: `2d6 + 4` $\rightarrow$ `{min: 6, max: 16}`).
   - **Mapeamento Explícito de Variável da Ficha (`target_variable_id`):** Todo efeito mecânico aponta para a variável exata da ficha (ex: `hp_current`, `anima_current`, `sanity_current`) com operações matemáticas padronizadas (`add`, `sub`, `set`).
5. **Governança RBAC e Feedback Visual de Blocos no Compêndio:**
   - O app lê ativamente o cargo do usuário (`Mestre`, `Assistente`, `Jogador`).
   - **Blocos Visíveis (`is_visible: true`):** Texto padrão sem destaque.
   - **Blocos Ocultos (`is_visible: false`):**
     - *Mestre / Assistente:* Fundo das letras em **vermelho vivo translúcido** com ícone `🔒`.
     - *Jogador:* Totalmente expurgados da árvore de renderização (zero pistas visuais).
   - **Elemento 100% Oculto (`is_all_hidden: true`):** O contorno do cartão do elemento fica em **vermelho forte e vibrante**.
   - Adicionado botão **`[ 📜 Descrição Completa ]`** nos cards e botão **`[← Voltar]`** retornando para a Aba 5 da Campanha.

---

## 💡 4. Resumo das Discussões Recentes & Decisões Arquiteturais

- **Teste de Estresse com 3 Sistemas Distintos (D&D 5e, CoC 7e e Genesys):**
  - O esqueleto modular de blocos foi validado para suportar desde poções simples de D&D até tomos com perda de sanidade e tempo de estudo de CoC, e itens com *Boost Dice* narrativos de Genesys sem inchar o banco de dados.
- **Ajustes no Hub da Oficina do Mestre:**
  - O card de *Compêndio* exibe a porcentagem ocupada no total de 500 slots (`📦 Homebrews: X% da Capacidade Usada`).
  - O card de *Mundo* teve o botão de avançar hora removido da tela inicial (mantendo o controle do relógio narrativo dentro do modal fullscreen de Gerenciamento de Mundo).

---

## 🚀 5. Próximo Passo Imediato
- Receber do usuário a lista de elementos e campos que devem compor a **tela de Edição, Visualização e Criação do Compêndio (A Forja por Blocos No-Code)** para montar o sketch/wireframe visual detalhado.
