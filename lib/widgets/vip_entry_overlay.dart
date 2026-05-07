import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class VipEntryOverlay extends StatefulWidget {
  final Widget child;
  const VipEntryOverlay({super.key, required this.child});
  @override
  State<VipEntryOverlay> createState() => _VipEntryOverlayState();
}

class _VipEntryOverlayState extends State<VipEntryOverlay>
    with TickerProviderStateMixin {
  StreamSubscription? _sub;
  Map<String, dynamic>? _data;
  String? _lastKey;
  late AnimationController _fc, _sc, _pc;
  late Animation<double> _fade, _scale, _pulse;

  @override
  void initState() {
    super.initState();
    _fc = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _sc = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _pc = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fade  = CurvedAnimation(parent: _fc, curves: Curves.easeIn);
    _scale = CurvedAnimation(parent: _sc, curves: Curves.elasticOut);
    _pulse = CurvedAnimation(parent: _pc, curves: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
  }

  void _listen() {
    _sub = context.read<AppProvider>().db.loginAnimationStream().listen((d) {
      if (d == null) return;
      final k = '${d['triggeredBy']}_${d['createdAt']}';
      if (k == _lastKey) return;
      _lastKey = k;
      if (d['triggeredBy'] == context.read<AppProvider>().currentUser?.uid) return;
      _show(d);
    });
  }

  void _show(Map<String, dynamic> d) async {
    if (!mounted) return;
    setState(() => _data = d);
    _fc.forward(from: 0);
    _sc.forward(from: 0);
    await Future.delayed(const Duration(seconds: 6));
    _dismiss();
  }

  void _dismiss() async {
    await _fc.reverse();
    if (mounted) setState(() => _data = null);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _fc.dispose(); _sc.dispose(); _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      if (_data != null)
        GestureDetector(
          onTap: _dismiss,
          child: FadeTransition(opacity: _fade, child: _buildAnim(_data!)),
        ),
    ]);
  }

  Widget _buildAnim(Map<String, dynamic> d) {
    final t = (d['templateId'] as int?) ?? 1;
    final name    = d['userName']  ?? 'Player';
    final uid     = d['userUid']   ?? '';
    final isAdmin = d['type']      == 'golden_commander';
    final color   = isAdmin ? AppTheme.gold : AppTheme.neonGreen;
    final emoji   = isAdmin ? '👑' : '⭐';
    final role    = isAdmin ? 'ADMIN MJ' : 'VIP';

    switch (t % 5) {
      case 1: return _tpl1(name, uid, isAdmin, color, emoji, role);
      case 2: return _tpl2(name, uid, isAdmin, color, emoji, role);
      case 3: return _tpl3(name, uid, isAdmin, color, emoji, role);
      case 4: return _tpl4(name, uid, isAdmin, color, emoji, role);
      default: return _tpl5(name, uid, isAdmin, color, emoji, role);
    }
  }

  Widget _base(Color color, Widget child) => Container(
    color: Colors.black.withOpacity(0.92),
    child: Center(child: ScaleTransition(scale: _scale, child: AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: MediaQuery.of(context).size.width * 0.88,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.black, color.withOpacity(0.12), Colors.black],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.4 + _pulse.value * 0.5), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3 + _pulse.value * 0.3), blurRadius: 40, spreadRadius: 5)],
        ),
        child: child,
      ),
    ))),
  );

  Widget _uidBadge(String uid, Color color) => uid.isEmpty ? const SizedBox() : Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text('UID: $uid', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
  );

  Widget _dismiss_hint() => const Text('tap to dismiss',
    style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 2));

  // Template 1: Golden Gate
  Widget _tpl1(String name, String uid, bool isAdmin, Color c, String emoji, String role) =>
    _base(c, Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 70)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: c)),
        child: Text('$role ONLINE', style: TextStyle(color: c, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 13)),
      ),
      const SizedBox(height: 16),
      Text(name, style: TextStyle(color: c, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2,
        shadows: [Shadow(color: c, blurRadius: 20)]), textAlign: TextAlign.center),
      _uidBadge(uid, c),
      const SizedBox(height: 14),
      Text(isAdmin ? 'Admin has entered! 🔥\nAll players be ready!' : '$name VIP is online! ⚡',
        style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.6), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Divider(color: c.withOpacity(0.3)),
      const SizedBox(height: 8),
      _dismiss_hint(),
    ]));

  // Template 2: Fire Storm
  Widget _tpl2(String name, String uid, bool isAdmin, Color c, String emoji, String role) =>
    Container(
      decoration: BoxDecoration(gradient: RadialGradient(colors: [c.withOpacity(0.2), Colors.black.withOpacity(0.95)], radius: 0.8)),
      child: Center(child: ScaleTransition(scale: _scale, child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🔥$emoji🔥', style: TextStyle(fontSize: 60, shadows: [Shadow(color: c, blurRadius: 30 + _pulse.value * 20)])),
          const SizedBox(height: 14),
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(20),
              border: Border(top: BorderSide(color: c, width: 3), bottom: BorderSide(color: AppTheme.neonBlue, width: 3),
                left: BorderSide(color: c.withOpacity(0.3)), right: BorderSide(color: c.withOpacity(0.3)))),
            child: Column(children: [
              Text('$role IS HERE', style: TextStyle(color: c, fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 11)),
              const SizedBox(height: 10),
              Text(name, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900,
                shadows: [Shadow(color: c, blurRadius: 15 + _pulse.value * 10)])),
              _uidBadge(uid, c),
            ]),
          ),
          const SizedBox(height: 10),
          _dismiss_hint(),
        ]),
      ))),
    );

  // Template 3: Neon Spotlight
  Widget _tpl3(String name, String uid, bool isAdmin, Color c, String emoji, String role) =>
    AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [c.withOpacity(0.1 + _pulse.value * 0.1), Colors.black87, Colors.black])),
      child: Center(child: ScaleTransition(scale: _scale, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 110, height: 110,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(0.12),
            border: Border.all(color: c.withOpacity(0.6 + _pulse.value * 0.4), width: 3),
            boxShadow: [BoxShadow(color: c.withOpacity(0.5 + _pulse.value * 0.3), blurRadius: 30, spreadRadius: 5)]),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 50)))),
        const SizedBox(height: 18),
        Text(name, style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 3,
          shadows: [Shadow(color: c, blurRadius: 20 + _pulse.value * 15)])),
        _uidBadge(uid, c),
        const SizedBox(height: 18),
        Container(
          width: MediaQuery.of(context).size.width * 0.65,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [c.withOpacity(0.8), AppTheme.neonBlue.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(30)),
          child: Text(role, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 4, fontSize: 13),
            textAlign: TextAlign.center)),
        const SizedBox(height: 18),
        Text(isAdmin ? 'Admin MJ is online!\nAll members stand by! 🫡' : 'VIP $name is in the arena!',
          style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.6), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        _dismiss_hint(),
      ]))),
    ));

  // Template 4: War Zone
  Widget _tpl4(String name, String uid, bool isAdmin, Color c, String emoji, String role) =>
    Container(color: Colors.black.withOpacity(0.92), child: Center(child: ScaleTransition(scale: _scale,
      child: AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.withOpacity(0.6), width: 1.5), color: const Color(0xFF0A0A0A),
          boxShadow: [BoxShadow(color: c.withOpacity(0.2 + _pulse.value * 0.2), blurRadius: 30)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [Container(width: 40, height: 3, color: c), const SizedBox(width: 8),
            Text('ALERT: $role ONLINE', style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 3)),
            const SizedBox(width: 8), Expanded(child: Container(height: 3, color: c))]),
          const SizedBox(height: 20),
          Row(children: [
            Container(width: 76, height: 76, decoration: BoxDecoration(shape: BoxShape.circle,
              border: Border.all(color: c, width: 2), color: c.withOpacity(0.1),
              boxShadow: [BoxShadow(color: c.withOpacity(0.4 + _pulse.value * 0.3), blurRadius: 20)]),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 34)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: TextStyle(color: c, fontSize: 24, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
              if (uid.isNotEmpty) Text('UID: $uid', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Text(role, style: TextStyle(color: AppTheme.neonBlue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ])),
          ]),
          const SizedBox(height: 16),
          Container(height: 1, color: c.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(isAdmin ? '🎯 MJ is in the house!\nAll squads report to duty!' : '🎯 $name VIP is online!',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          _dismiss_hint(),
        ]),
      )))));

  // Template 5: Royal Entry
  Widget _tpl5(String name, String uid, bool isAdmin, Color c, String emoji, String role) =>
    AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [c.withOpacity(0.12 + _pulse.value * 0.08), Colors.black, AppTheme.neonBlue.withOpacity(0.08)])),
      child: Center(child: ScaleTransition(scale: _scale, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (_) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.star, color: c, size: 18 + _pulse.value * 4)))),
        const SizedBox(height: 14),
        Text(emoji, style: const TextStyle(fontSize: 80)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Container(height: 2, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, c])))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('✦', style: TextStyle(color: c, fontSize: 20))),
          Expanded(child: Container(height: 2, decoration: BoxDecoration(gradient: LinearGradient(colors: [c, Colors.transparent])))),
        ]),
        const SizedBox(height: 14),
        Text(name, style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 4,
          shadows: [Shadow(color: c, blurRadius: 25 + _pulse.value * 15)])),
        _uidBadge(uid, c),
        const SizedBox(height: 18),
        Text(isAdmin ? '👑 The King MJ has arrived! 👑' : '⭐ Royal VIP Entry ⭐',
          style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(isAdmin ? 'Admin MJ is online!\nAll members at attention!' : '$name VIP is in the arena!',
          style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.6), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (_) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.star, color: c, size: 18 + _pulse.value * 4)))),
        const SizedBox(height: 12),
        _dismiss_hint(),
      ]))),
    ));
}
