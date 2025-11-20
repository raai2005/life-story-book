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
                  'You are a professional biography writer and editor. Your task is to enhance personal life stories while preserving the author\'s authentic voice and meaning. Make the text more engaging, vivid, and emotionally resonant, but never change facts or add fictional elements. Keep the same perspective (first-person or third-person) as the original.',
            },
            {
              'role': 'user',
              'content':
                  'Please enhance this life story text while keeping its authentic meaning and personal voice:\n\n$userText',
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
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
