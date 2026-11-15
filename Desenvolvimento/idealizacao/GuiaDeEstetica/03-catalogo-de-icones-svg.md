# 🛡️ ArcanaVTT — Catálogo Oficial de Ícones Vetoriais SVG (SVG-First)

---

## 🎯 1. Princípio Fundamental: SVG-First & Proibição Absoluta de Emojis

> [!IMPORTANT]
> **POLÍTICA DE TOLERÂNCIA ZERO A EMOJIS (Zero Emojis Policy):**
> É terminantemente proibido o uso de caracteres emoji (como ⚔️, 🛡️, 👑, 📜, 🚨, 🔞, 🚪, etc.) em qualquer componente visual, botão, lista, status ou modal do ArcanaVTT.

### Por que Emojis são Proibidos no ArcanaVTT?
1. **Quebra de Atmosfera e Tom Visual:** Emojis modernos e coloridos destoam completamente da identidade *Dark Fantasy Heráldica* do ArcanaVTT, degradando o aspecto visual do sistema.
2. **Fragmentação entre Sistemas Operacionais:** Um mesmo caractere emoji possui desenhos completamente diferentes no Android (Google Noto), iOS (Apple Emoji), Windows (Segoe UI) e navegadores Web, arruinando a consistência do design.
3. **Incompatibilidade com Cores Temáticas & Alto Contraste:** Emojis não aceitam tingimento por `ColorFilter`, não herdam `currentColor`, nem reagem às diretrizes do tema OLED (#000000) ou Modo Alto Contraste Solar.

---

## 📐 2. Diretrizes Técnicas de Iconografia

* **Formato Único:** Arquivos vetoriais SVG puros (`.svg`), armazenados em `assets/icons/`.
* **Biblioteca Base:** Ícones de estilo linear refinado (Lucide Icons) customizados para temática medieval e fantástica.
* **Espessura de Linha Padrão:** `1.75px` a `2.0px` (`stroke-width`).
* **Junções e Terminações:** `stroke-linecap="round"` e `stroke-linejoin="round"`.
* **Modo de Cor no Flutter:** Sempre renderizados com `SvgPicture.asset` e `ColorFilter.mode(cor, BlendMode.srcIn)`.

### 📏 Escala de Tamanhos Normalizada

| Nível | Dimensão | Uso Típico na Interface |
| :--- | :---: | :--- |
| **Micro (`iconSm`)** | `14x14dp` a `16x16dp` | Badges, tags de categoria, contadores em chips, status de lista |
| **Controle (`iconMd`)** | `18x18dp` a `20x20dp` | Botões secundários, campos de input, abas de modais, menus contextuais |
| **Navegação (`iconLg`)** | `22x22dp` a `24x24dp` | Bottom Navigation Bar, Sidebar fixa, botões primários CTA, Top Bar |
| **Hero / Destaque (`iconXl`)** | `32x32dp` a `40x40dp` | *IconBox* central de modais, ilustrações de Empty State, vitrines |

---

## 🗡️ 3. Catálogo de Ícones do Sistema (`assets/icons/`)

Abaixo estão listados os 50 ícones SVG oficiais catalogados para o projeto:

### ⚔️ 3.1. Heráldica, RPG & Fantasia
* `swords.svg`: Campanhas ativas, combates, rolagem de iniciativa e desafios.
* `sword.svg`: Ataques individuais, armas brancas e poder ofensivo.
* `shield.svg`: Hub principal (Início), defesas, armadura, classe de armadura (CA) e segurança.
* `crown.svg`: Painel do Mestre, campanhas mestradas, liderança de guilda e perfil supremo.
* `dices.svg`: Rolador de dados universal, testes de perícia e mecânicas de sistema.
* `dice-5.svg`: Indicador de face de dado e rolagem rápida.
* `scroll.svg`: Sistemas de RPG, fichas de regras, compêndios e diários de campanha.
* `book.svg`: Grimório arcano, manuais de regras e módulos oficiais.
* `book-open.svg`: Leitura aberta de regras, compêndio aberto e consulta rápida.
* `wand-2.svg`: Magias, poderes sobrenaturais, homebrews e forja de regras.
* `flask-conical.svg`: Poções, consumíveis, alquimia e testes laboratoriais.
* `skull.svg`: Morte de personagem, modo letal, monstros perigosos e ameaças graves.
* `flame.svg`: Dano de fogo, campanhas em alta, tópicos em destaque no fórum.
* `sparkles.svg`: Itens mágicos, XP, recompensas, novidades e destaques na Taverna.
* `feather.svg`: Criação de diário, anotações do mestre e escrita de lore.

### 🧭 3.2. Navegação, Sistema & Dispositivos
* `arrow-left.svg`: Voltar tela, fechar modal e retorno hierárquico.
* `chevron-right.svg`: Avançar passo, detalhe de card e links externos.
* `settings.svg`: Configurações gerais, preferências de áudio e definições da mesa.
* `sliders.svg`: Mixer de áudio de 4 canais, equalizador e filtros avançados.
* `terminal.svg`: Modelo 6 de Cena (Terminal / Hacking / Runas Arcanas).
* `wifi.svg`: Conexão P2P Mesh, status online e sincronização sem servidor.
* `qr-code.svg`: Entrada rápida em campanha (Quick Join) via escaneamento de câmera.
* `map.svg`: Grid tático 2D, mapas de batalha e fog of war.
* `calendar.svg`: Agendamento de sessões e frequência das mesas.
* `clock.svg`: Duração da sessão, histórico e timestamps.

### 💬 3.3. Comunicação, Social & Comunidade
* `users.svg`: Aba Comunidades, membros da campanha, guildas e grupos.
* `user.svg`: Perfil individual, aventureiro e avatar de jogador.
* `messages-square.svg`: Canais de chat da guilda, conversas de grupo e fórum geral.
* `message-square.svg`: Mensagem direta (DM), sussurro ao mestre e balão de fala.
* `bell.svg`: Central de notificações e alertas sonoros.
* `mail.svg`: Autenticação por e-mail, convites de campanha e e-mails transacionais.
* `heart.svg`: Favoritos, curtidas em homebrews e vitalidade (Pontos de Vida).
* `hash.svg`: Canais temáticos `#`, tags de busca e categorização.

### 🔒 3.4. Segurança, Moderação & Controles
* `lock.svg`: Sala trancada com senha, mesa privada e proteção de dados.
* `key.svg`: Chaves criptográficas P2P, tokens de autenticação e hashes.
* `log-out.svg`: Logout seguro, desconexão de dispositivos e abandono de mesa.
* `flag.svg`: Denúncia universal (Global Report) e sinalização de infração.
* `search.svg`: Busca na Taverna, filtros de compêndio e localização de amigos.
* `filter.svg`: Filtragem de campanhas por sistema, horário e vagas.
* `eye.svg`: Visibilidade pública e modo espectador.
* `eye-off.svg`: Conteúdo oculto do mestre, GM Secret e modo invisível (Ghost).
* `circle-check.svg`: Sucesso, verificação de conta e passo concluído.
* `check.svg`: Seleção de item e confirmação rápida.
* `x.svg`: Cancelar ação, fechar diálogo e remoção.
* `plus.svg`: Criar nova campanha, adicionar amigo e forjar item.
* `trash.svg`: Excluir rascunho, limpar cache e remover elemento.
* `download.svg`: Download de compêndio e módulos para uso 100% offline.
* `info.svg`: Informações de auxílio, tutoriais e dicas contextuais.
* `external-link.svg`: Abertura de links do Discord, Steam e Twitch.

---

## 💻 4. Exemplo de Implementação no Flutter

```dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ArcanaIcon extends StatelessWidget {
  final String iconName;
  final double size;
  final Color? color;

  const ArcanaIcon({
    super.key,
    required this.iconName,
    this.size = 20.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$iconName.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? Theme.of(context).colorScheme.primary,
        BlendMode.srcIn,
      ),
    );
  }
}

// Exemplos de Uso:
// ArcanaIcon(iconName: 'swords', size: 24, color: Color(0xFFE5B758))
// ArcanaIcon(iconName: 'shield', size: 20, color: Color(0xFFF4F4F8))
// ArcanaIcon(iconName: 'log-out', size: 18, color: Color(0xFFEF4444))
```

