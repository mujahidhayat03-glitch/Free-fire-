// lib/screens/splash_screen.dart — FF PRO ARENA PK
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import 'auth/login_screen.dart';
import 'main_shell.dart';

// Re-export widgets for other screens
export 'auth/login_screen.dart' show NeonButton, FFTextField, CustomTextField, FFProLogo, ParticleBg;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _rot;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _rotCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _rot = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotCtrl);

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeCtrl.forward();
    });

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    await provider.init();
    if (!mounted) return;
    Navigator.pushReplacement(context, _FadeRoute(
      builder: (_) =>
          provider.currentUser != null ? const MainShell() : const LoginScreen(),
    ));
  }

  @override
  void dispose() {
    _rotCtrl.dispose(); _fadeCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF020608), Color(0xFF050A0E), Color(0xFF001A08)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        ),

        // Particle field
        const ParticleBg(),

        // Rotating ring
        Center(
          child: AnimatedBuilder(
            animation: _rot,
            builder: (_, __) => Transform.rotate(
              angle: _rot.value,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.neonGreen.withOpacity(0.15), width: 1),
                ),
                child: CustomPaint(painter: _RingPainter()),
              ),
            ),
          ),
        ),

        // Logo + text
        Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const FFProLogo(size: 110),
              const SizedBox(height: 28),
              ShaderMask(
                shaderCallback: (b) => AppTheme.neonGradient.createShader(b),
                child: Text('FF PRO ARENA',
                    style: AppTheme.heading1.copyWith(color: Colors.white)),
              ),
              Text('PAKISTAN',
                  style: AppTheme.heading3.copyWith(
                      color: AppTheme.textSecondary, letterSpacing: 8)),
              const SizedBox(height: 10),
              Text('FREE FIRE TOURNAMENT PLATFORM',
                  style: AppTheme.caption.copyWith(
                      color: AppTheme.neonGreen.withOpacity(0.7),
                      letterSpacing: 2)),
            ]),
          ),
        ),

        // Bottom loading bar
        Positioned(
          bottom: 50,
          left: 60, right: 60,
          child: FadeTransition(
            opacity: _fade,
            child: Column(children: [
              Text('v${AppConstants.appVersion}',
                  style: AppTheme.caption.copyWith(color: AppTheme.textMuted)),
              const SizedBox(height: 10),
              _AnimatedBar(),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = AppTheme.neonGreen.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawArc(Rect.fromLTWH(0, 0, s.width, s.height),
        0, math.pi * 0.8, false, p);
    c.drawArc(Rect.fromLTWH(0, 0, s.width, s.height),
        math.pi, math.pi * 0.6, false, p);
  }
  @override bool shouldRepaint(_) => false;
}

class _AnimatedBar extends StatefulWidget {
  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _w;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..forward();
    _w = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _w,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _w.value,
          minHeight: 3,
          backgroundColor: AppTheme.divider,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonGreen),
        ),
      ),
    );
  }
}

class _FadeRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  _FadeRoute({required this.builder})
      : super(
          pageBuilder: (c, a, b) => builder(c),
          transitionsBuilder: (c, a, b, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        );
}
