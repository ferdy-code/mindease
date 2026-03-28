import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return _BubbleLayout(isUser: isUser, content: message.content);
  }
}

/// Streaming bubble shown while AI is typing — appends a blinking cursor.
class StreamingBubble extends StatefulWidget {
  final String content;

  const StreamingBubble({super.key, required this.content});

  @override
  State<StreamingBubble> createState() => _StreamingBubbleState();
}

class _StreamingBubbleState extends State<StreamingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BubbleLayout(
      isUser: false,
      content: widget.content,
      trailing: AnimatedBuilder(
        animation: _cursorController,
        builder: (_, __) => Opacity(
          opacity: _cursorController.value,
          child: Text(
            '▌',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared layout ───────────────────────────────────────────────────────────

class _BubbleLayout extends StatelessWidget {
  final bool isUser;
  final String content;
  final Widget? trailing;

  const _BubbleLayout({
    required this.isUser,
    required this.content,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: EdgeInsets.only(
            left: isUser ? 48 : 0,
            right: isUser ? 0 : 48,
            bottom: 4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: trailing != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(child: _messageText(isUser)),
                    trailing!,
                  ],
                )
              : _messageText(isUser),
        ),
      ),
    );
  }

  Widget _messageText(bool isUser) {
    return Text(
      content,
      style: GoogleFonts.poppins(
        fontSize: 13,
        height: 1.5,
        color: isUser ? Colors.white : AppTheme.textPrimary,
      ),
    );
  }
}
