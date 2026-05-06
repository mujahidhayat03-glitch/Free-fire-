// lib/screens/admin/admin_panel_screen.dart — FF PRO ARENA PK — Hidden Admin Panel
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/models.dart';
import 'create_tournament_screen.dart';
import 'manage_users_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});
  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(children: [
        // Admin background - fire themed
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A0500), Color(0xFF050A0E)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        ),

        // Diagonal accent
        CustomPaint(painter: _AdminBg(), size: Size.infinite),

        SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.gold, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.admin_panel_settings_rounded,
                        color: AppTheme.gold, size: 16),
                    const SizedBox(width: 6),
                    Text('ADMIN PANEL',
                        style: AppTheme.heading3.copyWith(color: AppTheme.gold)),
                  ]),
                  Text('FF Pro Arena PK · Control Center',
                      style: AppTheme.caption.copyWith(
                          color: AppTheme.goldDark, letterSpacing: 0.5)),
                ]),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    const Icon(Icons.shield_rounded,
                        color: AppTheme.background, size: 12),
                    const SizedBox(width: 4),
                    Text('ADMIN', style: AppTheme.caption.copyWith(
                        color: AppTheme.background, fontWeight: FontWeight.w900)),
                  ]),
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // Stats row
            FadeInDown(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<List<TournamentModel>>(
                stream: provider.db.tournamentsStream(),
                builder: (_, tSnap) {
                  return StreamBuilder<List<UserModel>>(
                    stream: provider.db.usersStream(),
                    builder: (_, uSnap) {
                      final tours = tSnap.data ?? [];
                      final users = uSnap.data ?? [];
                      final live  = tours.where(
                          (t) => t.status == AppConstants.tournamentLive).length;
                      return Row(children: [
                        _StatCard(label: 'Users', value: '${users.length}',
                            icon: Icons.people_rounded, color: AppTheme.neonGreen),
                        const SizedBox(width: 10),
                        _StatCard(label: 'Tournaments', value: '${tours.length}',
                            icon: Icons.emoji_events_rounded, color: AppTheme.gold),
                        const SizedBox(width: 10),
                        _StatCard(label: 'Live', value: '$live',
                            icon: Icons.live_tv_rounded, color: AppTheme.danger),
                      ]);
                    },
                  );
                },
              ),
            )),

            const SizedBox(height: 20),

            // Action cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FadeInLeft(delay: const Duration(milliseconds: 100),
                    child: _ActionCard(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Create Tournament',
                      subtitle: 'Schedule a new FF match',
                      color: AppTheme.neonGreen,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CreateTournamentScreen())),
                    )),
                  FadeInLeft(delay: const Duration(milliseconds: 150),
                    child: _ActionCard(
                      icon: Icons.manage_accounts_rounded,
                      title: 'Manage Users',
                      subtitle: 'Ban, mute, set VIP, wallet',
                      color: AppTheme.accentPurple,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
                    )),
                  FadeInLeft(delay: const Duration(milliseconds: 200),
                    child: _ActionCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Wallet Requests',
                      subtitle: 'Approve/reject deposits & withdrawals',
                      color: AppTheme.gold,
                      onTap: () => _showWalletRequests(context, provider),
                    )),
                  FadeInLeft(delay: const Duration(milliseconds: 250),
                    child: _ActionCard(
                      icon: Icons.notifications_rounded,
                      title: 'Send Announcement',
                      subtitle: 'Broadcast message to all users',
                      color: AppTheme.warning,
                      onTap: () => _showAnnouncementDialog(context, provider),
                    )),
                  FadeInLeft(delay: const Duration(milliseconds: 300),
                    child: _ActionCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Revenue & Stats',
                      subtitle: 'View prize pool & earnings',
                      color: AppTheme.neonBlue,
                      onTap: () => _showStats(context, provider),
                    )),

                  const SizedBox(height: 16),

                  // Recent transactions
                  Text('PENDING REQUESTS',
                      style: AppTheme.neonLabel.copyWith(
                          color: AppTheme.gold, fontSize: 11)),
                  const SizedBox(height: 10),
                  _PendingTransactions(provider: provider),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _showWalletRequests(BuildContext ctx, AppProvider p) {
    Navigator.push(ctx, MaterialPageRoute(
        builder: (_) => _WalletRequestsScreen(provider: p)));
  }

  void _showAnnouncementDialog(BuildContext ctx, AppProvider p) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.gold, width: 0.5),
        ),
        title: Text('Send Announcement', style: AppTheme.heading3),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: AppTheme.bodyMedium,
          decoration: const InputDecoration(hintText: 'Enter announcement…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await p.db.sendAnnouncement(ctrl.text.trim());
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('SEND'),
          ),
        ],
      ),
    );
  }

  void _showStats(BuildContext ctx, AppProvider p) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('REVENUE & STATS', style: AppTheme.heading3.copyWith(color: AppTheme.neonBlue)),
          const SizedBox(height: 20),
          StreamBuilder<List<TournamentModel>>(
            stream: p.db.tournamentsStream(),
            builder: (_, snap) {
              final tours = snap.data ?? [];
              final revenue = tours.fold(0.0, (s, t) => s + t.entryFee * t.currentPlayers);
              final prizes  = tours.fold(0.0, (s, t) => s + t.prizePool);
              return Column(children: [
                _StatRow('Total Revenue', 'PKR ${revenue.toStringAsFixed(0)}', AppTheme.neonGreen),
                _StatRow('Total Prizes', 'PKR ${prizes.toStringAsFixed(0)}', AppTheme.gold),
                _StatRow('Net', 'PKR ${(revenue - prizes).toStringAsFixed(0)}', AppTheme.neonBlue),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String l, v; final Color c;
  const _StatRow(this.l, this.v, this.c);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Text(l, style: AppTheme.bodySmall),
      const Spacer(),
      Text(v, style: AppTheme.heading3.copyWith(color: c)),
    ]),
  );
}

// ── STAT CARD ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: AppTheme.heading2.copyWith(color: color)),
        Text(label, style: AppTheme.caption),
      ]),
    ),
  );
}

// ── ACTION CARD ───────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title,
      required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600)),
          Text(subtitle, style: AppTheme.bodySmall),
        ])),
        Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 22),
      ]),
    ),
  );
}

// ── PENDING TRANSACTIONS ──────────────────────────────────────────────────────
class _PendingTransactions extends StatelessWidget {
  final AppProvider provider;
  const _PendingTransactions({required this.provider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TransactionModel>>(
      stream: provider.db.pendingTransactionsStream(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
              color: AppTheme.gold, strokeWidth: 2));
        }
        final txns = snap.data ?? [];
        if (txns.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.divider, width: 0.5),
            ),
            child: Center(child: Text('No pending requests',
                style: AppTheme.bodySmall)),
          );
        }
        return Column(
          children: txns.map((t) => _TxnTile(txn: t, provider: provider)).toList(),
        );
      },
    );
  }
}

class _TxnTile extends StatelessWidget {
  final TransactionModel txn;
  final AppProvider provider;
  const _TxnTile({required this.txn, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDeposit = txn.type == AppConstants.walletDeposit;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: (isDeposit ? AppTheme.neonGreen : AppTheme.danger).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isDeposit ? AppTheme.neonGreen : AppTheme.danger, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(txn.description, style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('PKR ${txn.amount.toStringAsFixed(0)}',
              style: AppTheme.neonLabel.copyWith(
                  color: isDeposit ? AppTheme.neonGreen : AppTheme.danger)),
        ])),
        Row(children: [
          GestureDetector(
            onTap: () => provider.db.approveTransaction(txn.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.neonGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.neonGreen.withOpacity(0.4)),
              ),
              child: Text('OK', style: AppTheme.caption.copyWith(
                  color: AppTheme.neonGreen, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => provider.db.rejectTransaction(txn.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
              ),
              child: Text('X', style: AppTheme.caption.copyWith(
                  color: AppTheme.danger, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _AdminBg extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppTheme.gold.withOpacity(0.02)
      ..strokeWidth = 1;
    for (var i = -10; i < 20; i++) {
      final x = i * size.width / 10;
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ── WALLET REQUESTS SCREEN ────────────────────────────────────────────────────
class _WalletRequestsScreen extends StatelessWidget {
  final AppProvider provider;
  const _WalletRequestsScreen({required this.provider});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      title: Text('Wallet Requests', style: AppTheme.heading3),
    ),
    body: StreamBuilder<List<TransactionModel>>(
      stream: provider.db.pendingTransactionsStream(),
      builder: (_, snap) {
        final txns = snap.data ?? [];
        if (txns.isEmpty) return Center(child: Text('No pending requests',
            style: AppTheme.bodySmall));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: txns.length,
          itemBuilder: (_, i) => _TxnTile(txn: txns[i], provider: provider),
        );
      },
    ),
  );
}
