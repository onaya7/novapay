abstract class StorageKeys {
  // Hive (non-sensitive)
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String pendingActions = 'pending_actions';
  static const String confirmedBalanceKobo = 'confirmed_balance_kobo';

  // Secure storage (flutter_secure_storage) — sensitive
  static const String authToken = 'auth_token';
  static const String sessionId = 'session_id';
}
