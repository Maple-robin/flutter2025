import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GenerativeService {
  static const List<String> _modelCandidates = [
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  static Future<String> generate(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEYが設定されていません。.envを確認してください。');
    }

    const maxRetry = 2;

    for (final modelName in _modelCandidates) {
      for (var attempt = 1; attempt <= maxRetry; attempt++) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            requestOptions: const RequestOptions(apiVersion: 'v1'),
          );

          final response = await model.generateContent([Content.text(prompt)]);
          final responseText = response.text;

          if (responseText == null || responseText.isEmpty) {
            throw Exception('AIからの返答が空でした。');
          }

          return responseText;
        } catch (error) {
          final message = error.toString();

          final isTemp = message.contains('503') ||
              message.contains('UNAVAILABLE') ||
              message.contains('high demand') ||
              message.contains('currently experiencing high demand');

          final lower = message.toLowerCase();
          final isQuota = lower.contains('quota') ||
              lower.contains('rate limit') ||
              lower.contains('you exceeded') ||
              lower.contains('please retry in');

          if (isQuota) {
            // Let caller handle quota errors (cooldown, user notification)
            throw Exception(message);
          }

          if (attempt < maxRetry && isTemp) {
            await Future.delayed(Duration(seconds: 2 * attempt));
            continue;
          }

          // try next model
          break;
        }
      }
    }

    // 最終手段で1.5-flashを直接試す
    final fallback = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final response = await fallback.generateContent([Content.text(prompt)]);
    final fallbackText = response.text;

    if (fallbackText == null || fallbackText.isEmpty) {
      throw Exception('AIからの返答が空でした。');
    }

    return fallbackText;
  }

  static String extractJsonString(String responseText) {
    final trimmed = responseText.trim();
    final startIndex = trimmed.indexOf('{');
    if (startIndex < 0) {
      throw FormatException('JSON開始文字「{」が見つかりませんでした。', responseText);
    }

    int depth = 0;
    bool inString = false;
    bool escape = false;

    for (var i = startIndex; i < trimmed.length; i++) {
      final char = trimmed[i];
      if (inString) {
        if (escape) {
          escape = false;
        } else if (char == '\\') {
          escape = true;
        } else if (char == '"') {
          inString = false;
        }
      } else {
        if (char == '"') {
          inString = true;
        } else if (char == '{') {
          depth++;
        } else if (char == '}') {
          depth--;
          if (depth == 0) {
            return trimmed.substring(startIndex, i + 1);
          }
        }
      }
    }

    throw FormatException('JSONの終了文字が見つかりませんでした。', responseText);
  }

  static Map<String, dynamic> parseJsonObject(String responseText) {
    final jsonString = extractJsonString(responseText);
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSONのルートがオブジェクトではありません。');
    }
    return decoded;
  }
}
