import 'package:flutter/material.dart';
import '../../../controllers/app_controller.dart';
import '../../../core/constants/svg_icons.dart';
import '../../../core/theme/arcana_colors.dart';
import '../widgets/heraldic_buttons.dart';
import 'campaign_modals.dart';
import 'modal_shell.dart';

class QuickJoinModal extends StatefulWidget {
  final AppController controller;

  const QuickJoinModal({
    super.key,
    required this.controller,
  });

  @override
  State<QuickJoinModal> createState() => _QuickJoinModalState();
}

class _QuickJoinModalState extends State<QuickJoinModal> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _errorText = 'Digite o codigo de 6 caracteres da mesa.');
      return;
    }
    setState(() {
      _loading = true;
      _errorText = null;
    });

    final result = await widget.controller.lookupCampaignByCode(code);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result == null) {
      setState(() {
        _errorText = widget.controller.lastSyncError ??
            'Nenhuma campanha encontrada ou acesso bloqueado para este codigo.';
      });
      return;
    }

    Navigator.of(context).pop();
    if (result.isMember || widget.controller.ghostSpectatorActive) {
      showArcanaModal(context,
        builder: (_) => CampaignGeneralModal(
          controller: widget.controller,
          campaign: result.campaign,
        ),
      );
    } else {
      showArcanaModal(context,
        builder: (_) => CampaignApplicationModal(
          controller: widget.controller,
          campaign: result.campaign,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.arcana;
    return ArcanaModalScaffold(
      svgIcon: ArcanaSvgIcons.qrCode,
      title: 'Quick Join por Codigo',
      subtitle: 'Se ainda nao for membro, abre o formulario de Candidatura ao Mestre',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            decoration: const InputDecoration(
              labelText: 'Codigo da Campanha (6 caracteres)',
              hintText: 'Ex: ARC904',
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(_errorText!, style: TextStyle(color: p.crimson, fontSize: 12.5)),
          ],
          const SizedBox(height: 14),
          PrimaryGoldPillButton(
            label: _loading ? 'Localizando...' : 'Localizar Mesa',
            svgIcon: ArcanaSvgIcons.search,
            expand: true,
            onPressed: _loading ? null : _lookupCode,
          ),
        ],
      ),
    );
  }
}
