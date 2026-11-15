import '../../core/security/rbac_guard.dart';
import '../entities/arcana_entities.dart';

/// Gera denúncia universal enriquecida automaticamente com autotags de contexto.
class BuildUniversalReportUseCase {
  UniversalReport execute({
    required String originType,
    required String originId,
    required String reasonCategory,
    required String description,
    required UserRole reporterRole,
    required String sessionContext,
  }) {
    final nowUtc = DateTime.now().toUtc();
    final stamp = nowUtc.toIso8601String().substring(0, 19);
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
      originId: originId,
      reasonCategory: reasonCategory,
      description: description.trim(),
      autoTags: autoTags,
      status: 'pending',
      createdAtText: 'Agora ($stamp UTC)',
    );
  }
}

