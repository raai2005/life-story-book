import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  // Load configuration from environment variables
  static String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static String get _baseUrl =>
      dotenv.env['OPENROUTER_BASE_URL'] ??
      'https://openrouter.ai/api/v1/chat/completions';
  static String get _model =>
      dotenv.env['OPENROUTER_MODEL'] ?? 'meta-llama/llama-3.1-8b-instruct';

  /// Enhances the user's story text using AI
  ///
  /// Takes the raw user input and returns an enhanced, more engaging version
  /// while maintaining the original story's meaning and personal touch
  static Future<String> enhanceStory(String userText) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://lifestorybook.app',
          'X-Title': 'Life Story Book',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are an expert memoir editor specializing in personal life stories.

Transform raw user text into polished, emotionally engaging narratives while preserving every fact and the author's authentic voice.

KEY TASKS:
• Fix grammar, improve clarity and flow
• Add emotional depth, sensory details, and natural pacing
• Convert indirect speech to direct dialogue: "she told me don't worry" → "Don't worry," she said
• Maintain first-person perspective if used
• Keep similar length (not extremely longer)
• Structure into clear paragraphs

TITLE REQUIREMENTS:
Generate meaningful, descriptive titles (3-7 words). NEVER use:
❌ "Chapter 1", "Chapter 20", "Untitled", or any numbers
✅ Use: "First Day Frenzy", "A Chaotic Start", "The Move to Mumbai"

DIALOGUE RULES:
• Convert implied conversations to natural direct speech
• Format: "..." I said. / "..." she replied.
• Don't add unnatural dialogue if none exists

OUTPUT:
Suggested Title:
<meaningful title>

Enhanced Content:
<polished story with natural flow and dialogue>''',
            },
            {'role': 'user', 'content': 'RAW USER TEXT:\n\n$userText'},
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final enhancedText = data['choices'][0]['message']['content'] as String;
        return enhancedText.trim();
      } else {
        throw AIServiceException(
          'Failed to enhance text: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is AIServiceException) {
        rethrow;
      }
      throw AIServiceException('Error enhancing text: $e');
    }
  }
}

/// Custom exception for AI service errors
class AIServiceException implements Exception {
  final String message;

  AIServiceException(this.message);

  @override
  String toString() => 'AIServiceException: $message';
}
