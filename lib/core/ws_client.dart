import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

/// SSE client for streaming AI responses from the backend.
///
/// Usage:
/// ```dart
/// final stream = SseClient().streamMessage(sessionId: id, content: text);
/// await for (final chunk in stream) { ... }
/// ```
class SseClient {
  static final SseClient _instance = SseClient._internal();
  factory SseClient() => _instance;
  SseClient._internal();

  /// Sends [content] to [sessionId] and streams back AI response chunks.
  /// Yields text chunks as they arrive (character groups, not single chars).
  Stream<String> streamMessage({
    required String sessionId,
    required String content,
  }) async* {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);

    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        responseType: ResponseType.stream,
      ),
    );

    late Response<ResponseBody> response;
    try {
      response = await dio.post<ResponseBody>(
        '/chat/send',
        data: {'sessionId': sessionId, 'message': content},
      );
    } catch (e) {
      log('[SseClient] connect error: $e');
      rethrow;
    }

    final stream = response.data!.stream;
    final buffer = StringBuffer();

    await for (final chunk in stream.cast<Uint8List>()) {
      final text = utf8.decode(chunk, allowMalformed: true);
      buffer.write(text);

      // Process complete lines from buffer
      final raw = buffer.toString();
      final lines = raw.split('\n');

      // Keep the last (potentially incomplete) line in the buffer
      buffer
        ..clear()
        ..write(lines.last);

      for (var i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.startsWith('data:')) {
          final data = line.substring(5).trim();
          if (data == '[DONE]') return;
          if (data.isEmpty) continue;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            // Support both {chunk: "..."} and {content: "..."} formats
            final piece =
                (json['chunk'] ?? json['content'] ?? json['text']) as String?;
            if (piece != null && piece.isNotEmpty) {
              yield piece;
            }
          } catch (_) {
            // Plain text data (not JSON)
            if (data.isNotEmpty) yield data;
          }
        }
      }
    }

    // Flush any remaining buffered data
    final remaining = buffer.toString().trim();
    if (remaining.startsWith('data:')) {
      final data = remaining.substring(5).trim();
      if (data.isNotEmpty && data != '[DONE]') {
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final piece =
              (json['chunk'] ?? json['content'] ?? json['text']) as String?;
          if (piece != null && piece.isNotEmpty) yield piece;
        } catch (_) {
          yield data;
        }
      }
    }
  }
}
