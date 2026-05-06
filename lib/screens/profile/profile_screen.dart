// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(slivers: [
        // Sliver App Bar
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppTheme.surface,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: user.isVip
                      ? [const Color(0xFF1A1500), const Color(0xFF0A0A0F)]
                      : [const Color(0xFF0A1F0F), const Color(0xFF0A0A0F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 40),
                // Avatar
                Stack(alignment: Alignment.bottomRight, children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: user.isVip
                          ? AppTheme.goldGradient : AppTheme.neonGradient,
                      boxShadow: user.isVip ? AppTheme.goldGlow : AppTheme.neonGlow,
                    ),
                    child: Center(child: Text(
                      user.displayName[0].toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.background,
                        fontWeight: FontWeight.w900, fontSize: 32),
                    )),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface, shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.background, width: 2)),
                    child: Icon(
                      user.isAdmin ? Icons.military_tech_rounded
                          : user.isVip ? Icons.workspace_premium_rounded
                          : Icons.person_rounded,
                      color: user.isAdmin ? AppTheme.gold
                          : user.isVip ? AppTheme.silver : AppTheme.textSecondary,
                      size: 14,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(user.displayName, style: AppTheme.heading3),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.games_outlined, size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text('FF UID: ${user.freeFireUid}', style: AppTheme.caption),
                ]),
              ]),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
              onPressed: () => _logout(context, provider),
            ),
          ],
        ),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Stats Row
            FadeInUp(child: Row(children: [
              Expanded(child: _StatCard(
                label: 'TOTAL BALANCE',
                value: 'Rs. ${user.totalBalance.toInt()}',
                icon: Icons.account_balance_wallet_rounded,
                color: AppTheme.neonGreen,
              )),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(
                label: 'TOURNAMENTS',
                value: '${user.joinedTournaments.length}',
                icon: Icons.sports_esports_rounded,
                color: AppTheme.accent,
              )),
            ])),

            const SizedBox(height: 10),

            FadeInUp(delay: const Duration(milliseconds: 100),
              child: Row(children: [
                Expanded(child: _StatCard(
                  label: 'WALLET',
                  value: 'Rs. ${user.walletBalance.toInt()}',
                  icon: Icons.payments_outlined,
                  color: AppTheme.neonGreen,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(
                  label: 'WINNINGS',
                  value: 'Rs. ${user.winningBalance.toInt()}',
                  icon: Icons.emoji_events_rounded,
                  color: AppTheme.gold,
                )),
              ])),

            const SizedBox(height: 24),

            // Player Info
            FadeInUp(delay: const Duration(milliseconds: 150),
              child: _InfoCard(user: user)),

            const SizedBox(height: 24),

            // Menu items
            FadeInUp(delay: const Duration(milliseconds: 200),
              child: Column(children: [
                _MenuTile(
                  icon: Icons.history_rounded,
                  label: 'Tournament History',
                  sublabel: '${user.joinedTournaments.length} tournaments',
                  color: AppTheme.accent,
                  onTap: () => _showTournamentHistory(context, user, provider),
                ),
                _MenuTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  color: AppTheme.warning,
                  onTap: () {},
                ),
                _MenuTile(
                  icon: Icons.security_rounded,
                  label: 'Privacy & Security',
                  color: AppTheme.neonGreen,
                  onTap: () {},
                ),
                _MenuTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  color: AppTheme.silver,
                  onTap: () {},
                ),
                _MenuTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  color: AppTheme.danger,
                  onTap: () => _logout(context, provider),
                  isDestructive: true,
                ),
              ])),

            const SizedBox(height: 24),

            // App version
            Text('FF Pro Arena PK v1.0.0',
              style: AppTheme.caption.copyWith(letterSpacing: 1)),
            const SizedBox(height: 4),
            Text('Made with ❤️ for Pakistan',
              style: AppTheme.caption.copyWith(color: AppTheme.neonGreen)),
            const SizedBox(height: 32),
          ]),
        )),
      ]),
    );
  }

  void _logout(BuildContext context, AppProvider provider) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Logout', style: AppTheme.heading3),
      content: Text('Are you sure you want to logout?', style: AppTheme.bodyMedium),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          onPressed: () async {
            Navigator.pop(context);
            await provider.logout();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false);
            }
          },
          child: const Text('LOGOUT'),
        ),
      ],
    ));
  }

  void _showTournamentHistory(BuildContext context, UserModel user, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Icon(Icons.history_rounded, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              Text('Tournament History', style: AppTheme.heading3),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: user.joinedTournaments.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.sports_esports_outlined,
                      size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 8),
                  Text('No tournaments joined yet', style: AppTheme.bodySmall),
                ]))
              : ListView.builder(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: user.joinedTournaments.length,
                  itemBuilder: (_, i) => FutureBuilder<TournamentModel?>(
                    future: provider.db.getTournament(user.joinedTournaments[i]),
                    builder: (_, snap) {
                      final t = snap.data;
                      if (t == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider, width: 0.5),
                        ),
                        child: Row(children: [
                          Text(t.mapEmoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t.title, style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700)),
                            Text('${t.map}  •  ${t.mode}', style: AppTheme.caption),
                            Text(DateFormat('dd MMM yyyy').format(t.scheduledAt),
                              style: AppTheme.caption),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: t.isEnded ? AppTheme.textMuted.withOpacity(0.1)
                                  : AppTheme.neonGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(t.status.toUpperCase(),
                              style: TextStyle(
                                color: t.isEnded ? AppTheme.textMuted : AppTheme.neonGreen,
                                fontSize: 9, fontWeight: FontWeight.w800)),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
          ),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTheme.caption.copyWith(fontSize: 9)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(
          color: color, fontWeight: FontWeight.w800, fontSize: 13),
          overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );
}

class _InfoCard extends StatelessWidget {
  final UserModel user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: AppTheme.cardGradient,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.divider, width: 0.5),
    ),
    child: Column(children: [
      _row('Member Since',
        DateFormat('MMMM yyyy').format(user.createdAt), AppTheme.textSecondary),
      const Divider(height: 16, color: AppTheme.divider),
      _row('Free Fire UID', user.freeFireUid, AppTheme.neonGreen),
      const Divider(height: 16, color: AppTheme.divider),
      _row('Account Status',
        user.isBanned ? 'Banned' : 'Active',
        user.isBanned ? AppTheme.danger : AppTheme.neonGreen),
    ]),
  );

  Widget _row(String label, String value, Color valueColor) =>
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTheme.caption),
      Text(value, style: TextStyle(
        color: valueColor, fontWeight: FontWeight.w700, fontSize: 13)),
    ]);
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;
  const _MenuTile({
    required this.icon, required this.label, this.sublabel,
    required this.color, required this.onTap, this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDestructive ? AppTheme.danger.withOpacity(0.05) : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive ? AppTheme.danger.withOpacity(0.2) : AppTheme.divider,
          width: 0.5),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
            color: isDestructive ? AppTheme.danger : AppTheme.textPrimary,
            fontWeight: FontWeight.w600, fontSize: 14)),
          if (sublabel != null) ...[
            const SizedBox(height: 2),
            Text(sublabel!, style: AppTheme.caption),
          ],
        ])),
        Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
      ]),
    ),
  );
}
