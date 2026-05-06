// lib/screens/wallet/wallet_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../splash_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text('MY WALLET', style: AppTheme.heading3),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Balance cards
                _BalanceCard(user: user),
                const SizedBox(height: 24),

                // Action buttons
                Row(children: [
                  Expanded(child: NeonButton(
                    label: 'DEPOSIT',
                    icon: Icons.add_circle_outline,
                    onTap: () => _showDepositSheet(context, user),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: NeonButton(
                    label: 'WITHDRAW',
                    icon: Icons.arrow_upward_rounded,
                    color: AppTheme.gold,
                    onTap: () => _showWithdrawSheet(context, user),
                  )),
                ]),

                const SizedBox(height: 24),

                // Payment methods info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.info_outline, color: AppTheme.neonGreen, size: 16),
                      const SizedBox(width: 8),
                      Text('Supported Payment Methods', style: AppTheme.neonLabel),
                    ]),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _PaymentMethod('Easypaisa', '0300-0000000', Colors.green),
                      _PaymentMethod('JazzCash',  '0300-0000000', Colors.red),
                    ]),
                  ]),
                ),

                const SizedBox(height: 24),

                // Transaction history
                _SectionHeader('TRANSACTION HISTORY'),
                const SizedBox(height: 12),

                StreamBuilder<List<TransactionModel>>(
                  stream: provider.db.transactionsStream(user.uid),
                  builder: (_, snap) {
                    final txns = snap.data ?? [];
                    if (txns.isEmpty) {
                      return Center(child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 48, color: AppTheme.textMuted),
                          const SizedBox(height: 8),
                          Text('No transactions yet', style: AppTheme.bodySmall),
                        ]),
                      ));
                    }
                    return Column(
                      children: txns.map((tx) => _TransactionTile(tx: tx)).toList());
                  },
                ),
              ]),
            ),
    );
  }

  void _showDepositSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DepositSheet(user: user),
    );
  }

  void _showWithdrawSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _WithdrawSheet(user: user),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final UserModel user;
  const _BalanceCard({required this.user});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0A2E1A), Color(0xFF061A0F), Color(0xFF0A1020)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
      boxShadow: AppTheme.neonGlow,
    ),
    child: Column(children: [
      Text('TOTAL BALANCE', style: AppTheme.neonLabel.copyWith(fontSize: 11)),
      const SizedBox(height: 8),
      Text('Rs. ${user.totalBalance.toStringAsFixed(0)}',
        style: GoogleFonts.orbitron(
          fontSize: 36, fontWeight: FontWeight.w800, color: AppTheme.neonGreen)),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: _BalanceItem(
          label: 'Wallet Balance',
          amount: user.walletBalance,
          color: AppTheme.neonGreen,
          icon: Icons.account_balance_wallet,
        )),
        Container(height: 50, width: 0.5, color: AppTheme.neonGreen.withOpacity(0.3)),
        Expanded(child: _BalanceItem(
          label: 'Winning Balance',
          amount: user.winningBalance,
          color: AppTheme.gold,
          icon: Icons.emoji_events,
        )),
      ]),
    ]),
  );
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _BalanceItem({required this.label, required this.amount,
    required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: color, size: 20),
    const SizedBox(height: 6),
    Text('Rs. ${amount.toStringAsFixed(0)}',
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
    const SizedBox(height: 2),
    Text(label, style: AppTheme.caption),
  ]);
}

class _PaymentMethod extends StatelessWidget {
  final String name, number;
  final Color color;
  const _PaymentMethod(this.name, this.number, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(children: [
      Text(name, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
      const SizedBox(height: 2),
      Text(number, style: AppTheme.caption),
    ]),
  );
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    Color color; IconData icon; String sign;
    if (tx.type == 'deposit' || tx.type == 'winning' || tx.type == 'bonus') {
      color = AppTheme.neonGreen; icon = Icons.arrow_downward_rounded; sign = '+';
    } else {
      color = AppTheme.danger; icon = Icons.arrow_upward_rounded; sign = '-';
    }
    Color statusColor = tx.isPending ? AppTheme.warning
                      : tx.isApproved ? AppTheme.neonGreen : AppTheme.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tx.type.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt),
            style: AppTheme.caption),
          if (tx.adminNote != null && tx.isRejected) ...[
            const SizedBox(height: 2),
            Text(tx.adminNote!, style: TextStyle(color: AppTheme.danger, fontSize: 11)),
          ],
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$sign Rs. ${tx.amount.toStringAsFixed(0)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(tx.status.toUpperCase(),
              style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
        ]),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: AppTheme.neonLabel),
    const SizedBox(width: 12),
    const Expanded(child: Divider(color: AppTheme.divider)),
  ]);
}

// ── Deposit Sheet ─────────────────────────────────────────────────────────
class _DepositSheet extends StatefulWidget {
  final UserModel user;
  const _DepositSheet({required this.user});
  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  final _amtCtrl    = TextEditingController();
  final _txIdCtrl   = TextEditingController();
  String _wallet    = 'Easypaisa';
  File?  _screenshot;
  bool   _isLoading = false;
  final _picker     = ImagePicker();

  Future<void> _pickScreenshot() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xfile != null) setState(() => _screenshot = File(xfile.path));
  }

  Future<void> _submit() async {
    final amt = double.tryParse(_amtCtrl.text.trim()) ?? 0;
    if (amt < 50) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Minimum deposit is Rs. 50'), backgroundColor: AppTheme.danger));
      return;
    }
    if (_screenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please attach payment screenshot'), backgroundColor: AppTheme.danger));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final ref = FirebaseStorage.instance
          .ref('payment_proofs/${const Uuid().v4()}.jpg');
      await ref.putFile(_screenshot!);
      final url = await ref.getDownloadURL();
      final tx = TransactionModel(
        id: '', userId: widget.user.uid, userName: widget.user.displayName,
        type: 'deposit', amount: amt, status: 'pending',
        transactionId: _txIdCtrl.text.trim(),
        screenshotUrl: url, mobileWallet: _wallet,
        mobileNumber: widget.user.mobile,
        createdAt: DateTime.now(),
      );
      await context.read<AppProvider>().db.submitDeposit(tx);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Deposit submitted! Awaiting admin approval.'),
          backgroundColor: AppTheme.neonGreen));
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SheetHandle(),
          Text('DEPOSIT FUNDS', style: AppTheme.heading3.copyWith(color: AppTheme.neonGreen)),
          const SizedBox(height: 20),

          // Wallet selector
          Row(children: ['Easypaisa', 'JazzCash'].map((w) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _wallet = w),
              child: Container(
                margin: EdgeInsets.only(right: w == 'Easypaisa' ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _wallet == w
                      ? AppTheme.neonGreen.withOpacity(0.15) : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _wallet == w ? AppTheme.neonGreen : AppTheme.divider,
                    width: _wallet == w ? 1.5 : 0.5,
                  ),
                ),
                child: Text(w, style: TextStyle(
                  color: _wallet == w ? AppTheme.neonGreen : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                )),
              ),
            ),
          )).toList()),

          const SizedBox(height: 16),
          CustomTextField(
            label: 'Amount (Rs.)', controller: _amtCtrl,
            keyboard: TextInputType.number,
            prefixIcon: Icons.payments_outlined,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Transaction ID (optional)', controller: _txIdCtrl,
            prefixIcon: Icons.receipt_outlined,
          ),
          const SizedBox(height: 14),

          // Screenshot picker
          GestureDetector(
            onTap: _pickScreenshot,
            child: Container(
              height: _screenshot != null ? 160 : 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _screenshot != null ? AppTheme.neonGreen : AppTheme.divider,
                  style: BorderStyle.solid,
                ),
              ),
              child: _screenshot != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_screenshot!, fit: BoxFit.cover, width: double.infinity))
                  : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.upload_rounded, color: AppTheme.textMuted, size: 28),
                      SizedBox(height: 6),
                      Text('Attach Payment Screenshot *',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ]),
            ),
          ),

          const SizedBox(height: 24),
          NeonButton(label: 'SUBMIT DEPOSIT', isLoading: _isLoading, onTap: _submit),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

// ── Withdraw Sheet ────────────────────────────────────────────────────────
class _WithdrawSheet extends StatefulWidget {
  final UserModel user;
  const _WithdrawSheet({required this.user});
  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amtCtrl  = TextEditingController();
  final _numCtrl  = TextEditingController();
  String _wallet  = 'Easypaisa';
  bool   _loading = false;

  Future<void> _submit() async {
    final amt = double.tryParse(_amtCtrl.text.trim()) ?? 0;
    if (amt < 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Minimum withdrawal is Rs. 100'), backgroundColor: AppTheme.danger));
      return;
    }
    if (widget.user.winningBalance < amt) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Insufficient winning balance'), backgroundColor: AppTheme.danger));
      return;
    }
    setState(() => _loading = true);
    try {
      final tx = TransactionModel(
        id: '', userId: widget.user.uid, userName: widget.user.displayName,
        type: 'withdrawal', amount: amt, status: 'pending',
        mobileWallet: _wallet, mobileNumber: _numCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      await context.read<AppProvider>().db.submitWithdrawal(tx);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Withdrawal request submitted!'),
          backgroundColor: AppTheme.neonGreen));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SheetHandle(),
          Text('WITHDRAW FUNDS', style: AppTheme.heading3.copyWith(color: AppTheme.gold)),
          const SizedBox(height: 4),
          Text('Available: Rs. ${widget.user.winningBalance.toStringAsFixed(0)} (Winning)',
            style: AppTheme.bodySmall),
          const SizedBox(height: 20),

          Row(children: ['Easypaisa', 'JazzCash'].map((w) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _wallet = w),
              child: Container(
                margin: EdgeInsets.only(right: w == 'Easypaisa' ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _wallet == w ? AppTheme.gold.withOpacity(0.1) : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _wallet == w ? AppTheme.gold : AppTheme.divider,
                    width: _wallet == w ? 1.5 : 0.5),
                ),
                child: Text(w, style: TextStyle(
                  color: _wallet == w ? AppTheme.gold : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700)),
              ),
            ),
          )).toList()),

          const SizedBox(height: 16),
          CustomTextField(
            label: 'Amount (Rs.)', controller: _amtCtrl,
            keyboard: TextInputType.number,
            prefixIcon: Icons.payments_outlined,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            label: 'Mobile Number', controller: _numCtrl,
            keyboard: TextInputType.phone,
            prefixIcon: Icons.phone_android,
          ),
          const SizedBox(height: 24),
          NeonButton(
            label: 'REQUEST WITHDRAWAL',
            color: AppTheme.gold, isLoading: _loading, onTap: _submit),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
    ),
  );
}

// re-exports
export '../splash_screen.dart' show NeonButton, CustomTextField;
// GoogleFonts import for balance card
import 'package:google_fonts/google_fonts.dart';
