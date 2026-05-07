import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../chat/private_chat_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final UserModel user;
  const UserProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final me = context.read<AppProvider>().currentUser;
    final isMe = me?.uid == user.uid;
    final c = user.isAdmin ? AppTheme.gold : user.isVip ? AppTheme.gold : AppTheme.neonGreen;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(backgroundColor: AppTheme.surface,
        title: Text(user.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        // Avatar
        Container(width: 100, height: 100,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c, width: 3),
            boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 20)]),
          child: user.avatarUrl != null
              ? ClipOval(child: CachedNetworkImage(imageUrl: user.avatarUrl!, fit: BoxFit.cover))
              : Container(decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(0.15)),
                child: Center(child: Text(user.displayName[0].toUpperCase(),
                  style: TextStyle(color: c, fontSize: 40, fontWeight: FontWeight.w900))))),
        const SizedBox(height: 16),
        // Name + badge
        Text(user.displayName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        if (user.isAdmin) _badge('👑 ADMIN', AppTheme.gold)
        else if (user.isVip) _badge('⭐ VIP', AppTheme.gold),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 8, height: 8,
            decoration: BoxDecoration(color: user.isOnline ? AppTheme.neonGreen : Colors.white24, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(user.isOnline ? 'Online' : 'Offline',
            style: TextStyle(color: user.isOnline ? AppTheme.neonGreen : Colors.white38)),
        ]),
        const SizedBox(height: 24),
        // Info cards
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider)),
          child: Column(children: [
            _row('Free Fire UID', user.freeFireUid, c),
            const Divider(color: Color(0xFF1E2D1E)),
            _row('Role', user.role.toUpperCase(), c),
            const Divider(color: Color(0xFF1E2D1E)),
            _row('Tournaments', '${user.joinedTournaments.length}', AppTheme.neonGreen),
          ])),
        const SizedBox(height: 24),
        if (!isMe) SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatScreen(otherUser: user))),
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
            label: const Text('Message karo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
      ])),
    );
  }

  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withOpacity(0.4))),
    child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.bold)));

  Widget _row(String label, String value, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white54)),
      Text(value, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
    ]));
}
