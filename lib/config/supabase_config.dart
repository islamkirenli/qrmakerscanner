class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://haipierkezvocsntamgy.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhhaXBpZXJrZXp2b2NzbnRhbWd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1NDgzMTMsImV4cCI6MjA4NTEyNDMxM30.oVEk_Co_FHategAmeOjzdz9cbapZmb1BU47TqsuY1BU',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static const String emailRedirectUrl = 'com.qrmakerscanner://login-callback';
}
