// lib/screens/chat/chat_screen.dart — FF PRO ARENA PK — Redesigned Chat
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker     = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(_onType);
  }

  @override
  void dispose() {
    _msgCtrl.removeListener(_onType);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _clearTyping();
    super.dispose();
  }

  void _onType() {
    final uid = context.read<AppProvider>().currentUser?.uid;
    if (uid != null) {
      context.read<AppProvider>().db.setTyping(uid, _msgCtrl.text.isNotEmpty);
    }
  }

  void _clearTyping() {
    final uid = context.read<AppProvider>().currentUser?.uid;
    if (uid != null) context.read<AppProvider>().db.setTyping(uid, false);
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final provider = context.read<AppProvider>();
    final user = provider.currentUser;
    if (user == null) return;
    if (user.isMuted) {
      _showSnack('You are muted by admin.');
      return;
    }
    _msgCtrl.clear();
    await provider.db.sendMessage(MessageModel(
      id: '', senderId: user.uid,
      senderName: user.displayName,
      senderRole: user.role,
      content: text, type: MessageType.text,
      createdAt: DateTime.now(),
    ));
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final user = context.read<AppProvider>().currentUser;
    if (user == null || user.isMuted) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final ref = FirebaseStorage.instance
          .ref('chat_images/${const Uuid().v4()}.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await context.read<AppProvider>().db.sendMessage(MessageModel(
        id: '', senderId: user.uid,
        senderName: user.displayName,
        senderRole: user.role,
        content: url, type: MessageType.image,
        createdAt: DateTime.now(),
      ));
      _scrollToBottom();
    } catch (_) {
      _showSnack('Failed to send image.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final me = provider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        automaticallyImplyLeading: false,
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.neonGradient,
            ),
            child: const Icon(Icons.forum_rounded,
                color: AppTheme.background, size: 18),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('COMMUNITY CHAT',
                style: AppTheme.heading3.copyWith(fontSize: 15)),
            StreamBuilder<List<MessageModel>>(
              stream: provider.db.messagesStream(),
              builder: (_, snap) {
                final count = snap.data?.length ?? 0;
                return Text('$count messages',
                    style: AppTheme.caption.copyWith(
                        color: AppTheme.neonGreen));
              },
            ),
          ]),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: Column(children: [
        // Online users banner
        _OnlineBanner(provider: provider),

        // Messages
        Expanded(
          child: StreamBuilder<List<MessageModel>>(
            stream: provider.db.messagesStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(
                    color: AppTheme.neonGreen));
              }
              final msgs = snap.data ?? [];
              if (msgs.isEmpty) {
                return Center(child: Column(
                  mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 60, color: AppTheme.textMuted),
                  const SizedBox(height: 12),
                  Text('No messages yet. Say hello! 👋',
                      style: AppTheme.bodySmall),
                ]));
              }
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                itemCount: msgs.length,
                itemBuilder: (_, i) {
                  final msg = msgs[i];
                  final isMe = msg.senderId == me?.uid;
                  final showDate = i == 0 ||
                      !_sameDay(msgs[i - 1].createdAt, msg.createdAt);
                  return Column(children: [
                    if (showDate) _DateDivider(msg.createdAt),
                    _MessageBubble(msg: msg, isMe: isMe),
                  ]);
                },
              );
            },
          ),
        ),

        // Typing indicator
        _TypingIndicator(provider: provider, myUid: me?.uid),

        // Input bar
        _InputBar(
          controller: _msgCtrl,
          isUploading: _isUploading,
          onSend: _sendText,
          onImage: _sendImage,
          isMuted: me?.isMuted ?? false,
        ),
      ]),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── ONLINE BANNER ─────────────────────────────────────────────────────────────
class _OnlineBanner extends StatelessWidget {
  final AppProvider provider;
  const _OnlineBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: provider.db.allUsersStream().map(
            (users) => users.where((u) => u.isOnline).toList()),
      builder: (_, snap) {
        final users = snap.data ?? [];
        if (users.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 44,
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppTheme.online)),
            const SizedBox(width: 6),
            Text('${users.length} online',
                style: AppTheme.caption.copyWith(color: AppTheme.neonGreen)),
            const SizedBox(width: 12),
            Expanded(child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: users.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Chip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(users[i].displayName,
                      style: AppTheme.caption.copyWith(
                          color: AppTheme.textPrimary)),
                  backgroundColor: AppTheme.surfaceLight,
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: AppTheme.divider),
                ),
              ),
            )),
          ]),
        );
      },
    );
  }
}

// ── DATE DIVIDER ──────────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider(this.date);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      label = 'TODAY';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider(color: AppTheme.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: AppTheme.caption.copyWith(letterSpacing: 1.5)),
        ),
        const Expanded(child: Divider(color: AppTheme.divider)),
      ]),
    );
  }
}

// ── MESSAGE BUBBLE ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  const _MessageBubble({required this.msg, required this.isMe});

  Color get _roleColor {
    switch (msg.senderRole) {
      case AppConstants.roleAdmin: return AppTheme.gold;
      case AppConstants.roleVip:   return AppTheme.accentPurple;
      default:                      return AppTheme.neonGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4, bottom: 4,
        left: isMe ? 48 : 0,
        right: isMe ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: _roleColor.withOpacity(0.2),
              child: Text(msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                  style: TextStyle(color: _roleColor, fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe) Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 2),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(msg.senderName,
                      style: AppTheme.caption.copyWith(
                          color: _roleColor, fontWeight: FontWeight.w700)),
                  if (msg.senderRole == AppConstants.roleAdmin) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('ADMIN', style: AppTheme.caption.copyWith(
                          color: AppTheme.background, fontSize: 8,
                          fontWeight: FontWeight.w900)),
                    ),
                  ],
                ]),
              ),
              Container(
                padding: msg.type == 'image'
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [Color(0xFF005C30), Color(0xFF003D20)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMe ? null : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isMe ? 14 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 14),
                  ),
                  border: Border.all(
                    color: isMe
                        ? AppTheme.neonGreen.withOpacity(0.2)
                        : AppTheme.divider,
                    width: 0.5,
                  ),
                ),
                child: msg.type == 'image'
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: msg.content,
                          width: 200, height: 150,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 200, height: 150,
                            color: AppTheme.surfaceLight,
                            child: const Center(child: CircularProgressIndicator(
                                color: AppTheme.neonGreen, strokeWidth: 2)),
                          ),
                        ),
                      )
                    : Text(msg.content,
                        style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textPrimary, height: 1.4)),
              ),
              const SizedBox(height: 3),
              Text(timeago.format(msg.createdAt),
                  style: AppTheme.caption.copyWith(fontSize: 9)),
            ],
          )),
        ],
      ),
    );
  }
}

// ── TYPING INDICATOR ──────────────────────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  final AppProvider provider;
  final String? myUid;
  const _TypingIndicator({required this.provider, this.myUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: provider.db.typingUsersStream(myUid ?? ''),
      builder: (_, snap) {
        final typers = snap.data ?? [];
        if (typers.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          color: AppTheme.surface,
          child: Row(children: [
            _Dots(),
            const SizedBox(width: 8),
            Text('Someone is typing...',
                style: AppTheme.caption.copyWith(
                    color: AppTheme.neonGreen)),
          ]),
        );
      },
    );
  }
}

class _Dots extends StatefulWidget {
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(children: List.generate(3, (i) {
        final delay = i * 0.33;
        final v = ((_c.value - delay) % 1.0).clamp(0.0, 1.0);
        final op = v < 0.5 ? v * 2 : 2 - v * 2;
        return Container(
          width: 5, height: 5,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.neonGreen.withOpacity(0.3 + op * 0.7),
          ),
        );
      })),
    );
  }
}

// ── INPUT BAR ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isUploading;
  final VoidCallback onSend;
  final VoidCallback onImage;
  final bool isMuted;

  const _InputBar({
    required this.controller, required this.isUploading,
    required this.onSend, required this.onImage, required this.isMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(children: [
        // Image btn
        GestureDetector(
          onTap: isMuted ? null : onImage,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.divider),
            ),
            child: isUploading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                        color: AppTheme.neonGreen, strokeWidth: 2))
                : Icon(Icons.image_outlined,
                    color: isMuted ? AppTheme.textMuted : AppTheme.textSecondary,
                    size: 20),
          ),
        ),
        const SizedBox(width: 8),

        // Text input
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !isMuted,
            onSubmitted: (_) => onSend(),
            style: AppTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: isMuted ? 'You are muted.' : 'Type a message…',
              hintStyle: AppTheme.caption,
              filled: true,
              fillColor: AppTheme.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: AppTheme.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: AppTheme.neonGreen, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Send btn
        GestureDetector(
          onTap: isMuted ? null : onSend,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: isMuted ? null : AppTheme.neonGradient,
              color: isMuted ? AppTheme.surfaceLight : null,
              borderRadius: BorderRadius.circular(22),
              boxShadow: isMuted ? null : [
                BoxShadow(color: AppTheme.neonGreen.withOpacity(0.4),
                    blurRadius: 12),
              ],
            ),
            child: Icon(Icons.send_rounded,
                color: isMuted ? AppTheme.textMuted : AppTheme.background,
                size: 20),
          ),
        ),
      ]),
    );
  }
}
