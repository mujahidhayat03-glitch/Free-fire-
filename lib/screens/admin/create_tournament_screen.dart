// lib/screens/admin/create_tournament_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../splash_screen.dart';

class CreateTournamentScreen extends StatefulWidget {
  final TournamentModel? existing; // non-null = edit mode
  const CreateTournamentScreen({super.key, this.existing});
  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _entryCtrl;
  late final TextEditingController _prizeCtrl;
  late final TextEditingController _slotsCtrl;
  late final TextEditingController _prize1Ctrl;
  late final TextEditingController _prize2Ctrl;
  late final TextEditingController _prize3Ctrl;

  String   _selectedMap  = AppConstants.ffMaps.first;
  String   _selectedMode = AppConstants.gameModes.last;
  DateTime _scheduledAt  = DateTime.now().add(const Duration(hours: 2));
  bool     _isLoading    = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _entryCtrl = TextEditingController(text: e?.entryFee.toInt().toString() ?? '');
    _prizeCtrl = TextEditingController(text: e?.prizePool.toInt().toString() ?? '');
    _slotsCtrl = TextEditingController(text: e?.totalSlots.toString() ?? '100');
    _prize1Ctrl = TextEditingController(
        text: e?.prizeDistribution['1st']?.toString() ?? '');
    _prize2Ctrl = TextEditingController(
        text: e?.prizeDistribution['2nd']?.toString() ?? '');
    _prize3Ctrl = TextEditingController(
        text: e?.prizeDistribution['3rd']?.toString() ?? '');
    if (e != null) {
      _selectedMap  = e.map;
      _selectedMode = e.mode;
      _scheduledAt  = e.scheduledAt;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _entryCtrl.dispose(); _prizeCtrl.dispose();
    _slotsCtrl.dispose(); _prize1Ctrl.dispose();
    _prize2Ctrl.dispose(); _prize3Ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (_, child) => Theme(
        data: AppTheme.theme.copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.neonGreen)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      builder: (_, child) => Theme(
        data: AppTheme.theme.copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.neonGreen)),
        child: child!,
      ),
    );
    if (time != null) {
      setState(() => _scheduledAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final provider = context.read<AppProvider>();
      final prizeDistribution = <String, dynamic>{};
      if (_prize1Ctrl.text.isNotEmpty) prizeDistribution['1st'] = int.parse(_prize1Ctrl.text);
      if (_prize2Ctrl.text.isNotEmpty) prizeDistribution['2nd'] = int.parse(_prize2Ctrl.text);
      if (_prize3Ctrl.text.isNotEmpty) prizeDistribution['3rd'] = int.parse(_prize3Ctrl.text);

      final tournament = TournamentModel(
        id: widget.existing?.id ?? '',
        title: _titleCtrl.text.trim(),
        map: _selectedMap,
        mode: _selectedMode,
        entryFee: double.parse(_entryCtrl.text.trim()),
        prizePool: double.parse(_prizeCtrl.text.trim()),
        totalSlots: int.parse(_slotsCtrl.text.trim()),
        filledSlots: widget.existing?.filledSlots ?? 0,
        status: widget.existing?.status ?? 'upcoming',
        scheduledAt: _scheduledAt,
        prizeDistribution: prizeDistribution,
        createdBy: provider.currentUser!.uid,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );

      if (widget.existing != null) {
        await provider.db.updateTournament(
            tournament.id, tournament.toMap());
      } else {
        await provider.db.createTournament(tournament);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.existing != null
              ? '✅ Tournament updated!' : '✅ Tournament created!'),
          backgroundColor: AppTheme.neonGreen,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppTheme.danger));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdit ? 'EDIT TOURNAMENT' : 'CREATE TOURNAMENT',
            style: AppTheme.heading3),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Basic Info ──────────────────────────────────────────────────
            _Section('BASIC INFO'),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Tournament Title', controller: _titleCtrl,
              prefixIcon: Icons.sports_esports_rounded,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Map selector
            _label('SELECT MAP'),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: AppConstants.ffMaps.length,
                itemBuilder: (_, i) {
                  final map = AppConstants.ffMaps[i];
                  final selected = _selectedMap == map;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMap = map),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 90,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        gradient: selected ? AppTheme.neonGradient : null,
                        color: selected ? null : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? Colors.transparent : AppTheme.divider),
                        boxShadow: selected ? AppTheme.neonGlow : null,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_mapEmoji(map), style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(map, style: TextStyle(
                          color: selected ? AppTheme.background : AppTheme.textSecondary,
                          fontWeight: FontWeight.w700, fontSize: 11)),
                      ]),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            // Mode selector
            _label('GAME MODE'),
            const SizedBox(height: 8),
            Row(children: AppConstants.gameModes.map((mode) {
              final selected = _selectedMode == mode;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _selectedMode = mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    right: mode != AppConstants.gameModes.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.neonGreen.withOpacity(0.15) : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppTheme.neonGreen : AppTheme.divider,
                      width: selected ? 1.5 : 0.5),
                  ),
                  child: Text(mode, style: TextStyle(
                    color: selected ? AppTheme.neonGreen : AppTheme.textSecondary,
                    fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ));
            }).toList()),

            const SizedBox(height: 20),
            // ── Financials ──────────────────────────────────────────────────
            _Section('FINANCIALS'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: CustomTextField(
                label: 'Entry Fee (Rs.)', controller: _entryCtrl,
                keyboard: TextInputType.number,
                prefixIcon: Icons.payments_outlined,
                validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
              )),
              const SizedBox(width: 12),
              Expanded(child: CustomTextField(
                label: 'Prize Pool (Rs.)', controller: _prizeCtrl,
                keyboard: TextInputType.number,
                prefixIcon: Icons.emoji_events_outlined,
                validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
              )),
            ]),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Total Slots', controller: _slotsCtrl,
              keyboard: TextInputType.number,
              prefixIcon: Icons.people_outline,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),

            const SizedBox(height: 20),
            // ── Prize Distribution ──────────────────────────────────────────
            _Section('PRIZE DISTRIBUTION (Optional)'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: CustomTextField(
                label: '1st Place (Rs.)', controller: _prize1Ctrl,
                keyboard: TextInputType.number, prefixIcon: Icons.looks_one_outlined)),
              const SizedBox(width: 8),
              Expanded(child: CustomTextField(
                label: '2nd Place', controller: _prize2Ctrl,
                keyboard: TextInputType.number, prefixIcon: Icons.looks_two_outlined)),
              const SizedBox(width: 8),
              Expanded(child: CustomTextField(
                label: '3rd Place', controller: _prize3Ctrl,
                keyboard: TextInputType.number, prefixIcon: Icons.looks_3_outlined)),
            ]),

            const SizedBox(height: 20),
            // ── Schedule ────────────────────────────────────────────────────
            _Section('SCHEDULE'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppTheme.neonGreen, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Match Date & Time', style: AppTheme.caption),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE, dd MMM yyyy  •  hh:mm a').format(_scheduledAt),
                      style: const TextStyle(
                        color: AppTheme.neonGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                  ])),
                  const Icon(Icons.edit_calendar_rounded,
                      color: AppTheme.textMuted, size: 18),
                ]),
              ),
            ),

            const SizedBox(height: 32),
            NeonButton(
              label: isEdit ? 'UPDATE TOURNAMENT' : 'CREATE TOURNAMENT',
              icon: isEdit ? Icons.edit_rounded : Icons.add_circle_rounded,
              isLoading: _isLoading,
              onTap: _submit,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _mapEmoji(String map) {
    switch (map) {
      case 'Bermuda':   return '🏝️';
      case 'Purgatory': return '🏔️';
      case 'Kalahari':  return '🏜️';
      case 'Alpine':    return '❄️';
      case 'Neextarra': return '🌌';
      default: return '🗺️';
    }
  }

  Widget _Section(String label) => Row(children: [
    Text(label, style: AppTheme.neonLabel),
    const SizedBox(width: 10),
    const Expanded(child: Divider(color: AppTheme.divider)),
  ]);

  Widget _label(String text) => Text(text, style: AppTheme.caption.copyWith(
    color: AppTheme.textSecondary, letterSpacing: 1));
}
