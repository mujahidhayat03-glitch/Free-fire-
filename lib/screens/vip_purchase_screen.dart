import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';

class VipPurchaseScreen extends StatefulWidget {
  const VipPurchaseScreen({super.key});
  @override
  State<VipPurchaseScreen> createState() => _VipPurchaseScreenState();
}

class _VipPurchaseScreenState extends State<VipPurchaseScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _gc;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _gc = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _gc, curves: Curves.easeInOut);
  }

  @override
  void dispose() { _gc.dispose(); super.dispose(); }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: c));

  Future<void> _buy() async {
    final user = context.read<AppProvider>().currentUser;
    if (user == null) return;
    if (user.isVip) { _snack('Aap already VIP hain!', AppTheme.neonGreen); return; }
    final bal = user.walletBalance + user.winningBalance;
    if (bal < 200) { _snack('Balance kam hai. Pehle Rs.200 deposit karo.', Colors.red); return; }

    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('VIP Purchase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Rs.200 wallet se kategi.\nBalance: Rs.${bal.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white70, height: 1.6)),
        const SizedBox(height: 12),
        const Text('Benefits:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('⭐ Entry animation (5 templates)\n🎬 Name + UID sabko dikhega\n👑 VIP badge on profile\n🔥 Priority tournament access',
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.7)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
            child: const Text('Buy VIP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
      ],
    ));

    if (ok != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await context.read<AppProvider>().db.purchaseVip(user.uid, user.displayName);
      if (mounted) { _snack('Mubarak! Aap VIP ban gaye!', AppTheme.gold); Navigator.pop(context); }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    final bal  = (user?.walletBalance ?? 0) + (user?.winningBalance ?? 0);
    final vip  = user?.isVip ?? false;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(backgroundColor: AppTheme.surface,
          title: const Text('VIP Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        AnimatedBuilder(animation: _glow, builder: (_, __) => Container(
          width: double.infinity, padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFF1A1200), AppTheme.gold.withOpacity(0.15), const Color(0xFF1A1200)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.gold.withOpacity(0.4 + _glow.value * 0.4), width: 2),
            boxShadow: [BoxShadow(color: AppTheme.gold.withOpacity(0.2 + _glow.value * 0.2), blurRadius: 30, spreadRadius: 3)],
          ),
          child: Column(children: [
            const Text('⭐', style: TextStyle(fontSize: 70)),
            const SizedBox(height: 10),
            const Text('VIP ACCOUNT', style: TextStyle(color: AppTheme.gold, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 4)),
            const SizedBox(height: 8),
            const Text('Sirf ek baar pay karo — hamesha ke liye VIP!',
                style: TextStyle(color: Colors.white60, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 18),
            Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.gold)),
              child: const Text('Rs. 200 Only', style: TextStyle(color: AppTheme.gold, fontSize: 28, fontWeight: FontWeight.w900))),
          ]),
        )),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.star, color: AppTheme.gold, size: 18), const SizedBox(width: 8),
              const Text('VIP Benefits', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))]),
            const SizedBox(height: 14),
            const Text('🎬  Login par saare users ko animation dikhegi\n📛  Aapka Name + FF UID show hoga\n👑  5 random animation templates\n⭐  VIP badge profile + chat mein\n🔥  Priority tournament access',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 2.0)),
          ])),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Aapka Balance:', style: TextStyle(color: Colors.white70)),
            Text('Rs. ${bal.toStringAsFixed(0)}',
                style: TextStyle(color: bal >= 200 ? AppTheme.neonGreen : Colors.red,
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ])),
        const SizedBox(height: 22),
        SizedBox(width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: _loading || vip ? null : _buy,
            style: ElevatedButton.styleFrom(backgroundColor: vip ? Colors.grey : AppTheme.gold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.black)
                : Text(vip ? '✅ Already VIP' : '⭐  BUY VIP — Rs.200',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
          )),
        const SizedBox(height: 10),
        const Text('* Pehle wallet mein deposit karo phir VIP lena',
            style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
      ])),
    );
  }
}
