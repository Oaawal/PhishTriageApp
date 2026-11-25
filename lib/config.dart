/// App configuration.
///
/// Override at build time, for example:
///   flutter build apk --dart-define=API_BASE_URL=https://api.example.com \
///                     --dart-define=BOT_WHATSAPP=2348000000000
class AppConfig {
  /// The PhishTriage Platform API (one backend for everything).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://phishtriageplatform.onrender.com',
  );

  /// WhatsApp number of the PhishTriage bot, digits only with country code.
  /// Leave empty to hide the "Use on WhatsApp" card.
  static const String botWhatsApp = String.fromEnvironment('BOT_WHATSAPP');

  /// WhatsApp number for human help from AWAL Global Consults.
  static const String helpWhatsApp = String.fromEnvironment(
    'HELP_WHATSAPP',
    defaultValue: '2347038336596',
  );
}
