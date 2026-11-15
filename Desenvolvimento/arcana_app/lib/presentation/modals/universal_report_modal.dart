import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/theme/arcana_colors.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import 'modal_shell.dart';

/// Modal onipresente de Denúncia Universal com geração automática de Autotags.
class UniversalReportModal extends StatefulWidget {
  final AppController controller;
  final String originType;
  final String originId;

  const UniversalReportModal({
    super.key,
    required this.controller,
    required this.originType,
    required this.originId,
  });

  @override
  State<UniversalReportModal> createState() => _UniversalReportModalState();
}

class _UniversalReportModalState extends State<UniversalReportModal> {
  String _selectedReason = 'Linguagem Ofensiva / Assédio';
  final TextEditingController _descCtrl = TextEditingController();
  bool _submitted = false;
  List<String> _generatedTags = const [];

  static const _reasons = [
    'Linguagem Ofensiva / Assédio',
    'Conteúdo Impróprio ou Spam',
    'Sabotagem de Sessão / Anti-jogo',
    'Violação de Segurança / Fraude',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.flag,
      title: 'DENÚNCIA UNIVERSAL',
      subtitle: 'Protocolo com autotags de contexto Zero-Trust',
      badgeLabel: 'SIGILO',
      badgeColor: p.crimson,
      child: _submitted
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeraldicCard(
                  borderColor: p.emerald,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Denúncia Registrada com Sucesso',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: p.emerald,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Nossa equipe de moderação recebeu o relatório junto com as autotags criptográficas:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _generatedTags
                            .map((t) => HeraldicChipPill(label: t, color: p.infoBlue))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryGoldPillButton(
                  label: 'Concluir',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HeraldicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Autotags Anexadas Automaticamente',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: p.goldPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          HeraldicChipPill(
                            label: '#origem:${widget.originType}',
                            color: p.infoBlue,
                          ),
                          HeraldicChipPill(
                            label: '#alvo:${widget.originId}',
                            color: p.goldPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  decoration: const InputDecoration(labelText: 'Motivo Principal'),
                  items: _reasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Relato Detalhado',
                    hintText: 'Descreva objetivamente o ocorrido...',
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryGoldPillButton(
                  label: 'Enviar Denúncia Segura',
                  svgIcon: ArcanaSvgIcons.shield,
                  onPressed: () async {
                    final text = _descCtrl.text.trim().isEmpty
                        ? 'Ocorrência sinalizada via botão rápido de denúncia.'
                        : _descCtrl.text.trim();
                    final created = await widget.controller.submitUniversalReport(
                      originType: widget.originType,
                      originId: widget.originId,
                      reasonCategory: _selectedReason,
                      description: text,
                    );
                    if (!mounted) return;
                    setState(() {
                      _submitted = true;
                      _generatedTags = created.autoTags;
                    });
                  },
                ),
              ],
            ),
    );
  }
}

