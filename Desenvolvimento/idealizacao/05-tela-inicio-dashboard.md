# ArcanaVTT — Módulo 05: Tela de Início (Home / Dashboard)

---

## 🏠 1. Início (Home / Dashboard)

- **Localização:** 1º item da Barra Inferior (Bottom Navigation Bar).
- **Finalidade:** Centro de comando e boas-vindas da Taverna para acesso instantâneo às mesas, entrada rápida e visão geral do jogador.

```
┌────────────────────────────────────────────────────────┐
│ [Logo ArcanaVTT]               [🔔 (3)] [👤 @nickname] │ (Top Bar)
├────────────────────────────────────────────────────────┤
│ 👑 "Saudações, Mestre @arthur!"                         │ (Hero Header)
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │ ⚡ ENTRAR COM CÓDIGO DA MESA                        │ │ (Quick Join)
│ │ [ Código de 6 dígitos: ______ ] [📷 QR] [Entrar]   │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ ⚔️ CONTINUAR A JORNADA (Minhas Mesas Recentes)        │
│ ┌───────────────────────┐  ┌────────────────────────┐  │ (Carrossel
│ │ 🔴 [AO VIVO AGORA]   │  │ 🟢 [FREE TIME]         │  │  Horizontal
│ │ "A Torre das Sombras" │  │ "Mina dos Anões"       │  │  Mesas que
│ │ Sistema: AlphaD6      │  │ Sistema: AlphaD6       │  │  Participa)
│ │ Meu Herói: Valen Mago │  │ Meu Herói: Thorin       │  │
│ │ [ 👉 Entrar na Mesa ] │  │ [ 👉 Entrar na Mesa ]  │  │
│ └───────────────────────┘  └────────────────────────┘  │
│                                                        │
│ 📜 HERÓI EM DESTAQUE (Último Personagem Ativo)        │ (Card Rápido)
│ ┌────────────────────────────────────────────────────┐ │
│ │ [Avatar] Valen de Lorien — Nv. 3 Mago Arcano       │ │
│ │ PV: [████████░░] 24/30  | PE: [██████████] 15/15   │ │
│ │                        [ 📄 Abrir Ficha Completa ] │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ 📢 MURAL DE NOVIDADES DA TAVERNA                       │ (Feed de Notícias)
│ ┌────────────────────────────────────────────────────┐ │
│ │ 🌟 Atualização v2.1: Novo modelo de cena Terminal  │ │
│ │ 📚 Módulo de Regras AlphaD6 atualizado             │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ ⚡ CHIPS DE AÇÃO RÁPIDA (Zona Inferior)                │
│ [🎲 Criar Campanha*]              [📖 Guia da Taverna] │
└────────────────────────────────────────────────────────┘
```

---

### 🧩 Módulos e Componentes da Tela de Início

- **👑 Hero Header & Saudação Dinâmica:**
  - Saudação personalizada calculada conforme horário local e cargo (*"Saudações matinais, Mestre @arthur"*, *"Boa noite, Aventureiro @lucas"*).
  - Sininho de Notificações com badge de contador de alertas pendentes.

- **⚡ Módulo "Entrar com Código da Mesa" (*Quick Join*):**
  - **Código Alfanumérico de 6 Dígitos:** Conjunto de 6 caracteres inteiramente aleatórios (letras e números aleatórios, podendo haver repetição de caracteres, sem prefixo fixo; ex: `K8F2M9`, `99AXB1`).
  - Botão de Câmera (*QR Code Scanner*) para leitura do código exibido pelo Mestre.
  - **Validação de Entrada & Regras de Acesso:**
    - *Se o usuário JÁ PARTICIPA da mesa:* Redireciona imediatamente e abre o **Modal Geral da Campanha** (onde o usuário tem acesso às sub-abas e modais internos da mesa).
    - *Se o usuário AINDA NÃO PARTICIPA da mesa:* Abre o **Modal de Candidatura / Solicitação ao Mestre**, onde envia o pedido para a Fila de Espera do Mestre.

- **⚔️ Carrossel Horizontal "Continuar a Jornada" (Minhas Mesas Recentes):**
  - Exibe **exclusivamente as campanhas nas quais o usuário já participa** e que estejam nos estados `🔴 AO VIVO` ou `🟢 FREE TIME`, ordenadas pela última partida/acesso recente.
  - **Único Botão no Card:** Apenas o botão **`[ 👉 Entrar na Mesa ]`**, que abre o **Modal Geral da Campanha** (o qual gerencia o ingresso na cena ativa, diário de bordo e ficha).

- **📜 Card "Herói em Destaque":**
  - Miniatura do último personagem ativo com dados básicos (Avatar, Nome, Raça, Classe, Nível, barras de PV e PE).
  - **Único Botão:** Botão destacado **`[ 📄 Abrir Ficha Completa ]`**, expandindo o Sheet completo do personagem vinculado à sua respectiva campanha.

- **📢 Mural de Novidades da Taverna:**
  - Feed com notas de atualização do ArcanaVTT, novos compêndios lançados e avisos oficiais da administração.

- **⚡ Chips de Ação Rápida (Atalhos Inferiores):**
  - Botões de atalho: `[🎲 Criar Campanha]` (renderizado exclusivamente para contas com cargo `Mestre`, `Admin` ou `Superadmin`) e `[📖 Guia da Taverna]` (Central de Tutoriais por Macro Função).
  - **Nota Arquitetural Rígida:** Personagens **NUNCA são criados soltos na Home**; a criação de personagem ocorre **obrigatoriamente vinculada a uma campanha específica** em que o usuário joga como jogador.
