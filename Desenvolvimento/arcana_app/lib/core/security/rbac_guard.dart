/// Papéis Zero-Trust RBAC oficiais do ArcanaVTT.
enum UserRole {
  jogador,
  assistenteMestre,
  mestre,
  admin,
  superadmin;

  String get badgeLabel {
    switch (this) {
      case UserRole.jogador:
        return 'JOGADOR';
      case UserRole.assistenteMestre:
        return 'AUXILIAR';
      case UserRole.mestre:
        return 'MESTRE';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.superadmin:
        return 'SUPERADMIN';
    }
  }

  String get wireKey {
    switch (this) {
      case UserRole.jogador:
        return 'jogador';
      case UserRole.assistenteMestre:
        return 'assistente_mestre';
      case UserRole.mestre:
        return 'mestre';
      case UserRole.admin:
        return 'admin';
      case UserRole.superadmin:
        return 'superadmin';
    }
  }

  static UserRole fromWire(String value) {
    switch (value) {
      case 'assistente_mestre':
        return UserRole.assistenteMestre;
      case 'mestre':
        return UserRole.mestre;
      case 'admin':
        return UserRole.admin;
      case 'superadmin':
        return UserRole.superadmin;
      default:
        return UserRole.jogador;
    }
  }
}

/// Guarda de segurança RBAC responsável pelo Widget Tree Pruning na interface.
class RbacGuard {
  RbacGuard._();

  static bool canForgeCampaign(UserRole role) {
    return role == UserRole.mestre ||
        role == UserRole.admin ||
        role == UserRole.superadmin;
  }

  static bool canAccessAdminPanel(UserRole role) {
    return role == UserRole.admin || role == UserRole.superadmin;
  }

  static bool canModerateReports(UserRole role) {
    return canAccessAdminPanel(role);
  }
}

