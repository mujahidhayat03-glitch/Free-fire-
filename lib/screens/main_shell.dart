// lib/screens/main_shell.dart — FF PRO ARENA PK — Redesigned Navigation
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import 'home/home_screen.dart';
import 'chat/chat_screen.dart';
import 'wallet/wallet_screen.dart';
import 'profile/profile_screen.dart';
import 'admin/admin_panel_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;

  final _screens = const [
    HomeScreen(),
    ChatScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  final _items = const [
    _NavItem(icon: Icons.sports_esports_rounded, label: 'Tournaments'),
    _NavItem(icon: Icons.forum_rounded, label: 'Chat'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Wallet'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  void _onTap(int i) {
    HapticFeedback.selectionClick();
    setState(() => _idx = i);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    final isAdmin = user?.role == AppConstants.roleAdmin;

    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4),
                blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(children: [
              ..._items.asMap().entries.map((e) =>
                  _NavBtn(item: e.value, selected: _idx == e.key,
                      onTap: () => _onTap(e.key))),
              if (isAdmin)
                _NavBtn(
                  item: const _NavItem(icon: Icons.admin_panel_settings_rounded, label: 'Admin'),
                  selected: false,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
                  color: AppTheme.gold,
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavBtn extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _NavBtn({required this.item, required this.selected,
      required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final sel = color ?? AppTheme.neonGreen;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? sel.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(item.icon,
                color: selected ? sel : AppTheme.textMuted, size: 22),
          ),
          const SizedBox(height: 2),
          Text(item.label,
              style: AppTheme.caption.copyWith(
                  color: selected ? sel : AppTheme.textMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 10)),
        ]),
      ),
    );
  }
}
