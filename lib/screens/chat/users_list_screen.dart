import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import 'private_chat_screen.dart';
import '../profile/user_profile_screen.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final me = provider.currentUser;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: const Text('Players', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: provider.db.allUsersStream(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen));
          final users = snap.data!.where((u) => u.uid != me?.uid).toList();
          users.sort((a, b) {
            if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
            if (a.isVip != b.isVip) return a.isVip ? -1 : 1;
            return a.displayName.compareTo(b.displayName);
          });
          if (users.isEmpty) return const Center(child: Text('Koi user nahin', style: TextStyle(color: Colors.white38)));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (_, i) => _UserTile(user: users[i]),
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = user.isAdmin ? AppTheme.gold : user.isVip ? AppTheme.gold : AppTheme.neonGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.2))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Stack(children: [
          Container(width: 46, height: 46,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c, width: 2)),
            child: user.avatarUrl != null
                ? ClipOval(child: CachedNetworkImage(imageUrl: user.avatarUrl!, fit: BoxFit.cover))
                : Container(decoration: BoxDecoration(shape: BoxShape.circle,
                    color: c.withOpacity(0.15)),
                  child: Center(child: Text(user.displayName[0].toUpperCase(),
                    style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 18))))),
          if (user.isOnline) Positioned(bottom: 0, right: 0,
            child: Container(width: 12, height: 12,
              decoration: BoxDecoration(color: AppTheme.neonGreen, shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surface, width: 2)))),
        ]),
        title: Row(children: [
          Flexible(child: Text(user.displayName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 6),
          if (user.isAdmin) _chip('👑 ADMIN', AppTheme.gold)
          else if (user.isVip) _chip('⭐ VIP', AppTheme.gold),
        ]),
        subtitle: Text('UID: ${user.freeFireUid}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.person_outline, color: Colors.white38, size: 20),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)))),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivateChatScreen(otherUser: user))),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.neonGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.neonGreen.withOpacity(0.5))),
              child: const Text('Chat', style: TextStyle(color: AppTheme.neonGreen, fontSize: 12, fontWeight: FontWeight.bold))),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
    child: Text(t, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)));
}
