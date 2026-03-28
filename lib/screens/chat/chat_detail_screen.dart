import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_bubble.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const ChatDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _inputHasText = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
    // Load messages after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatDetailProvider(widget.sessionId).notifier)
          .fetchMessages();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final hasText = _inputController.text.trim().isNotEmpty;
    if (hasText != _inputHasText) {
      setState(() => _inputHasText = hasText);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();

    final notifier = ref.read(chatDetailProvider(widget.sessionId).notifier);
    await notifier.sendMessage(text);

    // Update session last message in the sessions list
    ref
        .read(chatSessionsProvider.notifier)
        .updateLastMessage(widget.sessionId, text);

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatDetailProvider(widget.sessionId));

    // Auto-scroll when streaming
    if (state.isStreaming) _scrollToBottom();

    // Show error
    ref.listen(chatDetailProvider(widget.sessionId), (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        ref
            .read(chatDetailProvider(widget.sessionId).notifier)
            .clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asisten MindEase',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  state.isStreaming ? 'Sedang mengetik...' : 'Online',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: state.isStreaming
                        ? AppTheme.primary
                        : Colors.green[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading && state.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _MessageList(
                    messages: state.messages,
                    streamingContent: state.streamingContent,
                    isStreaming: state.isStreaming,
                    scrollController: _scrollController,
                    onScrollToBottom: _scrollToBottom,
                  ),
          ),
          _InputBar(
            controller: _inputController,
            hasText: _inputHasText,
            isStreaming: state.isStreaming,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── Message list ────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final List<ChatMessage> messages;
  final String streamingContent;
  final bool isStreaming;
  final ScrollController scrollController;
  final VoidCallback onScrollToBottom;

  const _MessageList({
    required this.messages,
    required this.streamingContent,
    required this.isStreaming,
    required this.scrollController,
    required this.onScrollToBottom,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = messages.length +
        (isStreaming ? 1 : 0) +
        (messages.isEmpty && !isStreaming ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Empty state
        if (messages.isEmpty && !isStreaming) {
          return _WelcomeMessage();
        }

        // Streaming bubble at the end
        if (isStreaming && index == messages.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: streamingContent.isEmpty
                ? _TypingIndicator()
                : StreamingBubble(content: streamingContent),
          );
        }

        final message = messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ChatBubble(message: message),
        );
      },
    );
  }
}

class _WelcomeMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppTheme.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Halo! Saya Asisten MindEase',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ceritakan apa yang sedang kamu rasakan.\nSaya siap mendengarkan dan membantu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final offset = ((_controller.value * 3) - i).clamp(0.0, 1.0);
                final bounce = offset < 0.5 ? offset * 2 : (1 - offset) * 2;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 7,
                  height: 7 + bounce * 5,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.5 + bounce * 0.5),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

// ── Input bar ───────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final bool isStreaming;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.hasText,
    required this.isStreaming,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPadding),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textHint,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isStreaming
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 44,
                      height: 44,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : GestureDetector(
                      key: const ValueKey('send'),
                      onTap: hasText ? onSend : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: hasText
                              ? AppTheme.primary
                              : AppTheme.primary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
