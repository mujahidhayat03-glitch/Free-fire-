// lib/screens/auth/login_screen.dart — FF PRO ARENA PK — Full Redesign v2
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../main_shell.dart';
import '../admin/admin_panel_screen.dart';

// ── FF PRO LOGO ───────────────────────────────────────────────────────────────
class FFProLogo extends StatefulWidget {
  final double size;
  const FFProLogo({super.key, this.size = 90});
  @override
  State<FFProLogo> createState() => _FFProLogoState();
}

class _FFProLogoState extends State<FFProLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(scale: _pulse.value, child: child),
      child: Stack(alignment: Alignment.center, children: [
        // Outer glow ring
        Container(
          width: widget.size + 30,
          height: widget.size + 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppTheme.neonGreen.withOpacity(0.15),
                  blurRadius: 40, spreadRadius: 10),
            ],
          ),
        ),
        // Logo circle
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.neonGreen.withOpacity(0.7), width: 2),
            boxShadow: [
              BoxShadow(color: AppTheme.neonGreen.withOpacity(0.4),
                  blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: CustomPaint(painter: _FFLogoPainter()),
        ),
      ]),
    );
  }
}

class _FFLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Crosshair ring
    canvas.drawCircle(Offset(cx, cy), size.width * 0.28,
        Paint()..color = AppTheme.neonGreen.withOpacity(0.8)
          ..style = PaintingStyle.stroke..strokeWidth = 2);

    // Crosshair lines
    final lp = Paint()..color = AppTheme.neonGreen
      ..strokeWidth = 2..strokeCap = StrokeCap.round;
    final gap = size.width * 0.10;
    final reach = size.width * 0.40;
    canvas.drawLine(Offset(cx - reach, cy), Offset(cx - gap, cy), lp);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + reach, cy), lp);
    canvas.drawLine(Offset(cx, cy - reach), Offset(cx, cy - gap), lp);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + reach), lp);

    // Center dot
    canvas.drawCircle(Offset(cx, cy), size.width * 0.055,
        Paint()..color = AppTheme.neonGreen);

    // "FF" text
    final tp = TextPainter(
      text: TextSpan(
        text: 'FF',
        style: TextStyle(
          color: AppTheme.background,
          fontSize: size.width * 0.22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── PARTICLE BACKGROUND ──────────────────────────────────────────────────────
class _Pt { double x, y, vx, vy, r, a; _Pt(this.x,this.y,this.vx,this.vy,this.r,this.a); }

class ParticleBg extends StatefulWidget {
  const ParticleBg({super.key});
  @override
  State<ParticleBg> createState() => _ParticleBgState();
}

class _ParticleBgState extends State<ParticleBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  final _rand = math.Random();
  late List<_Pt> _pts;

  @override
  void initState() {
    super.initState();
    _pts = List.generate(30, (_) => _Pt(
      _rand.nextDouble(), _rand.nextDouble(),
      (_rand.nextDouble() - 0.5) * 0.0006,
      -(_rand.nextDouble() * 0.0005 + 0.0002),
      _rand.nextDouble() * 2 + 0.5,
      _rand.nextDouble() * 0.5 + 0.1,
    ));
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 120))
      ..repeat();
    _c.addListener(_tick);
  }

  void _tick() {
    for (final p in _pts) {
      p.x += p.vx; p.y += p.vy;
      if (p.y < -0.02) p.y = 1.02;
      if (p.x < 0) p.x = 1.0;
      if (p.x > 1) p.x = 0.0;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() { _c.removeListener(_tick); _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PtPainter(_pts), size: Size.infinite);
}

class _PtPainter extends CustomPainter {
  final List<_Pt> pts;
  _PtPainter(this.pts);
  @override
  void paint(Canvas c, Size s) {
    for (final p in pts) {
      c.drawCircle(Offset(p.x * s.width, p.y * s.height), p.r,
          Paint()..color = AppTheme.neonGreen.withOpacity(p.a * 0.4));
    }
  }
  @override bool shouldRepaint(_) => true;
}

// ── FF TEXT FIELD ────────────────────────────────────────────────────────────
class FFTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscure;
  final IconData prefixIcon;
  final TextInputType keyboard;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const FFTextField({super.key, required this.label, this.hint,
      required this.controller, this.obscure = false,
      required this.prefixIcon,
      this.keyboard = TextInputType.text,
      this.validator, this.inputFormatters});

  @override
  State<FFTextField> createState() => _FFTFState();
}

class _FFTFState extends State<FFTextField> {
  bool _show = false;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: widget.obscure && !_show,
    keyboardType: widget.keyboard,
    inputFormatters: widget.inputFormatters,
    validator: widget.validator,
    style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
    decoration: InputDecoration(
      labelText: widget.label, hintText: widget.hint,
      prefixIcon: Icon(widget.prefixIcon, color: AppTheme.neonGreen, size: 20),
      suffixIcon: widget.obscure ? IconButton(
        icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppTheme.textMuted, size: 20),
        onPressed: () => setState(() => _show = !_show),
      ) : null,
    ),
  );
}

// ── NEON BUTTON ──────────────────────────────────────────────────────────────
class NeonButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? color;

  const NeonButton({super.key, required this.label, this.icon,
      this.onTap, this.isLoading = false, this.color});

  @override
  State<NeonButton> createState() => _NeonBtnState();
}

class _NeonBtnState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _sc;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _sc = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final col = widget.color ?? AppTheme.neonGreen;
    return AnimatedBuilder(
      animation: _sc,
      builder: (_, child) => Transform.scale(scale: _sc.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) { _c.reverse(); widget.onTap?.call(); },
        onTapCancel: () => _c.reverse(),
        child: Container(
          width: double.infinity, height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [col, col.withOpacity(0.75)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: col.withOpacity(0.4), blurRadius: 20, spreadRadius: 1),
              BoxShadow(color: col.withOpacity(0.15), blurRadius: 40, spreadRadius: 4),
            ],
          ),
          child: widget.isLoading
              ? Center(child: SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: AppTheme.background, strokeWidth: 2.5)))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: AppTheme.background, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.label,
                      style: AppTheme.heading3.copyWith(
                          color: AppTheme.background, letterSpacing: 1.5)),
                ]),
        ),
      ),
    );
  }
}

// ── CUSTOM TEXT FIELD (alias for splash_screen compat) ────────────────────────
typedef CustomTextField = FFTextField;

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey    = GlobalKey<FormState>();
  final _phoneCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _adminMode   = false;

  @override
  void initState() {
    super.initState();
    // Silently check if admin creds are entered
    _phoneCtrl.addListener(_checkAdmin);
    _passCtrl.addListener(_checkAdmin);
  }

  void _checkAdmin() {
    final isAdmin = _phoneCtrl.text.trim() == AppConstants.adminPhone &&
        _passCtrl.text.trim() == AppConstants.adminPassword;
    if (isAdmin != _adminMode) setState(() => _adminMode = isAdmin);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose(); _passCtrl.dispose(); super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();

    // Admin shortcut — go directly to admin panel
    if (_adminMode) {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
      return;
    }

    final ok = await context.read<AppProvider>().login(
      mobile: _phoneCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );
    if (ok && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      body: Stack(children: [
        // Background gradient
        Container(decoration: const BoxDecoration(gradient: AppTheme.bgGradient)),

        // Particle field
        const ParticleBg(),

        // Diagonal accent lines
        CustomPaint(painter: _DiagPainter(), size: Size.infinite),

        // Content
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const SizedBox(height: 30),

                // LOGO
                FadeInDown(duration: const Duration(milliseconds: 700),
                  child: const FFProLogo(size: 100)),

                const SizedBox(height: 20),

                // App name
                FadeInDown(delay: const Duration(milliseconds: 200),
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        AppTheme.neonGradient.createShader(bounds),
                    child: Text('FF PRO ARENA',
                        style: AppTheme.heading1.copyWith(color: Colors.white)),
                  )),
                FadeInDown(delay: const Duration(milliseconds: 300),
                  child: Text('PAKISTAN',
                      style: AppTheme.heading3.copyWith(
                          color: AppTheme.textSecondary, letterSpacing: 6))),

                const SizedBox(height: 8),

                FadeInDown(delay: const Duration(milliseconds: 350),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('FREE FIRE TOURNAMENT PLATFORM',
                        style: AppTheme.caption.copyWith(
                            color: AppTheme.neonGreen, letterSpacing: 1.5)),
                  )),

                const SizedBox(height: 44),

                // Login card
                FadeInUp(delay: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _adminMode
                            ? AppTheme.gold.withOpacity(0.5)
                            : AppTheme.divider,
                        width: _adminMode ? 1.5 : 1,
                      ),
                      boxShadow: _adminMode
                          ? AppTheme.goldGlow
                          : AppTheme.cardShadow,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Header
                      Row(children: [
                        Container(
                          width: 4, height: 22,
                          decoration: BoxDecoration(
                            gradient: _adminMode
                                ? AppTheme.goldGradient
                                : AppTheme.neonGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('SIGN IN',
                            style: AppTheme.heading3.copyWith(
                                color: _adminMode ? AppTheme.gold : AppTheme.neonGreen)),
                        const Spacer(),
                        if (_adminMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('ADMIN',
                                style: AppTheme.caption.copyWith(
                                    color: AppTheme.background,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1)),
                          ),
                      ]),

                      const SizedBox(height: 24),

                      // Error banner
                      if (provider.error != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline,
                                color: AppTheme.danger, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(provider.error!,
                                style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.danger))),
                          ]),
                        ),

                      FFTextField(
                        label: 'Mobile Number',
                        hint: '03xxxxxxxxx',
                        controller: _phoneCtrl,
                        prefixIcon: Icons.phone_android_rounded,
                        keyboard: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) =>
                            (v?.length ?? 0) < 10 ? 'Valid mobile required' : null,
                      ),

                      const SizedBox(height: 16),

                      FFTextField(
                        label: 'Password',
                        controller: _passCtrl,
                        obscure: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: (v) =>
                            (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                      ),

                      const SizedBox(height: 28),

                      NeonButton(
                        label: _adminMode ? 'ENTER ADMIN PANEL' : 'SIGN IN',
                        icon: _adminMode
                            ? Icons.admin_panel_settings
                            : Icons.login_rounded,
                        isLoading: provider.isLoading,
                        color: _adminMode ? AppTheme.gold : null,
                        onTap: _login,
                      ),
                    ]),
                  )),

                const SizedBox(height: 20),

                // Register link
                FadeInUp(delay: const Duration(milliseconds: 500),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("Don't have an account? ", style: AppTheme.bodySmall),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: Text('Register Now',
                          style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.neonGreen,
                              fontWeight: FontWeight.w700)),
                    ),
                  ])),

                const SizedBox(height: 30),

                // Footer
                FadeInUp(delay: const Duration(milliseconds: 600),
                  child: Row(children: [
                    const Expanded(child: Divider(color: AppTheme.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(children: [
                        const Icon(Icons.security, color: AppTheme.neonGreen, size: 12),
                        const SizedBox(width: 4),
                        Text('POWERED BY FIREBASE',
                            style: AppTheme.caption.copyWith(
                                color: AppTheme.neonGreen, letterSpacing: 1.2)),
                      ]),
                    ),
                    const Expanded(child: Divider(color: AppTheme.divider)),
                  ])),

                const SizedBox(height: 16),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DiagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppTheme.neonGreen.withOpacity(0.03)
      ..strokeWidth = 1;
    for (var i = -10; i < 20; i++) {
      final x = i * size.width / 10;
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// REGISTER SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _mobileCtrl   = TextEditingController();
  final _uidCtrl      = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final ok = await context.read<AppProvider>().register(
      mobile: _mobileCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      freeFireUid: _uidCtrl.text.trim(),
      displayName: _nameCtrl.text.trim(),
    );
    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      body: Stack(children: [
        Container(decoration: const BoxDecoration(gradient: AppTheme.bgGradient)),
        const ParticleBg(),
        SafeArea(
          child: Column(children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.textPrimary, size: 18),
                  ),
                ),
                const SizedBox(width: 16),
                Text('CREATE ACCOUNT', style: AppTheme.heading3.copyWith(
                    color: AppTheme.neonGreen)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (provider.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.danger.withOpacity(0.4)),
                        ),
                        child: Text(provider.error!,
                            style: AppTheme.bodySmall.copyWith(color: AppTheme.danger)),
                      ),

                    _Section(label: 'PLAYER INFO'),
                    const SizedBox(height: 12),
                    FFTextField(label: 'Display Name', hint: 'Your in-game name',
                        controller: _nameCtrl, prefixIcon: Icons.person_outline_rounded,
                        validator: (v) => (v?.length ?? 0) < 3 ? 'Min 3 chars' : null),
                    const SizedBox(height: 14),
                    FFTextField(label: 'Free Fire UID', hint: 'e.g. 1234567890',
                        controller: _uidCtrl, prefixIcon: Icons.games_rounded,
                        keyboard: TextInputType.number,
                        validator: (v) => (v?.length ?? 0) < 6 ? 'Enter valid UID' : null),

                    const SizedBox(height: 24),
                    _Section(label: 'ACCOUNT DETAILS'),
                    const SizedBox(height: 12),
                    FFTextField(label: 'Mobile Number', hint: '03xxxxxxxxx',
                        controller: _mobileCtrl,
                        prefixIcon: Icons.phone_android_rounded,
                        keyboard: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) => (v?.length ?? 0) < 10 ? 'Valid mobile required' : null),
                    const SizedBox(height: 14),
                    FFTextField(label: 'Password', controller: _passCtrl,
                        obscure: true, prefixIcon: Icons.lock_outline_rounded,
                        validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 chars' : null),
                    const SizedBox(height: 14),
                    FFTextField(label: 'Confirm Password', controller: _confirmCtrl,
                        obscure: true, prefixIcon: Icons.lock_outline_rounded,
                        validator: (v) => v != _passCtrl.text ? 'Passwords mismatch' : null),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline, color: AppTheme.neonGreen, size: 15),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          'Your mobile number is private and only visible to Admin.',
                          style: AppTheme.caption.copyWith(color: AppTheme.neonGreen),
                        )),
                      ]),
                    ),

                    const SizedBox(height: 32),
                    NeonButton(
                      label: 'CREATE ACCOUNT',
                      icon: Icons.person_add_rounded,
                      isLoading: provider.isLoading,
                      onTap: _register,
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section({required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 3, height: 14,
        decoration: BoxDecoration(
            gradient: AppTheme.neonGradient,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: AppTheme.neonLabel.copyWith(fontSize: 11)),
  ]);
}
