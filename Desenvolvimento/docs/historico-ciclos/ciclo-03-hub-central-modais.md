# Histórico do Ciclo 03 — Hub Central, 4 Abas Principais & 20 Modais Interativos

## 1. Contexto de Encadeamento
- **Fase Atual:** Fase 1 (`fase-1`)
- **Subfase:** Ciclo 03 (Interface Principal & Modais)
- **Subfase Anterior:** Ciclo 02 (Core Flutter & Login OAuth)
- **Próxima Subfase:** Ciclo 04 (Testes em 3 Camadas, Build APK Release & GitHub)

## 2. O que foi Implementado
1. **Hub Central Adaptativo (`main_hub_screen.dart`):**
   - Top AppBar com Drawer, logo vetorial, Denúncia Rápida, Notificações com badge e Avatar clicável.
   - Drawer com poda RBAC (`Painel de Governança Admin` removido da árvore para não-admins).
   - `BottomNavigationBar` (<600dp) e `NavigationRail` (>=600dp).
2. **As 4 Abas Principais (`lib/presentation/screens/tabs/`):**
   - *Início:* Saudação, Quick Join, Carrossel Continuar a Jornada, Herói em Destaque AlphaD6, Mural de Novidades e chips inferiores.
   - *Campanhas:* Busca, filtros, 4 papéis (`Jogando`, `Auxiliar`, `Mestre`, `Explorar`) e botão de forja RBAC.
   - *Sistemas:* 4 segmentos + Compêndio Inteligente com ocultação automática de categorias vazias dentre *Itens, Equipamentos, Seres, Poderes, Pistas*.
   - *Comunidades:* Anúncios, Guildas, Fórum com upvotes e Grupos/Chat.
3. **Modais Primários (`lib/presentation/modals/`):**
   - Chat Comunitário Híbrido **WhatsApp + Discord** com bolhas diferenciadas esquerda/direita, duplo check de leitura, preview de resposta e rolagem `3d6` ao vivo dentro da bolha.
   - Todos os modais funcionais: Quick Join, Wizard 4 Etapas de Campanha, Ficha em Destaque 3d6, Compêndio, Forja de Sistema, Guild Boost, Novo Tópico, Notificações, Perfil Social, Amigos, Tutoriais Sandbox, Configurações Gerais (Temas, Escala, Mixer 4 Canais, Cache P2P, Lockout Total), Painel Admin (Hardware Ban), Logout Seguro e Denúncia Universal com autotags.

## 3. Log de Erros Encontrados & Correções
- **Erro:** Nos testes de UI iniciais, detectamos `RenderFlex overflowed` em `HeraldicSectionDivider` (`4.2px`) e no rodapé dos cards horizontais em `home_tab_screen.dart` (`70px`), além de avisos de `RadioListTile` depreciado no Flutter 3.47.
- **Solução:** Envolvemos títulos com `Flexible`/`Expanded` + `TextOverflow.ellipsis` e migramos os seletores de tema para `RadioGroup<ArcanaThemeMode>`.
- **Verificação:** `dart analyze` retornou `No issues found!` e `flutter test` aprovou 9/9 testes em 3 camadas.

