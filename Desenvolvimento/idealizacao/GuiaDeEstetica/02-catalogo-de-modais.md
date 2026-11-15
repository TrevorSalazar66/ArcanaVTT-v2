# 🗂️ ArcanaVTT — Catálogo Oficial de Modais Primários & Renders de Referência

---

## 🎯 1. Princípios de Engenharia Visual: SVG-First (Ícones), WebP (Imagens) & Ergonomia Mobile Android

Este documento cataloga o pacote oficial de **23 imagens-guia dos modais primários** do ArcanaVTT, redesenhados com **organização vertical nativa de Android**, amplo conforto visual, respiro dinâmico entre seções e garantia absoluta de **zero sobreposição**.

> [!IMPORTANT]
> **PADRÃO DE ORGANIZAÇÃO MOBILE-FIRST & POLÍTICA ZERO EMOJIS:**
> 1. **Organização Inspirada na Guia Mobile Android:** Todos os 23 modais seguem a estrutura de cartões empilhados com respiro generoso, barra de status nativa do Android (`22:47`, Wi-Fi, Sinal, `87%`), cabeçalhos de seção heráldicos (`[Ícone SVG] + [Título Cinzel] + ────────◇`), cartões com moldura dupla (`#D4A34B` / `#282640`) e botão de ação principal em pílula dourada ornada.
> 2. **Zero Emojis:** Todos os emojis foram sumariamente eliminados da interface. Nenhum botão, status, badge ou texto utiliza caracteres de emoji.
> 3. **Ícones 100% SVG Vetoriais:** Todos os glifos gráficos são arquivos vetoriais SVG reais padronizados em `assets/icons/` e documentados em **[03-catalogo-de-icones-svg.md](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/03-catalogo-de-icones-svg.md)**.
> 4. **Imagens-Guia em WebP:** Os renders visuais de referência (`440px` de largura base mobile) foram compilados no formato **WebP** (`.webp`), proporcionando resolução nítida com peso médio de ~35 KB por tela.

* 📂 **Pasta de Renders e Vetores:** [modais/](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais)
* 🌐 **Galeria Visual Interativa:** [galeria-modais.html](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/galeria-modais.html)
* 🛡️ **Catálogo de Ícones SVG:** [03-catalogo-de-icones-svg.md](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/03-catalogo-de-icones-svg.md)

---

## 🔐 2. Grupo Autenticação & Telas de Login

| Identificador do Modal | Formato WebP | Código Vetorial SVG | Cenário / Variação | Destaques Visuais de Engenharia |
| :--- | :---: | :---: | :--- | :--- |
| **Login Padrão** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-login-padrao.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-login-padrao.svg) | Portal oficial 100% Google OAuth 2.0 (Zero Senhas) | Card de conta Google detectada no Android em 1 toque, botão dourado ornado de entrada OAuth, seletor de outra conta Google, toggle de *Dispositivo Confiável (15/30 dias via Keystore)* e garantias Zero-Custody/LGPD. |
| **Login Erro** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-login-erro.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-login-erro.svg) | Falha de autenticação OAuth / Bloqueios de segurança | Banner crítico carmesim, 3 chips de bloqueio (*Menor 16*, *Ban Aparelho*, *Token Expirado*), card da conta Google OAuth recusada (sem campos de senha) e telemetria de integridade do aparelho Android. |
| **Login Sucesso** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-login-sucesso.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-login-sucesso.svg) | Autenticação aprovada / Transição | Círculo de confirmação esmeralda `#10B981` com aura dourada, card de perfil autenticado com badge `[MESTRE]`, barra de progresso da conexão P2P Mesh a 60 FPS e botão de ingresso no Hub. |

---

## 🔝 3. Grupo Top AppBar & Acesso Social Rápido

| Identificador do Modal | Formato WebP | Código Vetorial SVG | Finalidade & Contexto | Destaques Visuais de Engenharia |
| :--- | :---: | :---: | :--- | :--- |
| **Central de Notificações** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-notificacoes.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-notificacoes.svg) | Sininho de notificações da Top Bar | Badge numérico nobre de pendências, cards interativos de convite de campanha com botões rápidos `[Aceitar]` e `[Recusar]`, avisos de mensagens diretas e notas de patch do sistema. |
| **Perfil Social do Aventureiro** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-perfil-social.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-perfil-social.svg) | Perfil social estilo Discord ao tocar no avatar | Banner heráldico panorâmico, avatar sobreposto com moldura dourada e status online esmeralda, selos oficiais de contas conectadas via OAuth (Discord, Steam, Twitch), biografia e métricas da Vitrine com drill-down. |

---

## 🏠 4. Grupo Início (Home / Dashboard)

| Identificador do Modal | Formato WebP | Código Vetorial SVG | Finalidade & Contexto | Destaques Visuais de Engenharia |
| :--- | :---: | :---: | :--- | :--- |
| **Quick Join** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-quick-join.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-quick-join.svg) | Entrada rápida na mesa pelo código da Home | 6 slots em fonte monoespaçada com moldura em ouro para inserção dos caracteres aleatórios, atalho para escaneamento de QR Code pela câmera e identificação visual instantânea da mesa encontrada. |
| **Candidatura ao Mestre** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-candidatura.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-candidatura.svg) | Pedido de entrada para mesas que o usuário não participa | Resumo do card da mesa com contagem de vagas, aviso formal sobre a regra rígida de criação de personagem e textarea com limite de 200 caracteres para apresentação ao Mestre. |
| **Modal Geral da Campanha** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-campanha-geral.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-campanha-geral.svg) | Primeira tela da mesa: Aba 1 (Geral) | Barra superior de 7 sub-abas em pílulas (`Geral*`, `Chats`, `Cenas`, `Diário`, `Oficina`, `Heróis`, `Configs`), sinopse, membros da mesa, mural de avisos, card do herói ativo e botão de ingresso no palco ao vivo. |
| **Criação de Campanha (Etapa 1/4)** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-criar-campanha.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-criar-campanha.svg) | Wizard de criação de mesa em 4 etapas | Barra de passos numerada, campo de nome da mesa, seletor de ícones vetoriais SVG, campo de URL/upload de banner 16:7 e preview ao vivo do card idêntico à renderização na Home. |
| **Ficha do Herói em Destaque** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-heroi-destaque.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-heroi-destaque.svg) | Modal rápido expandido da ficha | Barras vitais de Ânima (PV) e Energia (PE), matriz dos 4 atributos AlphaD6, resumo dos 12 slots corporais de equipamento, botões rápidos de rolagem e lore do aventureiro. |

---

## 🎲 5. Grupo Campanhas & Sistemas

| Identificador do Modal | Formato WebP | Código Vetorial SVG | Finalidade & Contexto | Destaques Visuais de Engenharia |
| :--- | :---: | :---: | :--- | :--- |
| **Filtros de Campanhas** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-filtros-campanhas.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-filtros-campanhas.svg) | Busca avançada de mesas abertas | Dropdown de sistema base, chips de estado da sessão (`Ao Vivo`, `Free Time`, `Agendada`), seletor de faixa etária, tags temáticas em pílula e toggle de mesas com vagas. |
| **Filtros de Sistemas** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-filtros-sistemas.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-filtros-sistemas.svg) | Filtro dinâmico das 5 categorias do Compêndio | Lista das 5 categorias universais (*Itens, Equipamentos, Seres, Poderes, Pistas*) aplicando a regra de UX que oculta automaticamente categorias sem conteúdos cadastrados. |
| **Prévia de Sistema** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-previa-sistema.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-previa-sistema.svg) | Card detalhado do sistema no catálogo | Selo oficial de licença livre, descrição de mecânicas centrais, contadores de elementos do compêndio de fábrica e botões de download offline / criação de campanha. |
| **Forja de Sistema Próprio** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-forja-sistema.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-forja-sistema.svg) | Criação de novo motor de regras do zero | Alerta de chave de criação detectada na conta, campos de nome e sigla, seletor de motor de dados (*D6 Pool, D20, D100, Fórmulas Livres*), licenças e pilares narrativos. |

---

## 🏰 6. Grupo Comunidades & Interação Social

| Identificador do Modal | Formato WebP | Código Vetorial SVG | Finalidade & Contexto | Destaques Visuais de Engenharia |
| :--- | :---: | :---: | :--- | :--- |
| **Painel de Guilda** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-painel-guilda.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-painel-guilda.svg) | Painel central do Cenário Compartilhado | Barra de evolução financeira coletiva (*Guild Boost*), contadores de membros, mesas e clãs fundados, lista de facções internas e atalho direto para a World Wiki. |
| **Criar Tópico no Fórum** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-criar-topico-forum.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-criar-topico-forum.svg) | Publicação comunitária estilo Reddit | Seletor de categorias `#`, campo de título, caixa de texto com toolbar de Markdown e formatação de dados, além de atalho para anexar tags secundárias. |
| **Chat Comunitário** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-chat-comunitario.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-chat-comunitario.svg) | Sala de conversa em tempo real (WhatsApp + Discord) | Cabeçalho de canal estilo Discord (`#regras-e-oficina • 84 online`), separador de data em pílula, balões recebidos à esquerda com avatar/cargo e enviados à direita com duplo check esmeralda, embed de rolagem 3d6, citação de resposta (reply), indicador "digitando..." e barra nativa inferior com botão redondo de envio. |

---

## 🚪 7. Grupo Navigation Drawer, Governança & Moderação

| Identificador do Modal | Formato WebP | Código Vetorial SVG | Finalidade & Contexto | Destaques Visuais de Engenharia |
| :--- | :---: | :---: | :--- | :--- |
| **Gestão da Lista de Amigos** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-gestao-amigos.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-gestao-amigos.svg) | Lista de aventureiros conectados | Abas de amigos e solicitações pendentes, barra de pesquisa por nickname, status online com atividade de campanha e atalhos rápidos de 1 toque para DMs e convite para mesa. |
| **Central de Tutoriais** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-central-tutoriais.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-central-tutoriais.svg) | Central de aprendizado interativo | Aviso de ambiente Sandboxed Local (zero custo de banco), lista dos 5 tutoriais por macro funções com indicadores de conclusão e botões de início. |
| **Configurações Gerais** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-configuracoes-gerais.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-configuracoes-gerais.svg) | Preferências de sistema do aplicativo | Seletor de idioma, tema visual e feedback tátil, mixer de áudio de 4 canais com sliders de volume, cota de cache P2P e botão crítico de Lockout com reautenticação. |
| **Painel de Administração** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-painel-administracao.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-painel-administracao.svg) | Governança restrita (Admin/Superadmin) | Cards de telemetria em tempo real, atalho para a Fila da Denúncia Universal com votação colegiada, auditoria de usuários com Hardware Ban, Ghost Spectator e gestão suprema. |
| **Confirmação de Logout** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-logout.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-logout.svg) | Saída segura da conta | Caixa de diálogo de confirmação com destaque nos 3 passos de sanitização criptográfica local no Android Keystore e botões claros de cancelamento ou saída. |
| **Denúncia Universal** | [WebP](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-denuncia-universal.webp) | [SVG](file:///c:/Users/João/Documents/Programas/Flutter/ArcanaVTT/Desenvolvimento/idealizacao/GuiaDeEstetica/modais/modal-denuncia-universal.svg) | Opção ubíqua de moderação comunitária | Autotag de entidade anexada automaticamente pelo sistema, seleção obrigatória de classificação da infração, justificativa e protocolo de evidências invioláveis com telemetria. |
