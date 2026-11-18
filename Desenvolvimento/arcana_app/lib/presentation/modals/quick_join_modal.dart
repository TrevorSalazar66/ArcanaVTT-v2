import 'package:flutter/material.dart';
import '../../controllers/app_controller.dart';
import '../../core/constants/svg_icons.dart';
import '../../core/theme/arcana_colors.dart';
import '../widgets/heraldic_buttons.dart';
import '../widgets/heraldic_card.dart';
import 'campaign_modals.dart';
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
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.prefilledCode ?? '');
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    setState(() {
      _joining = true;
      _statusMsg = null;
    });
    final res = await widget.controller.lookupCampaignByCode(_codeCtrl.text);
    if (!mounted) return;
    if (res == null) {
      setState(() {
        _joining = false;
        _isError = true;
        _statusMsg = widget.controller.lastSyncError ??
            'Código de campanha não encontrado no servidor.';
      });
      return;
    }

    Navigator.of(context).pop();
    showArcanaModal(
      context,
      builder: (_) => res.isMember
          ? CampaignGeneralModal(
              controller: widget.controller,
              campaign: res.campaign,
            )
          : CampaignApplicationModal(
              controller: widget.controller,
              campaign: res.campaign,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.qrCode,
      title: 'QUICK JOIN & QR CODE',
      subtitle: 'Localize mesas pelo código de convite de 6 dígitos',
      badgeLabel: 'CLOUDFLARE D1',
      badgeColor: p.infoBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Código Alfanumérico da Mesa (6 dígitos)',
              hintText: 'Ex: A1B2C3',
            ),
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
            label: _joining ? 'Consultando Servidor...' : 'Localizar Campanha Agora',
            svgIcon: ArcanaSvgIcons.arrowRight,
            onPressed: _joining ? null : _lookup,
          ),
        ],
      ),
    );
  }
}

