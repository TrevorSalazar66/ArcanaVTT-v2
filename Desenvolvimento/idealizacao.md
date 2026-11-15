# ArcanaVTT — Idealização Executiva (Fase 1)

## 1. Visão do Produto
O **ArcanaVTT** é um Virtual Tabletop (VTT) mobile-first para Android projetado especificamente para mesas de RPG rápidas, táticas e comunitárias, unindo a estética **Dark Fantasy Heráldico Moderno** com uma arquitetura de **baixo custo em Edge (Cloudflare Workers + D1)** e **sincronização local-first / P2P WebRTC**.

Em vez de interfaces lentas e cheias de ruído, o ArcanaVTT adota uma linguagem visual inspirada em grimórios arcanos e brasões de cavalaria dourados (`#E5B758`) sobre fundos Obsidian e Void (`#080811` / `#131322`), garantindo legibilidade em até **60 FPS** mesmo em celulares intermediários.

## 2. Público-Alvo & Faixa Etária
- **Jogadores e Mestres de RPG Mobile:** Participantes que desejam entrar numa mesa em segundos pelo celular usando código **Quick Join** (6 dígitos) ou QR Code, gerenciar suas fichas no sistema oficial **AlphaD6 Core** e conversar com sua guilda.
- **Criadores de Sistemas & Homebrews:** Mestres que constroem seus próprios sistemas de regras e compêndios modulares em JSON Delta.
- **Conformidade Legal (LGPD/COPPA):** O acesso ao aplicativo é estritamente reservado a usuários com **16 anos ou mais**, validado no momento da autenticação via Google OAuth 2.0.

## 3. Estética & Princípios Inegociáveis da Experiência
1. **100% Google OAuth 2.0 (Zero Senhas):** Nenhum armazenamento ou campo de senha tradicional. O acesso ocorre via fluxo Google OAuth 2.0 1-Tap, com opção de Dispositivo Confiável (15 a 30 dias em Keystore) e proteção por Hardware Ban / Lockout Total com código via e-mail transacional.
2. **SVG-First & Tolerância Zero a Emojis:** Proibição absoluta de emojis Unicode na interface. Todos os elementos gráficos e ícones utilizam a biblioteca oficial de ícones vetoriais SVG em `assets/icons/*.svg`.
3. **Três Temas Oficiais & Acessibilidade Dinâmica:**
   - *Modo Escuro Heráldico* (padrão)
   - *Modo OLED* (`#000000` absoluto)
   - *Alto Contraste Solar* (pergaminho claro de alta legibilidade)
   - Escala tipográfica dinâmica de `80%` a `150%`.
4. **Chat Comunitário Híbrido (WhatsApp + Discord):** Conversação em tempo real com bolhas diferenciadas (recebidas à esquerda com cargo; enviadas à direita com duplo check), rolagem `3d6` embutida dentro das mensagens, barra de resposta rápida e denúncia universal.

## 4. Escopo Entregue na Fase 1
- **Backend Serverless Cloudflare (`Desenvolvimento/arcana_backend`):** Autenticação OAuth 2.0, Lockout Total, Gateway Unificado `/api/sync`, Banco D1 com 16 tabelas relacionais + JSON Deltas, Segurança Zero-Trust RBAC, Denúncia Universal com autotags e Sinalização P2P com Eleição Dinâmica de Líder.
- **Aplicativo Mobile Flutter (`Desenvolvimento/arcana_app`):**
  - Tela de Login (estados Padrão OAuth, Erro/Bloqueio e Sucesso/Onboarding).
  - Hub Central responsivo (`<600dp` BottomBar, `>=600dp` Sidebar) com Top AppBar, Menu Gaveta com poda RBAC e as 4 abas principais (*Início*, *Campanhas*, *Sistemas*, *Comunidades*).
  - 20 modais primários funcionais (Quick Join, Forja de Campanha 4 etapas, Ficha em Destaque 3d6, Compêndio com ocultação automática de categorias vazias, Painel de Guilda, Fórum, Chat Comunitário híbrido, Lista de Amigos, Tutoriais Sandboxed, Configurações Gerais, Painel Admin, Logout Seguro e Denúncia Universal).

