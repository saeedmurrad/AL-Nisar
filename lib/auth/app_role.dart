enum AppRole {
  user,
  admin,
  superAdmin;

  static AppRole fromString(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
      case 'super-admin':
        return AppRole.superAdmin;
      case 'admin':
        return AppRole.admin;
      default:
        return AppRole.user;
    }
  }

  String get firestoreValue {
    switch (this) {
      case AppRole.superAdmin:
        return 'super_admin';
      case AppRole.admin:
        return 'admin';
      case AppRole.user:
        return 'user';
    }
  }

  bool get isAdminOrHigher => this == AppRole.admin || this == AppRole.superAdmin;
  bool get isSuperAdmin => this == AppRole.superAdmin;
}

