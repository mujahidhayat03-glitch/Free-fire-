// lib/screens/home/tournament_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../splash_screen.dart';
import '../home/home_screen.dart'; // TournamentCard widgets

class TournamentDetailScreen extends StatelessWidget {
  final TournamentModel tournament;
  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user     = provider.currentUser;
    final t        = tournament;
    final hasJoined = user != null && t.joinedUsers.contains(user.uid);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppTheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: t.isLive
                      ? [const Color(0xFF0A2E1A), AppTheme.surface]
                      : [const Color(0xFF1A1A2A), AppTheme.surface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(t.mapEmoji, style: const TextStyle(fontSize: 50)),
                  const SizedBox(height: 8),
                  Text(t.title, style: AppTheme.heading2, textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _Chip(label: t.map,  color: AppTheme.accent),
                    const SizedBox(width: 8),
                    _Chip(label: t.mode, color: AppTheme.neonGreen),
                    const SizedBox(width: 8),
                    _StatusChip(status: t.status),
                  ]),
                ],
              )),
            ),
          ),
        ),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Info cards
            Row(children: [
              _InfoCard('ENTRY FEE', 'Rs. ${t.entryFee.toInt()}',
                  Icons.payments_outlined, AppTheme.neonGreen),
              const SizedBox(width: 12),
              _InfoCard('PRIZE POOL', 'Rs. ${t.prizePool.toInt()}',
                  Icons.emoji_events_outlined, AppTheme.gold),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _InfoCard('SLOTS', '${t.slotsRemaining} Left',
                  Icons.people_outline, AppTheme.accent),
              const SizedBox(width: 12),
              _InfoCard('SCHEDULE',
                  DateFormat('dd MMM\nhh:mm a').format(t.scheduledAt),
                  Icons.schedule, AppTheme.warning),
            ]),

            const SizedBox(height: 24),

            // Prize Distribution
            if (t.prizeDistribution.isNotEmpty) ...[
              _SectionHeader(icon: Icons.emoji_events, label: 'PRIZE DISTRIBUTION'),
              const SizedBox(height: 12),
              ...t.prizeDistribution.entries.map((e) => _PrizeRow(
                rank: e.key, amount: e.value.toString())),
              const SizedBox(height: 24),
            ],

            // Slots Progress
            _SectionHeader(icon: Icons.people, label: 'SLOT STATUS'),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: t.fillPercentage,
                backgroundColor: AppTheme.surfaceLight,
                valueColor: AlwaysStoppedAnimation(
                  t.fillPercentage > 0.9 ? AppTheme.danger : AppTheme.neonGreen),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${t.filledSlots} Joined', style: AppTheme.bodySmall),
              Text('${t.slotsRemaining} Remaining', style: AppTheme.bodySmall),
            ]),

            const SizedBox(height: 24),

            // Room ID section (only for joined users)
            if (hasJoined && t.roomVisible && t.roomId != null) ...[
              _SectionHeader(icon: Icons.meeting_room, label: 'ROOM DETAILS'),
              const SizedBox(height: 12),
              _RoomInfoCard(roomId: t.roomId!, roomPass: t.roomPassword ?? '---'),
              const SizedBox(height: 24),
            ],

            if (hasJoined && t.roomVisible && t.roomId == null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: AppTheme.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Room ID will be shared 15 minutes before the match.',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.warning),
                  )),
                ]),
              ),
              const SizedBox(height: 24),
            ],

            // Action button
            if (!t.isEnded)
              hasJoined
                  ? _JoinedBadge()
                  : NeonButton(
                      label: t.isFull ? 'TOURNAMENT FULL' : 'JOIN TOURNAMENT  •  Rs. ${t.entryFee.toInt()}',
                      icon: Icons.add_circle_outline,
                      onTap: t.isFull ? null : () => _confirmJoin(context, t),
                    ),

            const SizedBox(height: 32),
          ]),
        )),
      ]),
    );
  }

  void _confirmJoin(BuildContext context, TournamentModel t) {
    final provider = context.read<AppProvider>();
    final user = provider.currentUser;
    if (user == null) return;
    if (user.totalBalance < t.entryFee) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Insufficient balance! Please deposit funds.'),
        backgroundColor: AppTheme.danger,
      ));
      return;
    }
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Confirm Join', style: AppTheme.heading3),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Tournament: ${t.title}', style: AppTheme.bodyMedium),
        const SizedBox(height: 8),
        Text('Entry Fee: Rs. ${t.entryFee.toInt()}',
            style: TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Your Balance: Rs. ${user.totalBalance.toInt()}',
            style: AppTheme.bodySmall),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted))),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final ok = await provider.joinTournament(t);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? '✅ Successfully joined ${t.title}!'
                               : provider.error ?? 'Failed to join'),
                backgroundColor: ok ? AppTheme.neonGreen : AppTheme.danger,
              ));
              if (ok) Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
          child: const Text('CONFIRM'),
        ),
      ],
    ));
  }
}

class _InfoCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _InfoCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTheme.caption),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(
            color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        ])),
      ]),
    ),
  );
}

class _PrizeRow extends StatelessWidget {
  final String rank, amount;
  const _PrizeRow({required this.rank, required this.amount});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      Text(rank, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      const Spacer(),
      Text('Rs. $amount', style: TextStyle(
        color: AppTheme.gold, fontWeight: FontWeight.w800, fontSize: 14)),
      const SizedBox(width: 6),
      const Icon(Icons.emoji_events, color: AppTheme.gold, size: 16),
    ]),
  );
}

class _RoomInfoCard extends StatelessWidget {
  final String roomId, roomPass;
  const _RoomInfoCard({required this.roomId, required this.roomPass});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0A2E1A), Color(0xFF061A0F)]),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.neonGreen.withOpacity(0.4)),
      boxShadow: AppTheme.neonGlow,
    ),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.meeting_room_outlined, color: AppTheme.neonGreen, size: 16),
        const SizedBox(width: 6),
        Text('ROOM CREDENTIALS', style: AppTheme.neonLabel),
      ]),
      const SizedBox(height: 16),
      _credRow('Room ID', roomId),
      const SizedBox(height: 10),
      _credRow('Password', roomPass),
    ]),
  );

  Widget _credRow(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTheme.caption),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(
          color: AppTheme.neonGreen, fontWeight: FontWeight.w800,
          fontSize: 18, letterSpacing: 2)),
      ])),
      GestureDetector(
        onTap: () => Clipboard.setData(ClipboardData(text: value)),
        child: const Icon(Icons.copy_rounded, color: AppTheme.neonGreen, size: 20),
      ),
    ]),
  );
}

class _JoinedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 52, alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppTheme.neonGreen.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.neonGreen.withOpacity(0.4)),
    ),
    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.check_circle_rounded, color: AppTheme.neonGreen, size: 20),
      SizedBox(width: 8),
      Text('ALREADY JOINED', style: TextStyle(
        color: AppTheme.neonGreen, fontWeight: FontWeight.w800, letterSpacing: 1)),
    ]),
  );
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppTheme.neonGreen, size: 16),
    const SizedBox(width: 8),
    Text(label, style: AppTheme.neonLabel),
    const SizedBox(width: 12),
    const Expanded(child: Divider(color: AppTheme.divider)),
  ]);
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(
      color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});
  @override
  Widget build(BuildContext context) {
    final c = status == 'live' ? AppTheme.neonGreen
            : status == 'ended' ? AppTheme.textMuted : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(
        color: c, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
    );
  }
}
