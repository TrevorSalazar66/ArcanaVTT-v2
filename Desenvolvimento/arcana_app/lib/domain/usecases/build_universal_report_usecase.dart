import '../../core/security/rbac_guard.dart';
import '../entities/arcana_entities.dart';

/// Gera denuncia universal enriquecida automaticamente com 5 tags oficiais e [TIPO: ...].
class BuildUniversalReportUseCase {
  UniversalReport execute({
    required String originType,
    required String originId,
    required String reasonCategory,
    required String description,
    required UserRole reporterRole,
    required String sessionContext,
    String? targetUserId,
  }) {
    final nowUtc = DateTime.now().toUtc();
    final stamp = '${nowUtc.hour.toString().padLeft(2, '0')}:${nowUtc.minute.toString().padLeft(2, '0')}';
    final cleanDesc = description.trim();
    final prefixedDesc = cleanDesc.startsWith('[TIPO:')
        ? cleanDesc
        : '[TIPO: ${originType.toUpperCase()}] $cleanDesc';

    final autoTags = [
      '#origem:$originType',
      '#alvo:$originId',
      '#sessao:$sessionContext',
      '#relator:${reporterRole.wireKey}',
      '#utc:${stamp}Z',
    ];

    return UniversalReport(
      id: 'rep_${nowUtc.millisecondsSinceEpoch}',
      originType: originType,
      entityType: originType,
      originId: originId,
      targetUserId: targetUserId,
      reasonCategory: reasonCategory,
      description: prefixedDesc,
      autoTags: autoTags,
      status: 'pending',
      createdAtText: 'Agora ($stamp UTC)',
      votesCount: 0,
      requiredVotes: 3,
    );
  }
}
