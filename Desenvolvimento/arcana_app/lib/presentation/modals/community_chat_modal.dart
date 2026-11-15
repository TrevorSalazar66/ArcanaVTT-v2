import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/theme/arcana_colors.dart';
import '../../domain/entities/arcana_entities.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/svg_icon_widget.dart';
import '../widgets/heraldic_card.dart';
import 'modal_shell.dart';
import 'universal_report_modal.dart';

/// Chat Comunitário Híbrido (WhatsApp + Discord):
/// - Bolhas à esquerda (outros) com avatar e badge de cargo
/// - Bolhas à direita (próprias) com duplo check de leitura
/// - Card 3d6 integrado dentro da bolha + botão ao vivo para rolar 3d6
/// - Preview de resposta estilo WhatsApp e barra de entrada fixa inferior
class CommunityChatModal extends StatefulWidget {
  final AppController controller;
  final String channelTitle;

  const CommunityChatModal({
    super.key,
    required this.controller,
    this.channelTitle = 'TAVERNA DOS MESTRES',
  });

  @override
  State<CommunityChatModal> createState() => _CommunityChatModalState();
}

class _CommunityChatModalState extends State<CommunityChatModal> {
  final TextEditingController _msgCtrl = TextEditingController();
  String? _replyingPreview;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  void _handleSend({bool with3d6 = false}) {
    final raw = _msgCtrl.text.trim();
    final content = raw.isEmpty && with3d6
        ? 'Executou uma rolagem de desafio na Taverna!'
        : raw;
    if (content.isEmpty) return;

    widget.controller.sendCommunityMessage(
      content: content,
      replyPreview: _replyingPreview,
      with3d6Roll: with3d6,
    );
    _msgCtrl.clear();
    setState(() => _replyingPreview = null);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final messages = widget.controller.chatMessages;
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: p.voidBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: p.goldBorder),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: p.subtleBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.goldBorder),
                      ),
                      alignment: Alignment.center,
                      child: SvgIconWidget(
                        ArcanaSvgIcons.messagesSquare,
                        size: 20,
                        color: p.goldPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.channelTitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: p.goldPrimary),
                                ),
                              ),
                              const SizedBox(width: 6),
                              HeraldicChipPill(
                                label: 'PÚBLICO',
                                color: p.emerald,
                              ),
                            ],
                          ),
                          Text(
                            '#regras-e-oficina • ${messages.length} mensagens sincronizadas',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Denunciar canal',
                      onPressed: () {
                        showArcanaModal(
                          context,
                          builder: (_) => UniversalReportModal(
                            controller: widget.controller,
                            originType: 'chat',
                            originId: 'taverna-dos-mestres',
                          ),
                        );
                      },
                      icon: SvgIconWidget(
                        ArcanaSvgIcons.flag,
                        size: 18,
                        color: p.crimson,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: SvgIconWidget(
                        ArcanaSvgIcons.close,
                        size: 20,
                        color: p.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: p.goldBorder.withValues(alpha: 0.35), height: 1),
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: HeraldicCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgIconWidget(
                                  ArcanaSvgIcons.messagesSquare,
                                  size: 28,
                                  color: p.goldPrimary,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Nenhuma mensagem neste canal ainda. Envie a primeira mensagem ou role 3d6!',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (ctx, idx) =>
                            _buildBubble(ctx, messages[idx], p),
                      ),
              ),
              if (_replyingPreview != null)
                Container(
                  color: p.surfaceElevated,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Container(width: 3, height: 28, color: p.goldPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Respondendo a $_replyingPreview',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _replyingPreview = null),
                        child: SvgIconWidget(
                          ArcanaSvgIcons.close,
                          size: 16,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: p.obsidianBg,
                  border: Border(top: BorderSide(color: p.subtleBorder)),
                ),
                child: Row(
                  children: [
                    Tooltip(
                      message: 'Rolar 3d6 no Chat',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _handleSend(with3d6: true),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: p.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: p.goldBorder),
                          ),
                          child: SvgIconWidget(
                            ArcanaSvgIcons.dices,
                            size: 20,
                            color: p.goldPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        decoration: const InputDecoration(
                          hintText: 'Mensagem na Taverna...',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _handleSend(),
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [p.goldHighlight, p.goldPrimary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const SvgIconWidget(
                          ArcanaSvgIcons.arrowRight,
                          size: 20,
                          color: Color(0xFF0A0A12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBubble(
    BuildContext context,
    ChatMessage msg,
    ArcanaPalette p,
  ) {
    final isMine = msg.isMine;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => setState(
          () => _replyingPreview = '${msg.senderHandle}: ${msg.content}',
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.80,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMine ? p.bubbleOutgoing : p.bubbleIncoming,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMine ? 16 : 4),
              topRight: Radius.circular(isMine ? 4 : 16),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
            border: Border.all(
              color: isMine ? p.infoBlue.withValues(alpha: 0.65) : p.subtleBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.senderHandle,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isMine ? p.infoBlue : p.goldPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  RoleBadgeWidget(role: msg.senderRole),
                ],
              ),
              if (msg.replyPreview != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.voidBg.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: p.goldPrimary, width: 3),
                    ),
                  ),
                  child: Text(
                    msg.replyPreview!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(msg.content, style: Theme.of(context).textTheme.bodyMedium),
              if (msg.diceRoll != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.voidBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.goldBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgIconWidget(
                            ArcanaSvgIcons.dices,
                            size: 16,
                            color: p.goldPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            msg.diceRoll!.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: p.goldPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dados: [${msg.diceRoll!.dice.join(', ')}] -> ${msg.diceRoll!.outcome}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: msg.diceRoll!.successes > 0
                              ? p.emerald
                              : p.crimson,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.timeText,
                    style: TextStyle(fontSize: 10, color: p.textSecondary),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    SvgIconWidget(
                      ArcanaSvgIcons.check,
                      size: 12,
                      color: msg.isRead ? p.infoBlue : p.textSecondary,
                    ),
                    SvgIconWidget(
                      ArcanaSvgIcons.check,
                      size: 12,
                      color: msg.isRead ? p.infoBlue : p.textSecondary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

