class AdminConfig {
  /// TODO: Replace with your real admin email(s).
  /// These emails must be Firebase Auth users (Email/Password) in your project.
  static const allowedEmails = <String>{
    'admin@example.com',
  };

  static bool isAllowedEmail(String? email) {
    if (email == null) return false;
    return allowedEmails.contains(email.trim().toLowerCase());
  }
}

