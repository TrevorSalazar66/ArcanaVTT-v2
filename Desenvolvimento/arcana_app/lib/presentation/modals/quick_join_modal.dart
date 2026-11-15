import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/theme/arcana_colors.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import 'modal_shell.dart';

/// Modal de Entrada Rápida (Quick Join) por código de 6 dígitos ou leitura QR Code.
class QuickJoinModal extends StatefulWidget {
  final AppController controller;
  final String? prefilledCode;

  const QuickJoinModal({
    super.key,
    required this.controller,
    this.prefilledCode,
  });

  @override
  State<QuickJoinModal> createState() => _QuickJoinModalState();
}

class _QuickJoinModalState extends State<QuickJoinModal> {
  late final TextEditingController _codeCtrl;
  String? _statusMsg;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.prefilledCode ?? 'ARC774');
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _join() {
    final found = widget.controller.quickJoinByCode(_codeCtrl.text);
    setState(() {
      if (found != null) {
        _isError = false;
        _statusMsg =
            'Conectado à mesa "${found.title}" (${found.quickJoinCode})!';
      } else {
        _isError = true;
        _statusMsg =
            'Código não localizado. Códigos ativos para teste: ARC774, CIN882, OBE309.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.qrCode,
      title: 'QUICK JOIN & QR CODE',
      subtitle: 'Conecte-se em segundos a qualquer mesa aberta',
      badgeLabel: 'P2P EDGE',
      badgeColor: p.infoBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Código Alfanumérico da Mesa (6 dígitos)',
              hintText: 'Ex: ARC774',
            ),
          ),
          const SizedBox(height: 12),
          SecondaryHeraldicButton(
            label: 'Simular Leitura QR Code da Mesa (ARC774)',
            svgIcon: ArcanaSvgIcons.qrCode,
            expand: true,
            onPressed: () {
              _codeCtrl.text = 'ARC774';
              _join();
            },
          ),
          if (_statusMsg != null) ...[
            const SizedBox(height: 12),
            HeraldicCard(
              borderColor: _isError ? p.crimson : p.emerald,
              child: Text(
                _statusMsg!,
                style: TextStyle(
                  color: _isError ? p.crimson : p.emerald,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryGoldPillButton(
            label: 'Entrar na Campanha Agora',
            svgIcon: ArcanaSvgIcons.arrowRight,
            onPressed: _join,
          ),
        ],
      ),
    );
  }
}

