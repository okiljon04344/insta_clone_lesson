class SupabaseConfig {
  static const _defaultUrl = 'https://cmttklunnlocluuvnjyl.supabase.co';
  static const _defaultPublishableKey =
      'sb_publishable_0a6O2msNdHkIVgtASffY4Q_6SIzmvyO';

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _nextPublicUrl = String.fromEnvironment(
    'NEXT_PUBLIC_SUPABASE_URL',
  );
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _nextPublicPublishableKey = String.fromEnvironment(
    'NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY',
  );

  static String get url => _url.isNotEmpty
      ? _url
      : _nextPublicUrl.isNotEmpty
      ? _nextPublicUrl
      : _defaultUrl;

  static String get anonKey => _anonKey.isNotEmpty
      ? _anonKey
      : _publishableKey.isNotEmpty
      ? _publishableKey
      : _nextPublicPublishableKey.isNotEmpty
      ? _nextPublicPublishableKey
      : _defaultPublishableKey;

  static const bucket = String.fromEnvironment(
    'SUPABASE_BUCKET',
    defaultValue: 'instagram-media',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
