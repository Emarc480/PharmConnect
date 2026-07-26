/// Configuration for the free Google Gemini API that powers the
/// "Ask a Pharmacist" AI chatbot.
///
/// Get a free key at https://aistudio.google.com/apikey (no billing
/// required for the free tier) and paste it below.
///
/// SECURITY NOTE: this embeds the key in the client app, which is fine
/// for a student/demo project but not for a production app (anyone who
/// decompiles the APK can read it). For production you'd instead proxy
/// requests through a small backend (e.g. a Cloud Function) that holds
/// the key server-side.
class AiConfig {
  AiConfig._();

  /// Paste your Gemini API key here.
  static const String apiKey = 'AQ.Ab8RN6LhfCiSV91nAKLT2FlIbJ_fQh8okYVFgWtqFTve8GRY2w';

  /// Uses the auto-updating "latest flash" alias so this keeps working
  /// as Google ships newer Flash-generation models, instead of pointing
  /// at one pinned version that eventually gets deprecated.
  static const String model = 'gemini-flash-latest';

  static bool get isConfigured =>
      apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY';
}
