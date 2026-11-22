import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/theme/arcana_colors.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import 'modal_shell.dart';

class UniversalReportModal extends StatefulWidget {
  final AppController controller;
  final String originType;
  final String originId;
  final String? targetUserId;

  const UniversalReportModal({
    super.key,
    required this.controller,
    required this.originType,
    required this.originId,
    this.targetUserId,
  });

  @override
  State<UniversalReportModal> createState() => _UniversalReportModalState();
}

class _UniversalReportModalState extends State<UniversalReportModal> {
  late String _entityType;
  String _reasonCategory = 'Comportamento Toxico';
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  static const _entityTypes = [
    'chat',
    'dm',
    'campanha',
    'usuario',
    'ficha_personagem',
    'compendio',
    'sistema',
    'homebrew',
    'guilda',
    'cla',
    'forum',
    'wiki',
  ];

  static const _reasons = [
    'Comportamento Toxico',
    'Discurso de Odio / Assedio',
    'Spam / Flood',
    'Conteudo Improprio (+18 sem tag)',
    'Cheat / Trapaca em Mesa',
    'Violacao LGPD / Privacidade',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _entityType = _entityTypes.contains(widget.originType)
        ? widget.originType
        : 'usuario';
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    final tagsPreview = [
      '#origem:$_entityType',
      '#alvo:${widget.originId}',
      '#sessao:sessao_ativa',
      '#relator:${widget.controller.currentUser.role.wireKey}',
      '#utc:agoraZ',
    ];

    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.flag,
      title: 'Denuncia Universal Zero-Trust',
      subtitle: 'Auditavel pelo Colegiado de Administradores & Superadmin',
      badgeLabel: _entityType.toUpperCase(),
      badgeColor: p.crimson,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _entityType,
            decoration: const InputDecoration(labelText: 'Tipo de Entidade Denunciada'),
            items: _entityTypes
                .map((e) => DropdownMenuItem(value: e, child: Text('[TIPO: ${e.toUpperCase()}]')))
                .toList(),
            onChanged: (v) => setState(() => _entityType = v ?? 'usuario'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _reasonCategory,
            decoration: const InputDecoration(labelText: 'Categoria da Infracao'),
            items: _reasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => _reasonCategory = v ?? _reasons.first),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Relato Detalhado (minimo 10 caracteres)',
            ),
          ),
          const SizedBox(height: 12),
          HeraldicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '5 Autotags Geradas Automaticamente:',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.goldPrimary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tagsPreview
                      .map((t) => HeraldicChipPill(label: t, color: p.infoBlue))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PrimaryGoldPillButton(
            label: _submitting ? 'Enviando...' : 'Registrar Denuncia',
            svgIcon: ArcanaSvgIcons.check,
            expand: true,
            onPressed: _submitting
                ? null
                : () async {
                    if (_descCtrl.text.trim().length < 10) return;
                    setState(() => _submitting = true);
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    await widget.controller.submitUniversalReport(
                      originType: _entityType,
                      originId: widget.originId,
                      targetUserId: widget.targetUserId,
                      reasonCategory: _reasonCategory,
                      description: _descCtrl.text,
                    );
                    if (nav.mounted) {
                      nav.pop();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Denuncia registrada com 5 tags oficiais.'),
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}
