import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CustomAIService {
  static String _cleanValue(String value) {
    var cleaned = value.trim();
    // Strip quotes if they exist
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1).trim();
    } else if (cleaned.startsWith("'") && cleaned.endsWith("'")) {
      cleaned = cleaned.substring(1, cleaned.length - 1).trim();
    }
    // Strip trailing carriage return/newlines
    return cleaned.replaceAll('\r', '').replaceAll('\n', '').trim();
  }

  static String _extractJsonBlock(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && start < end) {
      return text.substring(start, end + 1);
    }
    return text;
  }

  // 1. Get API Key dynamically with fallback
  static String get apiKey {
    const defineKey = String.fromEnvironment('OPENROUTER_API_KEY');
    if (defineKey.isNotEmpty) return _cleanValue(defineKey);
    try {
      final envKey = dotenv.env['OPENROUTER_API_KEY'];
      if (envKey != null && envKey.isNotEmpty) return _cleanValue(envKey);
    } catch (_) {}
    return '';
  }

  // 2. Get Base URL dynamically with fallback
  static String get baseUrl {
    const defineUrl = String.fromEnvironment('OPENROUTER_BASE_URL');
    if (defineUrl.isNotEmpty) {
      final normalized = _normalizeUrl(defineUrl);
      if (kDebugMode) {
        debugPrint(
          "CustomAIService: Using dart-define URL: '$defineUrl' -> '$normalized'",
        );
      }
      return normalized;
    }
    try {
      final envUrl = dotenv.env['OPENROUTER_BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        final normalized = _normalizeUrl(envUrl);
        if (kDebugMode) {
          debugPrint(
            "CustomAIService: Using .env URL: '$envUrl' -> '$normalized' (len: ${envUrl.length}, codeUnits: ${envUrl.codeUnits})",
          );
        }
        return normalized;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("CustomAIService: Error reading .env URL: $e");
      }
    }
    if (kDebugMode) {
      debugPrint(
        "CustomAIService: Using default URL: 'https://api.openrouter.ai/api/v1/chat/completions'",
      );
    }
    return 'https://api.openrouter.ai/api/v1/chat/completions';
  }

  static String _normalizeUrl(String url) {
    final cleanUrl = _cleanValue(url);
    if (cleanUrl.endsWith('/chat/completions')) {
      return cleanUrl;
    }
    if (cleanUrl.endsWith('/')) {
      return '${cleanUrl}chat/completions';
    }
    return '$cleanUrl/chat/completions';
  }

  // 3. Get Default Model dynamically with fallback
  static String get defaultModel {
    const defineModel = String.fromEnvironment('OPENROUTER_MODEL');
    if (defineModel.isNotEmpty) return _cleanValue(defineModel);
    try {
      final envModel = dotenv.env['OPENROUTER_MODEL'];
      if (envModel != null && envModel.isNotEmpty) return _cleanValue(envModel);
    } catch (_) {}
    return 'kr/claude-haiku-4.5'; // Default model selected by user
  }

  /// Send prompt messages history to OpenRouter API and return the raw text reply.
  ///
  /// [messages] is list of chat history:
  /// `[{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}]`
  ///
  /// [systemInstruction] is optional system instruction.
  static Future<String> getChatCompletion(
    List<Map<String, String>> messages, {
    String? systemInstruction,
    String? model,
    double temperature = 0.7,
    int? maxTokens,
  }) async {
    try {
      final selectedModel = model ?? defaultModel;
      final key = apiKey;
      final url = baseUrl;

      if (key.isEmpty) {
        throw Exception(
          'API Key tidak ditemukan. Harap konfigurasi lewat --dart-define atau file .env',
        );
      }

      final List<Map<String, String>> requestMessages = [];

      // Add system instruction at the beginning if present
      if (systemInstruction != null && systemInstruction.isNotEmpty) {
        requestMessages.add({'role': 'system', 'content': systemInstruction});
      }

      // Add remaining conversation messages
      requestMessages.addAll(messages);

      final Map<String, dynamic> body = {
        'model': selectedModel,
        'messages': requestMessages,
        'temperature': temperature,
        'stream': false, // Explicitly request non-streaming response
      };
      if (maxTokens != null) {
        body['max_tokens'] = maxTokens;
      }

      if (kDebugMode) {
        debugPrint("OpenRouter Request Body to $url: ${json.encode(body)}");
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://duitly.app', // Required by OpenRouter
              'X-Title': 'Duitly', // Required by OpenRouter
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        var bodyString = utf8.decode(response.bodyBytes).trim();
        if (kDebugMode) {
          debugPrint(
            "OpenRouter Raw Response (len: ${bodyString.length}): $bodyString",
          );
        }

        // 1. Handle streaming/SSE format lines if it has multiple lines starting with "data:"
        if (bodyString.contains('\ndata:') || bodyString.startsWith('data:')) {
          final lines = bodyString.split('\n');
          var accumulatedContent = '';
          Map<String, dynamic>? lastJson;

          for (final line in lines) {
            final trimmedLine = line.trim();
            if (trimmedLine.startsWith('data:')) {
              var dataContent = trimmedLine.substring(5).trim();

              // Strip trailing "data:" labels if they got concatenated on the same line
              if (dataContent.contains('data:')) {
                dataContent = dataContent.split('data:').first.trim();
              }
              if (dataContent == '[DONE]') continue;

              try {
                // Safely extract the valid JSON block from dataContent
                final cleanDataContent = _extractJsonBlock(dataContent);
                final Map<String, dynamic> jsonPart = json.decode(
                  cleanDataContent,
                );
                lastJson = jsonPart;
                final choices = jsonPart['choices'] as List?;
                if (choices != null && choices.isNotEmpty) {
                  final delta = choices.first['delta'];
                  if (delta != null && delta['content'] != null) {
                    accumulatedContent += delta['content'];
                  } else {
                    final msg = choices.first['message'];
                    if (msg != null && msg['content'] != null) {
                      accumulatedContent += msg['content'];
                    }
                  }
                }
              } catch (_) {}
            }
          }

          if (accumulatedContent.isNotEmpty) {
            return accumulatedContent.trim();
          }

          if (lastJson != null) {
            final choices = lastJson['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final message = choices.first['message'];
              if (message != null && message['content'] != null) {
                return (message['content'] as String).trim();
              }
            }
          }
        }

        // 2. Direct extract JSON block for single-line or wrapped responses (safely handles any trailing data: [DONE])
        try {
          final cleanJson = _extractJsonBlock(bodyString);
          final Map<String, dynamic> data = json.decode(cleanJson);
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final message = choices.first['message'];
            if (message != null && message['content'] != null) {
              return (message['content'] as String).trim();
            }
          }
        } catch (e) {
          debugPrint("CustomAIService: JSON block parsing failed: $e");
        }

        // 3. Fallback: try parsing clean bodyString directly
        if (bodyString.contains('data: [DONE]')) {
          bodyString = bodyString.replaceAll('data: [DONE]', '').trim();
        }
        bodyString = bodyString.replaceAll('data:[DONE]', '').trim();

        // Keep only valid JSON block
        final lastBrace = bodyString.lastIndexOf('}');
        if (lastBrace != -1 && lastBrace < bodyString.length - 1) {
          bodyString = bodyString.substring(0, lastBrace + 1);
        }

        final Map<String, dynamic> data = json.decode(bodyString);
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices.first['message'];
          if (message != null && message['content'] != null) {
            return (message['content'] as String).trim();
          }
        }
        throw Exception('Format respon OpenRouter tidak valid');
      } else {
        if (kDebugMode) {
          debugPrint("OpenRouter Error response: ${response.body}");
        }
        throw Exception(
          'API Error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("CustomAIService Error: $e");
      }
      rethrow;
    }
  }
}
