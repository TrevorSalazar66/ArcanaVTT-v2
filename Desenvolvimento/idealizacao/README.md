# ArcanaVTT — Tríade 1: Idealização & GDD Modular

Este diretório contém a **Idealização Completa & Game Design Document (GDD)** do **ArcanaVTT**, dividida modularmente por macro funções e domínios do sistema para garantir foco cirúrgico, máxima qualidade e profundidade nos detalhes de engenharia.

---

## 🗺️ Mapa de Macro Módulos

| Arquivo | Macro Módulo / Domínio | Conteúdo Principal |
| :--- | :--- | :--- |
| **[01-visao-geral-e-rbac.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/Desenvolvimento/idealizacao/01-visao-geral-e-rbac.md)** | Visão Geral & Governança | Propósito do app, pilares (No-Code, Custo Zero, Mobile-First), hierarquia RBAC (Jogador, Mestre, Admin, Superadmin) e regra de rebaixamento local. |
| **[02-autenticacao-e-seguranca.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/Desenvolvimento/idealizacao/02-autenticacao-e-seguranca.md)** | Autenticação & Identidade | OAuth 2.0 / OpenID Connect, bloqueio < 16 anos, sessões progressivas (15/30 dias), telemetria profunda, Hardware Ban e Lockout via Resend/Brevo. |
| **[03-perfil-social-dms-e-vitrine.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/Desenvolvimento/idealizacao/03-perfil-social-dms-e-vitrine.md)** | Perfil Social & Mensagens | Ficha de perfil estilo Discord, contas vinculadas (7 redes), DMs 1-a-1 com isolamento e auditoria do Superadmin, e Vitrine da Taverna com Drill-Down. |
| **[04-configuracoes-privacidade-e-amigos.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/Desenvolvimento/idealizacao/04-configuracoes-privacidade-e-amigos.md)** | Configurações & Preferências | Idiomas (PT/EN/ES), haptic feedback, 3 temas visuais (OLED #000000), mixer de áudio 4 canais, governança P2P Mesh e Lista de Amigos do aventureiro. |
| **[05-tela-inicio-dashboard.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/Desenvolvimento/idealizacao/05-tela-inicio-dashboard.md)** | Hub & Dashboard | Hero Header dinâmico, Quick Join (6 dígitos aleatórios / QR Code), Carrossel de Mesas Recentes, Herói em Destaque e Mural de Novidades. |
| **[06-campanhas-e-mesas.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/Desenvolvimento/idealizacao/06-campanhas-e-mesas.md)** | Campanhas & Mesas | Criação em 4 etapas, candidatura ao mestre, As 7 Sub-abas do Modal da Campanha (Geral, Chats, Cenas, Diário, Oficina, Personagens, Configs) e limpeza de 75 dias. |
| **[07-sistemas-e-compendio.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/Desenvolvimento/idealizacao/07-sistemas-e-compendio.md)** | Sistemas & Homebrews | Catálogo em 4 sub-abas, sanitização Anti-XSS, e sincronização P2P Mesh em estrela com Eleição de Líder Dinâmica e fallback de polling. |
| **[08-comunidades-guildas-e-denuncia.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/Desenvolvimento/idealizacao/08-comunidades-guildas-e-denuncia.md)** | Comunidades & Moderação | Dinâmica tripla (Reddit + Discord + WhatsApp), Guildas com crowdfunding de nível (Guild Boost), e Botão de Denúncia Universal nos 7 grupos de conteúdo. |
| **[09-cenas-interativas.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/Desenvolvimento/idealizacao/09-cenas-interativas.md)** | Modelos de Cenas Interativas | Os 6 modelos granulares: Grid Tático (3 layers + Raycasting + não-sobreposição), Mahjong & Minas, Senhas, Menus Conectados / Máquina de Estados, Combate JRPG e Terminal. |
| **[10-tutoriais-e-guia.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/Desenvolvimento/idealizacao/10-tutoriais-e-guia.md)** | Tutoriais & Onboarding | Central de aprendizado por macro funções guiada com overlays dinâmicos e Sandboxed Local Mock Engine sem gravação no banco de dados. |
| **[11-administracao-e-blindagem.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/Desenvolvimento/idealizacao/11-administracao-e-blindagem.md)** | Painel Admin & Segurança | Telemetria, fila de denúncias com tags automáticas, votação colegiada (3 admins), Ghost Spectator, governança Superadmin e protocolo de blindagem em 3 camadas. |
| **[12-regras-compendio-e-audio.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/Desenvolvimento/idealizacao/12-regras-compendio-e-audio.md)** | Mecânicas, Ficha & Áudio | Herança Delta (semi-dependente), Blocos Visuais No-Code com visibilidade granular, otimização mobile, regras AlphaD6 (v2.0) e streaming inteligente de áudio. |
| **[13-arquitetura-flutter-e-metas.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/Desenvolvimento/idealizacao/13-arquitetura-flutter-e-metas.md)** | FrontEnd Flutter & Metas | Top Bar, Bottom Dock, Navigation Drawer, mapa de telas unificado e metas técnicas (60 FPS, Clean Architecture em 4 camadas, Resiliência e Zero-Trust). |

---

> [!NOTE]
> Para o mapeamento estrutural e navegacional de todos os modais da aplicação, consulte o arquivo de governança **[hierarquia-modais.md](file:///home/ultratelecom/Documentos/Prjts/arc-vtt/hierarquia-modais.md)** na raiz do projeto.
