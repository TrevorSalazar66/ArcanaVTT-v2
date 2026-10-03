# ArcanaVTT — Módulo 13: Arquitetura FrontEnd Flutter, Mapa de Telas & Metas de Engenharia

---

## 📱 6. Arquitetura e Organização do FrontEnd Mobile (Flutter UI)

A interface do aplicativo Flutter é projetada para **ergonomia mobile**, **alta fluidez (60 FPS)** e distribuição intuitiva dos **botões macro** de navegação.

```mermaid
flowchart TD
    APP["📱 Interface Geral do ArcanaVTT (Flutter)"]
    
    APP --> TOP_BAR["🔝 1. Top AppBar (Cabeçalho)\n(Logo ArcanaVTT, Notificações 🔔, Avatar/Perfil 👤)"]
    APP --> BOTTOM_BAR["📱 2. Bottom Navigation Bar (Dock Principal)\n(🏠 Início | 🎲 Campanhas | 📜 Sistemas | 🏰 Comunidades)"]
    APP --> DRAWER["🚪 3. Navigation Drawer (Menu Lateral)\n(👤 Meu Perfil | 📖 Tutorial | ⚙️ Configurações | 🛡️ Administração* | 🚪 Sair)"]
    
    DRAWER -.->|"Apenas Admin/Superadmin"| ADMIN_SEC["🛡️ Módulo de Administração\n(Totalmente blindado e isolado)"]
```

---

## 📱 11. Mapa de Telas no Aplicativo Flutter

```mermaid
flowchart TD
    SPLASH["🚀 Splash & Autenticação OAuth"] --> HUB["🏠 Hub Principal"]
    
    HUB --> HERO_CARD["📜 Herói em Destaque\n(Visualização da Ficha da Campanha Ativa)"]
    HUB --> CAMPS["🎲 Campanhas\n(Listar, Criar* e Entrar com Código 6 Dígitos / QR)"]
    HUB --> COMP["📜 Sistemas & Compêndio\n(Consulta de Regras Livres, Magias e Homebrews)"]
    HUB --> COMMS["🏰 Comunidades\n(Guildas, Fóruns, Canais e DMs 1-a-1)"]
    
    CAMPS --> MODAL_CAMP["🚪 Modal Geral da Campanha (7 Sub-abas)\n(Geral, Chats, Cenas, Diário, Oficina*, Personagens, Configs*)"]
    
    MODAL_CAMP --> LOBBY["🚪 Lobby / Ingresso na Sessão"]
    LOBBY --> VTT["⚔️ Mesa de Jogo (Workspace VTT)"]
    
    subgraph VTT_ROOM["Ambiente VTT Ativo"]
        VTT --> CANVAS["🗺️ Renderizador da Cena Ativa\n(Grid 2D / Mahjong / Senha / Diálogo / JRPG / Terminal)"]
        VTT --> CHAT_DRAWER["💬 Gaveta de Chat & Rolador de Dados"]
        VTT --> SHEET_DRAWER["📄 Gaveta de Ficha do Herói / Ameaça"]
        VTT --> GM_TOOLBOX["🛠️ Painel do Mestre\n(Troca de Cenas, Fog, NPCs e Áudio)"]
    end
```

> [!IMPORTANT]
> **Regra Rígida de Personagens:** Personagens **NUNCA são criados de forma avulsa fora de uma mesa**. Toda ficha de personagem é forjada e vinculada obrigatoriamente a uma campanha específica após a aprovação da candidatura pelo Mestre. O Hub oferece apenas visualização rápida do último herói ativo e atalho para sua mesa correspondente.

---

## 🎯 12. Metas de Engenharia & Qualidade

1. **Desempenho 60 FPS:** Otimização máxima no Flutter utilizando `CustomPainter`, widgets com construtores `const` e descarte de renders fora da viewport (*Viewport Culling*).
2. **Resiliência de Rede:** Reconexão automática em segundo plano sem perda do estado do jogo caso a rede móvel oscile.
3. **Clean Architecture em 4 Camadas:** Separação estrita em:
   - `presentation/` (Telas e componentes puros);
   - `controllers/` (Gerência de estado e eventos de tela);
   - `domain/` (Entidades e Casos de Uso puros, 1 caso por arquivo);
   - `data/` (Repositórios, abstrações de cache local e APIs Cloudflare/P2P).
4. **Segurança Zero-Trust:** O cliente mobile nunca dita o resultado de um evento crítico; todas as transições de cena, ganho de itens, dano e final de turnos são validadas na borda (Cloudflare Worker autoritativo).
