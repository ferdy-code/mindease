import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/ws_client.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import 'auth_provider.dart';

// ── Session list ────────────────────────────────────────────────────────────

class ChatSessionsState {
  final List<ChatSession> sessions;
  final bool isLoading;
  final String? error;

  const ChatSessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
  });

  ChatSessionsState copyWith({
    List<ChatSession>? sessions,
    bool? isLoading,
    String? error,
  }) => ChatSessionsState(
    sessions: sessions ?? this.sessions,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class ChatSessionsNotifier extends StateNotifier<ChatSessionsState> {
  ChatSessionsNotifier() : super(const ChatSessionsState());

  void reset() => state = const ChatSessionsState();

  Future<void> fetchSessions() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().dio.get('/chat/sessions');
      final raw = response.data['data'];
      final rawList = raw is List
          ? raw
          : (raw as Map<String, dynamic>)['data'] as List;
      log('[ChatSessions] fetch response: $rawList');
      final sessions = rawList
          .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (e) {
      log('[ChatSessions] fetch error: $e');
      state = state.copyWith(isLoading: false, error: 'Gagal memuat sesi');
    }
  }

  Future<ChatSession?> createSession({String title = 'Sesi Baru'}) async {
    try {
      final response = await ApiClient().dio.post(
        '/chat/sessions',
        data: {'title': title},
      );
      final raw = response.data['data'];
      final data = raw is Map<String, dynamic> && raw.containsKey('data')
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      log('[ChatSessions] create response: $data');
      final session = ChatSession.fromJson(data);
      state = state.copyWith(sessions: [session, ...state.sessions]);
      return session;
    } catch (e) {
      log('[ChatSessions] create error: $e');
      return null;
    }
  }

  Future<void> deleteSession(String id) async {
    final prev = state.sessions;
    state = state.copyWith(sessions: prev.where((s) => s.id != id).toList());
    try {
      await ApiClient().dio.delete('/chat/sessions/$id');
    } catch (e) {
      log('[ChatSessions] delete error: $e');
      state = state.copyWith(sessions: prev);
      rethrow;
    }
  }

  void updateLastMessage(String sessionId, String message) {
    final updated = state.sessions.map((s) {
      if (s.id != sessionId) return s;
      return ChatSession(
        id: s.id,
        title: s.title,
        lastMessage: message,
        createdAt: s.createdAt,
        updatedAt: DateTime.now(),
      );
    }).toList();
    state = state.copyWith(sessions: updated);
  }
}

final chatSessionsProvider =
    StateNotifierProvider<ChatSessionsNotifier, ChatSessionsState>((ref) {
      final notifier = ChatSessionsNotifier();
      ref.listen<AuthState>(authProvider, (_, next) {
        if (next.status == AuthStatus.authenticated) {
          notifier.fetchSessions();
        } else if (next.status == AuthStatus.unauthenticated) {
          notifier.reset();
        }
      });
      if (ref.read(authProvider).status == AuthStatus.authenticated) {
        notifier.fetchSessions();
      }
      return notifier;
    });

// ── Chat detail (messages + streaming) ─────────────────────────────────────

class ChatDetailState {
  final String sessionId;
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isStreaming;
  final String streamingContent;
  final String? error;

  const ChatDetailState({
    required this.sessionId,
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.streamingContent = '',
    this.error,
  });

  ChatDetailState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? streamingContent,
    String? error,
  }) => ChatDetailState(
    sessionId: sessionId,
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    isStreaming: isStreaming ?? this.isStreaming,
    streamingContent: streamingContent ?? this.streamingContent,
    error: error,
  );
}

class ChatDetailNotifier extends StateNotifier<ChatDetailState> {
  ChatDetailNotifier(String sessionId)
    : super(ChatDetailState(sessionId: sessionId));

  Future<void> fetchMessages() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient().dio.get(
        '/chat/sessions/${state.sessionId}/messages',
      );
      final raw = response.data['data']['messages'];
      final rawList = raw is List
          ? raw
          : (raw as Map<String, dynamic>)['data'] as List;
      final messages = rawList
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      log('[ChatDetail] fetch error: $e');
      state = state.copyWith(isLoading: false, error: 'Gagal memuat pesan');
    }
  }

  /// Sends a user message and streams the AI response character-by-character.
  Future<void> sendMessage(String content) async {
    if (state.isStreaming) return;

    // Add user message optimistically
    final userMsg = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: state.sessionId,
      role: MessageRole.user,
      content: content,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isStreaming: true,
      streamingContent: '',
    );

    final accumulated = StringBuffer();

    try {
      final stream = SseClient().streamMessage(
        sessionId: state.sessionId,
        content: content,
      );

      await for (final chunk in stream) {
        accumulated.write(chunk);
        state = state.copyWith(streamingContent: accumulated.toString());
      }

      // Streaming complete — add final AI message
      if (accumulated.isNotEmpty) {
        final aiMsg = ChatMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: state.sessionId,
          role: MessageRole.assistant,
          content: accumulated.toString(),
          createdAt: DateTime.now(),
        );
        state = state.copyWith(
          messages: [...state.messages, aiMsg],
          isStreaming: false,
          streamingContent: '',
        );
      } else {
        state = state.copyWith(isStreaming: false, streamingContent: '');
      }
    } catch (e) {
      log('[ChatDetail] stream error: $e');
      state = state.copyWith(
        isStreaming: false,
        streamingContent: '',
        error: 'Gagal mengirim pesan',
      );
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final chatDetailProvider =
    StateNotifierProvider.family<ChatDetailNotifier, ChatDetailState, String>((
      ref,
      sessionId,
    ) {
      return ChatDetailNotifier(sessionId);
    });
