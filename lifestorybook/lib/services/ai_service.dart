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
              'content': '''ROLE:
You are an expert story enhancer. You rewrite messy, unstructured user-written chapters into polished, emotionally engaging stories without changing the meaning.

JOB:
Take the user's raw text and enhance it by:
- improving grammar, clarity, flow, and richness
- adding emotion, sensory details, pacing, and structure
- making conversations sound natural and realistic
- converting any passive or indirect speech into direct dialogues
  Example: "she told me don't worry" → "Don't worry," she said.
- keeping the story in first-person if the user wrote it that way
- keeping the tone close to the user's original intention
- keeping the length similar or slightly increased (not extremely longer)

CHAPTER TITLE RULE:
Generate a meaningful written title, NEVER a number.
⛔ Do NOT generate:
- "Chapter 1"
- "Chapter 20"
- "Untitled"

✅ Instead generate a title like:
- "First Day Frenzy"
- "A Chaotic Start"
- "My First College Morning"

ADDITIONAL RULES:
- If the user didn't write a title, you MUST create one.
- If the story contains implied dialogue, convert it into real conversation.
- Keep conversations in natural format:
  "..." I said.
  "..." she replied.
- If no conversation exists, do not forcibly add unnatural dialogue.

OUTPUT FORMAT:
Suggested Title:
<your meaningful chapter title here>

Enhanced Content:
<your enhanced, conversational, polished story here>''',
            },
            {'role': 'user', 'content': 'RAW USER TEXT:\n\n$userText'},
          ],
          'temperature': 0.7,
          'max_tokens': 1500,
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
