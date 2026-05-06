// lib/screens/home/home_screen.dart — FF PRO ARENA PK — Redesigned
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart' show NeonButton;
import 'tournament_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _tabs = ['All', 'Upcoming', 'Live', 'Ended'];
  int _sel = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(() => setState(() => _sel = _tab.index));
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  List<TournamentModel> _filtered(List<TournamentModel> all) {
    if (_sel == 0) return all;
    final status = [
      '',
      AppConstants.tournamentUpcoming,
      AppConstants.tournamentLive,
      AppConstants.tournamentEnded,
    ][_sel];
    return all.where((t) => t.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            floating: false,
            backgroundColor: AppTheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF021A0A), Color(0xFF050A0E)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('WELCOME BACK', style: AppTheme.caption.copyWith(
                          color: AppTheme.neonGreen, letterSpacing: 2)),
                      Text(user?.displayName ?? 'Player',
                          style: AppTheme.heading2.copyWith(color: AppTheme.textPrimary),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      _RoleBadge(role: user?.role ?? 'user'),
                    ],
                  )),
                  // Wallet chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                      boxShadow: [BoxShadow(
                          color: AppTheme.gold.withOpacity(0.15),
                          blurRadius: 12)],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: AppTheme.gold, size: 18),
                      const SizedBox(height: 2),
                      Text('PKR ${user?.walletBalance.toStringAsFixed(0) ?? '0'}',
                          style: AppTheme.goldLabel.copyWith(fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: Container(
                color: AppTheme.surface,
                child: TabBar(
                  controller: _tab,
                  isScrollable: true,
                  labelColor: AppTheme.neonGreen,
                  unselectedLabelColor: AppTheme.textMuted,
                  labelStyle: AppTheme.neonLabel.copyWith(fontSize: 12),
                  unselectedLabelStyle: AppTheme.caption,
                  indicator: UnderlineTabIndicator(
                    borderSide: const BorderSide(color: AppTheme.neonGreen, width: 2.5),
                    insets: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ),
          ),
        ],
        body: StreamBuilder<List<TournamentModel>>(
          stream: provider.db.tournamentsStream(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(
                  color: AppTheme.neonGreen));
            }
            final all = snap.data ?? [];
            final list = _filtered(all);

            if (list.isEmpty) {
              return Center(child: Column(
                mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.sports_esports_rounded,
                      size: 60, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text('No tournaments yet',
                      style: AppTheme.heading3.copyWith(color: AppTheme.textMuted)),
                  Text('Check back soon!',
                      style: AppTheme.bodySmall),
                ],
              ));
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: list.length,
              itemBuilder: (_, i) => FadeInUp(
                delay: Duration(milliseconds: i * 60),
                child: _TournamentCard(
                  tournament: list[i],
                  user: user,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TournamentDetailScreen(tournament: list[i]))),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── ROLE BADGE ────────────────────────────────────────────────────────────────
class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == AppConstants.roleAdmin;
    final isVip   = role == AppConstants.roleVip;
    if (!isAdmin && !isVip) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: isAdmin ? AppTheme.goldGradient : AppTheme.neonGradient,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isAdmin ? Icons.shield_rounded : Icons.star_rounded,
            size: 11, color: AppTheme.background),
        const SizedBox(width: 4),
        Text(isAdmin ? 'ADMIN' : 'VIP',
            style: AppTheme.caption.copyWith(
                color: AppTheme.background, fontWeight: FontWeight.w800,
                letterSpacing: 1)),
      ]),
    );
  }
}

// ── TOURNAMENT CARD ───────────────────────────────────────────────────────────
class _TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final UserModel? user;
  final VoidCallback onTap;

  const _TournamentCard({
    required this.tournament, required this.user, required this.onTap});

  Color get _statusColor {
    switch (tournament.status) {
      case AppConstants.tournamentLive: return AppTheme.danger;
      case AppConstants.tournamentUpcoming: return AppTheme.neonGreen;
      default: return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLive = tournament.status == AppConstants.tournamentLive;
    final fmt = DateFormat('dd MMM · hh:mm a');
    final spotsLeft = tournament.maxPlayers - tournament.currentPlayers;
    final isFull = spotsLeft <= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive
                ? AppTheme.danger.withOpacity(0.4)
                : AppTheme.divider,
            width: isLive ? 1.5 : 0.5,
          ),
          boxShadow: isLive ? [
            BoxShadow(color: AppTheme.danger.withOpacity(0.15),
                blurRadius: 20, spreadRadius: 1),
          ] : AppTheme.cardShadow,
        ),
        child: Column(children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLive
                    ? [AppTheme.danger.withOpacity(0.15), Colors.transparent]
                    : [AppTheme.neonGreen.withOpacity(0.05), Colors.transparent],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              // Status dot
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _statusColor,
                  boxShadow: isLive ? [BoxShadow(
                      color: AppTheme.danger.withOpacity(0.6),
                      blurRadius: 8)] : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(tournament.status.toUpperCase(),
                  style: AppTheme.caption.copyWith(
                      color: _statusColor, letterSpacing: 1.5)),
              const Spacer(),
              // Prize chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('PKR ${tournament.prizePool.toStringAsFixed(0)}',
                    style: AppTheme.caption.copyWith(
                        color: AppTheme.background, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tournament.title,
                  style: AppTheme.heading3.copyWith(color: AppTheme.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),

              // Info row
              Row(children: [
                _InfoChip(Icons.map_outlined, tournament.map),
                const SizedBox(width: 8),
                _InfoChip(Icons.people_outline_rounded,
                    '${tournament.gameMode}'),
                const SizedBox(width: 8),
                _InfoChip(Icons.access_time_rounded,
                    fmt.format(tournament.scheduledAt)),
              ]),

              const SizedBox(height: 10),

              // Spots + entry
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ENTRY FEE',
                      style: AppTheme.caption.copyWith(letterSpacing: 1)),
                  Text('PKR ${tournament.entryFee.toStringAsFixed(0)}',
                      style: AppTheme.neonLabel),
                ])),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SPOTS LEFT',
                      style: AppTheme.caption.copyWith(letterSpacing: 1)),
                  Text(isFull ? 'FULL' : '$spotsLeft / ${tournament.maxPlayers}',
                      style: AppTheme.neonLabel.copyWith(
                          color: isFull ? AppTheme.danger : AppTheme.neonGreen)),
                ])),
                Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted, size: 22),
              ]),

              // Progress bar
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: tournament.currentPlayers / tournament.maxPlayers,
                  minHeight: 4,
                  backgroundColor: AppTheme.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFull ? AppTheme.danger : AppTheme.neonGreen,
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: AppTheme.textMuted),
    const SizedBox(width: 4),
    Text(label, style: AppTheme.caption.copyWith(color: AppTheme.textSecondary)),
  ]);
}
