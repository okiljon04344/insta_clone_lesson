import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import 'call_screen.dart';

class ChatScreen extends StatefulWidget {
  final UserModel otherUser;

  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _myUid = FirebaseAuth.instance.currentUser!.uid;
  bool _isSending = false;
  bool _isUploadingImage = false;
  bool _isTyping = false;
  DateTime? _lastMarkSeenAt;

  @override
  void initState() {
    super.initState();
    _chatService.markSeen(widget.otherUser.uid);
    _chatService.setOnline(true);
  }

  @override
  void dispose() {
    // Turn typing off
    _chatService.setTyping(widget.otherUser.uid, false);
    _chatService.setOnline(false);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged(String val) {
    final typing = val.trim().isNotEmpty;
    if (typing != _isTyping) {
      _isTyping = typing;
      _chatService.setTyping(widget.otherUser.uid, typing);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear();
    _onTextChanged('');
    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(widget.otherUser.uid, text);
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickImageSource() async {
    if (_isUploadingImage) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppTheme.white,
                  ),
                  title: Text(
                    context.tr('camera'),
                    style: const TextStyle(color: AppTheme.white),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppTheme.white,
                  ),
                  title: Text(
                    context.tr('gallery'),
                    style: const TextStyle(color: AppTheme.white),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      await _sendImage(source);
    }
  }

  Future<void> _sendImage(ImageSource source) async {
    if (_isUploadingImage) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked == null) return;
    if (!mounted) return;

    setState(() => _isUploadingImage = true);
    try {
      await _chatService.sendImageMessage(widget.otherUser.uid, picked);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('image_send_failed')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        leadingWidth: 30,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.darkGrey,
              backgroundImage: widget.otherUser.photoUrl.isNotEmpty
                  ? NetworkImage(widget.otherUser.photoUrl)
                  : null,
              child: widget.otherUser.photoUrl.isEmpty
                  ? const Icon(Icons.person, color: AppTheme.grey, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.otherUser.username,
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (widget.otherUser.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: AppTheme.blue,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                // Online or lastSeen status
                StreamBuilder<Map<String, dynamic>>(
                  stream: _chatService.onlineStatusStream(widget.otherUser.uid),
                  builder: (ctx, snap) {
                    final isOnline = snap.data?['isOnline'] == true;
                    final lastSeen = snap.data?['lastSeen'] as DateTime?;
                    String subtitle;
                    if (isOnline) {
                      subtitle = context.tr('online');
                    } else if (lastSeen != null) {
                      final diff = DateTime.now().difference(lastSeen);
                      if (diff.inMinutes < 1) {
                        subtitle = context.tr('seen_just_now');
                      } else if (diff.inHours < 1) {
                        subtitle =
                            '${diff.inMinutes} ${context.tr('minutes_ago')}';
                      } else if (diff.inDays < 1) {
                        subtitle = '${diff.inHours} ${context.tr('hours_ago')}';
                      } else {
                        subtitle = '${diff.inDays} ${context.tr('days_ago')}';
                      }
                    } else {
                      subtitle = widget.otherUser.displayName;
                    }
                    return Text(
                      subtitle,
                      style: TextStyle(
                        color: isOnline ? Colors.green : AppTheme.grey,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Voice call
          IconButton(
            icon: const Icon(Icons.call_outlined, color: AppTheme.white),
            onPressed: () => _startCall(isVideo: false),
          ),
          // Video call
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: AppTheme.white),
            onPressed: () => _startCall(isVideo: true),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(color: AppTheme.divider, height: 1),

          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.messagesStream(widget.otherUser.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.blue),
                  );
                }

                final messages = snap.data ?? [];
                if (messages.isNotEmpty) {
                  _markSeenSoon();
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppTheme.darkGrey,
                          backgroundImage: widget.otherUser.photoUrl.isNotEmpty
                              ? NetworkImage(widget.otherUser.photoUrl)
                              : null,
                          child: widget.otherUser.photoUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: AppTheme.grey,
                                  size: 40,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.otherUser.displayName,
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${widget.otherUser.username}',
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('start_chat_prompt'),
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == _myUid;
                    final showDate =
                        i == 0 ||
                        !_isSameDay(messages[i - 1].createdAt, msg.createdAt);
                    return Column(
                      children: [
                        if (showDate) _DateSeparator(date: msg.createdAt),
                        _MessageBubble(message: msg, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Typing indicator
          StreamBuilder<bool>(
            stream: _chatService.typingStream(widget.otherUser.uid),
            builder: (ctx, snap) {
              final isTyping = snap.data ?? false;
              if (!isTyping) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    _TypingDots(),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.otherUser.username} ${context.tr('typing')}...',
                      style: const TextStyle(
                        color: AppTheme.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.black,
              border: Border(top: BorderSide(color: AppTheme.divider)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: _isUploadingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppTheme.blue,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.photo_outlined, color: AppTheme.white),
                  onPressed: _isUploadingImage ? null : _pickImageSource,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.darkGrey,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 14,
                            ),
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: context.tr('write_message'),
                              hintStyle: const TextStyle(color: AppTheme.grey),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                            onChanged: _onTextChanged,
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.emoji_emotions_outlined,
                            color: AppTheme.grey,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.blue,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: AppTheme.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: AppTheme.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startCall({required bool isVideo}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          otherUser: widget.otherUser,
          isVideo: isVideo,
          isOutgoing: true,
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _markSeenSoon() {
    final now = DateTime.now();
    if (_lastMarkSeenAt != null &&
        now.difference(_lastMarkSeenAt!).inSeconds < 5) {
      return;
    }
    _lastMarkSeenAt = now;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_chatService.markSeen(widget.otherUser.uid));
    });
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.blue : AppTheme.darkGrey,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: isMe
                    ? const Radius.circular(18)
                    : const Radius.circular(4),
                bottomRight: isMe
                    ? const Radius.circular(4)
                    : const Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (message.type == 'image')
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _ChatImagePreview(
                            imageUrl: message.text,
                            sentAt: _formatTime(message.createdAt),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: message.text,
                        width: MediaQuery.of(context).size.width * 0.58,
                        height: 220,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          height: 220,
                          color: AppTheme.divider,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.blue,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (_, _, _) => Container(
                          height: 220,
                          color: AppTheme.divider,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppTheme.grey,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    message.text,
                    style: const TextStyle(color: AppTheme.white, fontSize: 14),
                  ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        color: AppTheme.white.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 3),
                      Icon(
                        message.seen ? Icons.done_all : Icons.done,
                        size: 12,
                        color: message.seen
                            ? Colors.lightBlueAccent
                            : AppTheme.white.withValues(alpha: 0.6),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.darkGrey,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _label(context, date),
          style: const TextStyle(color: AppTheme.grey, fontSize: 11),
        ),
      ),
    );
  }

  String _label(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value = DateTime(date.year, date.month, date.day);
    final diff = today.difference(value).inDays;
    if (diff == 0) return AppStrings.of(context).t('today');
    if (diff == 1) return AppStrings.of(context).t('yesterday');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _ChatImagePreview extends StatelessWidget {
  final String imageUrl;
  final String sentAt;

  const _ChatImagePreview({required this.imageUrl, required this.sentAt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: Text(
          sentAt,
          style: const TextStyle(color: AppTheme.white, fontSize: 14),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, _) => const Center(
              child: CircularProgressIndicator(color: AppTheme.blue),
            ),
            errorWidget: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: AppTheme.grey,
              size: 42,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return Row(
          children: List.generate(3, (i) {
            final offset = (i / 3);
            final val = ((_ctrl.value - offset).abs() % 1.0);
            final opacity = val < 0.5 ? val * 2 : 2 - val * 2;
            return Container(
              margin: const EdgeInsets.only(right: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.grey.withValues(alpha: 0.3 + opacity * 0.7),
              ),
            );
          }),
        );
      },
    );
  }
}
