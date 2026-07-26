import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/ai_config.dart';
import '../models/chat_message.dart';

/// Calls Google's free Gemini API to generate an instant reply for the
/// "Ask a Pharmacist" AI chat. Stateless — the caller (AiPharmacistProvider)
/// owns message history/persistence; this class only turns a history +
/// new user message into a reply string.
class GeminiService {
  GeminiService._();

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Keeps prompts small (free-tier friendly) by only sending the most
  /// recent messages as conversational context.
  static const int _maxHistoryMessages = 20;

  static const String _systemInstruction = '''
You are PharmBot, the in-app AI assistant for PharmConnect, a community
pharmacy app. You reply to customers instantly, replacing what used to
be a "wait for a human pharmacist to reply" chat.

How to help:
- Answer in short, clear, friendly paragraphs (avoid walls of text).
- You can explain what a medication is generally used for, common side
  effects, general storage/dosage information of the kind printed on a
  package insert, and general drug-interaction awareness at an
  educational level.
- You can help customers figure out how to use the app (uploading a
  prescription, requesting a refill, setting medication reminders).

Safety boundaries (do not cross these):
- Never diagnose a medical condition.
- Never tell someone to start, stop, or change the dose of a
  prescription medication.
- Never claim to be a licensed pharmacist, doctor, or medical
  professional — you are an AI assistant, not a substitute for one.
- For anything involving a specific prescription decision, a possible
  allergic reaction, or any urgent/emergency symptom, tell the person
  clearly to contact a licensed pharmacist, their doctor, or emergency
  services right away, rather than answering it yourself.
- If you are not confident an answer is safe or accurate, say so and
  recommend they confirm with a pharmacist.

Keep a warm, reassuring, human tone — you're the friendly first line of
support, not a legal disclaimer generator, so don't repeat the
disclaimer in every single message, only when it's actually relevant.

You may also receive a "Customer context" block below with this
specific customer's recent orders, medication reminders, and
prescription status pulled live from the app. Use it to answer
questions like "where's my order?" or "when's my next dose?"
specifically — but only mention these details when they're actually
relevant to what the customer asked; don't recite their whole order
history unprompted.
''';

  /// Sends [userMessage] plus recent [history] to Gemini and returns the
  /// model's reply text. Throws on network/API errors — the provider
  /// decides how to surface that to the UI.
  ///
  /// [customerContext], if given, is a short plain-text summary of the
  /// signed-in customer's own data (recent orders, active reminders,
  /// prescription status) built by CustomerContextBuilder. It's passed
  /// alongside the system instruction so PharmBot can answer questions
  /// like "where's my order?" or "when's my next dose?" specifically,
  /// instead of only giving generic drug information.
  static Future<String> reply({
    required List<ChatMessage> history,
    required String userMessage,
    String? customerContext,
  }) async {
    if (!AiConfig.isConfigured) {
      throw StateError(
        'Gemini API key is not set. Add your free key in '
        'lib/core/constants/ai_config.dart',
      );
    }

    final recentHistory = history.length > _maxHistoryMessages
        ? history.sublist(history.length - _maxHistoryMessages)
        : history;

    final contents = <Map<String, dynamic>>[
      for (final m in recentHistory)
        {
          'role': m.isBot ? 'model' : 'user',
          'parts': [
            {'text': m.text},
          ],
        },
      {
        'role': 'user',
        'parts': [
          {'text': userMessage},
        ],
      },
    ];

    final systemText = customerContext == null || customerContext.trim().isEmpty
        ? _systemInstruction
        : '$_systemInstruction\n\n$customerContext';

    final uri = Uri.parse('$_baseUrl/${AiConfig.model}:generateContent');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            // Google's newer "Auth key" format (keys starting with
            // "AQ.") must be sent as this header rather than the old
            // "?key=" query parameter — see
            // https://ai.google.dev/gemini-api/docs/api-key
            'x-goog-api-key': AiConfig.apiKey,
          },
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {'text': systemText},
              ],
            },
            'contents': contents,
            'generationConfig': {
              'temperature': 0.6,
              'maxOutputTokens': 512,
            },
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      // Usually means the prompt or reply was blocked by a safety filter.
      final blockReason = data['promptFeedback']?['blockReason'];
      throw Exception(
        blockReason != null
            ? 'Gemini blocked this response ($blockReason).'
            : 'Gemini returned no response.',
      );
    }

    final parts = (candidates.first['content']?['parts'] as List<dynamic>?) ?? [];
    final text = parts.map((p) => p['text']?.toString() ?? '').join().trim();
    if (text.isEmpty) {
      throw Exception('Gemini returned an empty response.');
    }
    return text;
  }
}
