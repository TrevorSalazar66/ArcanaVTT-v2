enum OAuthSecurityState {
  padrao,
  erroMenorIdade,
  erroHardwareBan,
  erroLockoutTotal,
  sucessoAutenticado,
}

class OAuthAttemptResult {
  final bool success;
  final String? errorCode;
  final String? errorTitle;
  final String? errorMessage;

  const OAuthAttemptResult({
    required this.success,
    this.errorCode,
    this.errorTitle,
    this.errorMessage,
  });
}

/// Caso de uso client-side para pré-validação LGPD (>= 16 anos) e interpretação dos estados OAuth 2.0.
class AuthenticateOAuthUseCase {
  static int calculateAge(DateTime birthDate, {DateTime? now}) {
    final ref = now ?? DateTime.now().toUtc();
    var age = ref.year - birthDate.year;
    if (ref.month < birthDate.month ||
        (ref.month == birthDate.month && ref.day < birthDate.day)) {
      age -= 1;
    }
    return age;
  }

  OAuthAttemptResult evaluateAttempt({
    required DateTime birthDate,
    required bool isHardwareBanned,
    required bool isAccountLocked,
  }) {
    if (isAccountLocked) {
      return const OAuthAttemptResult(
        success: false,
        errorCode: 'ACCOUNT_LOCKED',
        errorTitle: 'Conta em Lockout Total Preventivo',
        errorMessage:
            'Todas as sessoes foram revogadas. Insira o codigo enviado via Resend para seu e-mail Google para desbloquear.',
      );
    }

    if (isHardwareBanned) {
      return const OAuthAttemptResult(
        success: false,
        errorCode: 'HARDWARE_BANNED',
        errorTitle: 'Dispositivo Bloqueado (Hardware Ban)',
        errorMessage:
            'Este aparelho Android foi bloqueado permanentemente pelas Diretrizes de Seguranca Zero-Trust.',
      );
    }

    final age = calculateAge(birthDate);
    if (age < 16) {
      return const OAuthAttemptResult(
        success: false,
        errorCode: 'AGE_RESTRICTED',
        errorTitle: 'Restricao Etaria LGPD (< 16 anos)',
        errorMessage:
            'O ArcanaVTT e destinado a aventureiros com 16 anos ou mais. O acesso foi bloqueado antes da criacao de sessao.',
      );
    }

    return const OAuthAttemptResult(success: true);
  }
}

