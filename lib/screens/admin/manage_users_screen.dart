// lib/screens/admin/manage_users_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/services.dart';
import '../../utils/app_theme.dart';
import '../splash_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('MANAGE USERS', style: AppTheme.heading3),
        centerTitle: true,
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _search = v.trim()),
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name, mobile or FF UID...',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
              filled: true, fillColor: AppTheme.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.divider)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.divider)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.neonGreen)),
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: db.allUsersStream(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(
                  color: AppTheme.neonGreen));
              }
              var users = snap.data ?? [];
              if (_search.isNotEmpty) {
                final q = _search.toLowerCase();
                users = users.where((u) =>
                    u.displayName.toLowerCase().contains(q) ||
                    u.mobile.contains(q) ||
                    u.freeFireUid.contains(q)).toList();
              }
              if (users.isEmpty) {
                return Center(child: Text('No users found', style: AppTheme.bodySmall));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (_, i) => _UserCard(user: users[i], db: db),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final FirestoreService db;
  const _UserCard({required this.user, required this.db});

  @override
  Widget build(BuildContext context) {
    final roleColor = user.isAdmin ? AppTheme.gold
                    : user.isVip  ? AppTheme.silver : AppTheme.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: user.isBanned ? AppTheme.danger.withOpacity(0.3) : AppTheme.divider,
          width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          CircleAvatar(
            radius: 20, backgroundColor: roleColor.withOpacity(0.15),
            child: Text(user.displayName[0].toUpperCase(),
              style: TextStyle(color: roleColor, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(user.displayName,
                style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              if (user.isBanned) _badge('BANNED', AppTheme.danger),
              if (user.isMuted) _badge('MUTED', AppTheme.warning),
            ]),
            const SizedBox(height: 2),
            // Admin-only: show mobile number
            Text(user.mobile, style: AppTheme.bodySmall.copyWith(color: AppTheme.neonGreen)),
            Text('FF UID: ${user.freeFireUid}', style: AppTheme.caption),
          ])),
          // Online dot
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: user.isOnline ? AppTheme.online : AppTheme.offline,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.surface, width: 1.5),
            ),
          ),
        ]),

        const Divider(height: 20, color: AppTheme.divider),

        // Balance info
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _infoItem('Wallet', 'Rs. ${user.walletBalance.toInt()}', AppTheme.neonGreen),
          _infoItem('Winning', 'Rs. ${user.winningBalance.toInt()}', AppTheme.gold),
          _infoItem('Joined', '${user.joinedTournaments.length}', AppTheme.accent),
          _infoItem('Role', user.role.toUpperCase(), roleColor),
        ]),

        const SizedBox(height: 12),

        // Action buttons
        Wrap(spacing: 8, runSpacing: 8, children: [
          // Role toggle
          if (!user.isAdmin)
            _actionBtn(
              user.isVip ? 'Remove VIP' : 'Make VIP',
              user.isVip ? AppTheme.textMuted : AppTheme.silver,
              Icons.workspace_premium,
              () async {
                final newRole = user.isVip ? 'user' : 'vip';
                await db.updateUserRole(user.uid, newRole);
                _snack(context, user.isVip ? 'VIP removed' : '⭐ VIP granted!');
              },
            ),
          // Add Balance
          _actionBtn('Add Balance', AppTheme.neonGreen, Icons.add_circle_outline,
              () => _showBalanceDialog(context, user, true)),
          // Deduct Balance
          _actionBtn('Deduct', AppTheme.danger, Icons.remove_circle_outline,
              () => _showBalanceDialog(context, user, false)),
          // Ban toggle
          if (!user.isAdmin)
            _actionBtn(
              user.isBanned ? 'Unban' : 'Ban',
              user.isBanned ? AppTheme.neonGreen : AppTheme.danger,
              user.isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
              () async {
                await db.banUser(user.uid, !user.isBanned);
                _snack(context, user.isBanned ? '✅ User unbanned' : '🚫 User banned');
              },
            ),
          // Mute toggle
          _actionBtn(
            user.isMuted ? 'Unmute' : 'Mute',
            user.isMuted ? AppTheme.neonGreen : AppTheme.warning,
            user.isMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            () async {
              await db.muteUser(user.uid, !user.isMuted);
              _snack(context, user.isMuted ? '🔊 User unmuted' : '🔇 User muted');
            },
          ),
        ]),
      ]),
    );
  }

  void _showBalanceDialog(BuildContext context, UserModel user, bool isAdd) {
    final ctrl = TextEditingController();
    String type = 'wallet';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAdd ? 'Add Balance' : 'Deduct Balance',
          style: AppTheme.heading3.copyWith(
            color: isAdd ? AppTheme.neonGreen : AppTheme.danger)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(user.displayName, style: AppTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(children: ['wallet', 'winning'].map((t) => Expanded(
            child: GestureDetector(
              onTap: () => setS(() => type = t),
              child: Container(
                margin: EdgeInsets.only(right: t == 'wallet' ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: type == t
                      ? AppTheme.neonGreen.withOpacity(0.15) : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: type == t ? AppTheme.neonGreen : AppTheme.divider),
                ),
                child: Text(t.toUpperCase(), style: TextStyle(
                  color: type == t ? AppTheme.neonGreen : AppTheme.textMuted,
                  fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
          )).toList()),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Amount (Rs.)',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              prefixText: 'Rs. ',
              prefixStyle: TextStyle(color: isAdd ? AppTheme.neonGreen : AppTheme.danger),
              filled: true, fillColor: AppTheme.surfaceLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.divider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.divider)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isAdd ? AppTheme.neonGreen : AppTheme.danger)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdd ? AppTheme.neonGreen : AppTheme.danger),
            onPressed: () async {
              final amt = double.tryParse(ctrl.text) ?? 0;
              if (amt <= 0) return;
              final walletDelta  = type == 'wallet'  ? (isAdd ? amt : -amt) : 0.0;
              final winningDelta = type == 'winning' ? (isAdd ? amt : -amt) : 0.0;
              await db.adjustBalance(user.uid, walletDelta, winningDelta);
              if (context.mounted) {
                Navigator.pop(context);
                _snack(context,
                  '${isAdd ? "✅ Added" : "⬇️ Deducted"} Rs. ${amt.toInt()} ${isAdd ? "to" : "from"} ${user.displayName}');
              }
            },
            child: Text(isAdd ? 'ADD' : 'DEDUCT'),
          ),
        ],
      )),
    );
  }

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
    );

  Widget _infoItem(String label, String value, Color color) =>
    Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      const SizedBox(height: 2),
      Text(label, style: AppTheme.caption.copyWith(fontSize: 9)),
    ]);

  Widget _badge(String label, Color color) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: TextStyle(
      color: color, fontSize: 9, fontWeight: FontWeight.w800)),
  );

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: AppTheme.neonGreen));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// lib/screens/admin/pending_transactions_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
class PendingTransactionsScreen extends StatelessWidget {
  const PendingTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.read<AppProvider>().db;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('PENDING TRANSACTIONS', style: AppTheme.heading3),
        centerTitle: true,
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: db.pendingTransactionsStream(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
              color: AppTheme.neonGreen));
          }
          final txns = snap.data ?? [];
          if (txns.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 64, color: AppTheme.neonGreen),
                const SizedBox(height: 12),
                Text('No pending transactions 🎉', style: AppTheme.bodyMedium),
              ],
            ));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: txns.length,
            itemBuilder: (_, i) => _TransactionCard(tx: txns[i], db: db),
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatefulWidget {
  final TransactionModel tx;
  final FirestoreService db;
  const _TransactionCard({required this.tx, required this.db});
  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final isDeposit = tx.type == 'deposit';
    final color = isDeposit ? AppTheme.neonGreen : AppTheme.gold;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Icon(isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.type.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
              Text(tx.userName, style: AppTheme.bodySmall),
            ])),
            Text('Rs. ${tx.amount.toInt()}',
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
          ]),
        ),

        // Details
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _row('User Mobile', tx.mobileNumber ?? '-'),
            _row('Payment Method', tx.mobileWallet ?? '-'),
            if (tx.transactionId != null && tx.transactionId!.isNotEmpty)
              _row('Transaction ID', tx.transactionId!),

            // Screenshot
            if (tx.screenshotUrl != null) ...[
              const SizedBox(height: 10),
              Text('Payment Proof:', style: AppTheme.caption),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _viewImage(context, tx.screenshotUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    tx.screenshotUrl!,
                    height: 120, width: double.infinity, fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(height: 120, alignment: Alignment.center,
                            color: AppTheme.surfaceLight,
                            child: const CircularProgressIndicator(
                              color: AppTheme.neonGreen, strokeWidth: 2)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Approve / Reject
            if (_processing)
              const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen))
            else
              Row(children: [
                Expanded(child: _actionBtn('REJECT', AppTheme.danger,
                    Icons.close_rounded, () => _reject(context, tx))),
                const SizedBox(width: 10),
                Expanded(child: _actionBtn('APPROVE', AppTheme.neonGreen,
                    Icons.check_rounded, () => _approve(context, tx))),
              ]),
          ]),
        ),
      ]),
    );
  }

  Future<void> _approve(BuildContext ctx, TransactionModel tx) async {
    setState(() => _processing = true);
    try {
      if (tx.type == 'deposit') {
        await widget.db.approveDeposit(tx);
      } else {
        await widget.db.approveWithdrawal(tx.id);
      }
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('✅ ${tx.type} of Rs. ${tx.amount.toInt()} approved!'),
          backgroundColor: AppTheme.neonGreen));
      }
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<void> _reject(BuildContext ctx, TransactionModel tx) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject ${tx.type}?',
            style: AppTheme.heading3.copyWith(color: AppTheme.danger)),
        content: TextField(
          controller: noteCtrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
            hintStyle: TextStyle(color: AppTheme.textMuted),
            border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _processing = true);
      try {
        await widget.db.rejectDeposit(tx.id, noteCtrl.text.trim());
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text('Transaction rejected'), backgroundColor: AppTheme.danger));
        }
      } finally {
        setState(() => _processing = false);
      }
    }
  }

  void _viewImage(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context))),
      body: Center(child: InteractiveViewer(child: Image.network(url))),
    )));
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTheme.caption),
      Text(value, style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
      ),
    );
}
