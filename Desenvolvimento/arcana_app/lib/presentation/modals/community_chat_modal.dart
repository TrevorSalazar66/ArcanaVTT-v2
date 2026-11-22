import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/security/rbac_guard.dart';
import '../../../core/theme/arcana_colors.dart';
import '../../../domain/entities/arcana_entities.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/svg_icon_widget.dart';
import 'modal_shell.dart';
import 'universal_report_modal.dart';

class CommunityChatModal extends StatefulWidget {
  final AppController controller;
  final String channelId;
  final String? campaignId;
  final CampaignSegment? tableRelation;

  const CommunityChatModal({
    super.key,
    required this.controller,
    this.channelId = 'taverna-dos-mestres',
    this.campaignId,
    this.tableRelation,
  });

  @override
  State<CommunityChatModal> createState() => _CommunityChatModalState();
}

class _CommunityChatModalState extends State<CommunityChatModal> {
  final _msgCtrl = TextEditingController();
  final _npcCtrl = TextEditingController();
  final _diceExprCtrl = TextEditingController(text: '1d20+3');
  String _persona = 'ic'; // ic | ooc | narrador | npc
  String? _replyPreview;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _npcCtrl.dispose();
    _diceExprCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final ctrl = widget.controller;
    final canLeaderNarrate = ctrl.currentUser.role == UserRole.mestre ||
        ctrl.currentUser.role == UserRole.admin ||
        ctrl.currentUser.role == UserRole.superadmin ||
        widget.tableRelation == CampaignSegment.mestre ||
        widget.tableRelation == CampaignSegment.auxiliar;
    final canModerateCards = RbacGuard.canApproveActionCard(
      globalRole: ctrl.currentUser.role,
      relation: widget.tableRelation ?? CampaignSegment.explorar,
    );

    final channelMessages =
        ctrl.chatMessages.where((m) => m.channelId == widget.channelId).toList();

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.messagesSquare,
      title: 'Canal #${widget.channelId}',
      subtitle: 'Chat Hibrido IC/OOC + Comandos Universais (/roll, /w, /rest)',
      badgeLabel: 'TEMPO REAL',
      badgeColor: p.emerald,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('IC (Personagem)'),
                selected: _persona == 'ic',
                onSelected: (_) => setState(() => _persona = 'ic'),
              ),
              ChoiceChip(
                label: const Text('OOC (Off)'),
                selected: _persona == 'ooc',
                onSelected: (_) => setState(() => _persona = 'ooc'),
              ),
              if (canLeaderNarrate) ...[
                ChoiceChip(
                  label: const Text('Narrador (/gm)'),
                  selected: _persona == 'narrador',
                  onSelected: (_) => setState(() => _persona = 'narrador'),
                ),
                ChoiceChip(
                  label: const Text('NPC'),
                  selected: _persona == 'npc',
                  onSelected: (_) => setState(() => _persona = 'npc'),
                ),
              ],
            ],
          ),
          if (_persona == 'npc') ...[
            const SizedBox(height: 8),
            TextField(
              controller: _npcCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do NPC em Cena',
                hintText: 'Ex: Estalajadeiro Bram',
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            height: 230,
            child: channelMessages.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma mensagem neste canal ainda.\nExperimente /roll 2d20kh1, /rest longo ou /me observa o salao.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: channelMessages.length,
                    itemBuilder: (context, idx) {
                      final m = channelMessages[idx];
                      final isWhisper = m.msgType == 'whisper';
                      final isGmRoll = m.msgType == 'gmroll';
                      final isNar = m.msgType == 'narracao';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isNar
                              ? p.goldPrimary.withValues(alpha: 0.12)
                              : m.isMine
                                  ? p.bubbleOutgoing
                                  : p.bubbleIncoming,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isGmRoll || isWhisper
                                ? p.crimson
                                : isNar
                                    ? p.goldPrimary
                                    : p.subtleBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  m.npcName != null
                                      ? '${m.npcName} (NPC)'
                                      : m.senderHandle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: p.goldHighlight,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                RoleBadgeWidget(role: m.senderRole),
                                const SizedBox(width: 6),
                                if (isWhisper)
                                  HeraldicChipPill(label: 'SUSSURRO', color: p.crimson),
                                if (isGmRoll)
                                  HeraldicChipPill(label: 'OCULTO GM', color: p.crimson),
                                const Spacer(),
                                Text(
                                  m.timeText,
                                  style: TextStyle(fontSize: 10.5, color: p.textSecondary),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(left: 6),
                                  onPressed: () => setState(
                                    () => _replyPreview = '${m.senderHandle}: ${m.content}',
                                  ),
                                  icon: Icon(Icons.reply, size: 15, color: p.textSecondary),
                                ),
                                if (m.isMine || canModerateCards)
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.only(left: 6),
                                    onPressed: () => ctrl.deleteChatMessage(
                                      m.id,
                                      campaignId: widget.campaignId,
                                    ),
                                    icon: Icon(Icons.delete_outline, size: 15, color: p.crimson),
                                  ),
                              ],
                            ),
                            if (m.replyPreview != null && m.replyPreview!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: p.voidBg.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  m.replyPreview!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: p.textSecondary),
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              m.content,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: m.msgType == 'ooc' || m.msgType == 'acao'
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: p.textPrimary,
                              ),
                            ),
                            if (m.diceRoll != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: p.obsidianBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: p.goldBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${m.diceRoll!.label} (${m.diceRoll!.expression})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: p.goldPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Dados: ${m.diceRoll!.dice} -> ${m.diceRoll!.outcome}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: p.emerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (m.actionCard != null &&
                                m.actionCard!['status'] == 'pending' &&
                                canModerateCards &&
                                widget.campaignId != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: SecondaryHeraldicButton(
                                      label: 'Aprovar Acao',
                                      svgIcon: ArcanaSvgIcons.check,
                                      borderColor: p.emerald,
                                      textColor: p.emerald,
                                      onPressed: () => ctrl.moderateChatActionCard(
                                        campaignId: widget.campaignId!,
                                        messageId: m.id,
                                        decision: 'approved',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SecondaryHeraldicButton(
                                      label: 'Recusar',
                                      svgIcon: ArcanaSvgIcons.close,
                                      borderColor: p.crimson,
                                      textColor: p.crimson,
                                      onPressed: () => ctrl.moderateChatActionCard(
                                        campaignId: widget.campaignId!,
                                        messageId: m.id,
                                        decision: 'rejected',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_replyPreview != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: p.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Respondendo: $_replyPreview',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: p.goldPrimary),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _replyPreview = null),
                    child: SvgIconWidget(ArcanaSvgIcons.close, size: 14, color: p.crimson),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Mensagem ou /r 1d20+3, /w @user...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PrimaryGoldPillButton(
                label: 'Enviar',
                expand: false,
                onPressed: () async {
                  if (_msgCtrl.text.trim().isEmpty) return;
                  final txt = _msgCtrl.text;
                  final reply = _replyPreview;
                  _msgCtrl.clear();
                  setState(() => _replyPreview = null);
                  await ctrl.sendCommunityMessage(
                    content: txt,
                    channelId: widget.channelId,
                    replyPreview: reply,
                    persona: _persona,
                    npcName: _persona == 'npc' ? _npcCtrl.text.trim() : null,
                    campaignId: widget.campaignId,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _diceExprCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Rolagem Rapida (Formula / Pool / d100)',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SecondaryHeraldicButton(
                label: 'Rolar',
                svgIcon: ArcanaSvgIcons.dices,
                onPressed: () => ctrl.sendCommunityMessage(
                  content: 'Executou rolagem rapida (${_diceExprCtrl.text})',
                  channelId: widget.channelId,
                  rollExpression: _diceExprCtrl.text.trim(),
                  rollLabel: 'ROLAGEM UNIVERSAL',
                  persona: _persona,
                  campaignId: widget.campaignId,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Denunciar Mensagem/Canal',
                onPressed: () => showArcanaModal(context,
                  builder: (_) => UniversalReportModal(
                    controller: ctrl,
                    originType: 'chat',
                    originId: widget.channelId,
                  ),
                ),
                icon: SvgIconWidget(ArcanaSvgIcons.flag, size: 18, color: p.crimson),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
