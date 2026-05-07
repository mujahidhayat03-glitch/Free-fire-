import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _jazzCtrl = TextEditingController();
  final _easyCtrl = TextEditingController();
  bool _loading = false, _fetching = true;

  @override
  void initState() {
    super.initState();
    context.read<AppProvider>().db.paymentNumbersStream().first.then((n) {
      if (!mounted) return;
      _jazzCtrl.text = n['jazzCash'] ?? '';
      _easyCtrl.text = n['easyPaisa'] ?? '';
      setState(() => _fetching = false);
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await context.read<AppProvider>().db.savePaymentNumbers(
        jazzCash: _jazzCtrl.text.trim(),
        easyPaisa: _easyCtrl.text.trim(),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Payment numbers save ho gaye!'),
        backgroundColor: AppTheme.neonGreen));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _jazzCtrl.dispose(); _easyCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(backgroundColor: AppTheme.surface,
        title: const Text('Payment Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: _fetching
        ? const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen))
        : Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          _field('JazzCash Number', _jazzCtrl, Colors.red),
          const SizedBox(height: 20),
          _field('Easypaisa Number', _easyCtrl, Colors.green),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _loading
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text('SAVE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)))),
        ])));
  }

  Widget _field(String label, TextEditingController ctrl, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextField(controller: ctrl, keyboardType: TextInputType.phone,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: '03XX-XXXXXXX',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(Icons.phone_android, color: color),
          filled: true, fillColor: AppTheme.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color.withOpacity(0.4))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color.withOpacity(0.4))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color, width: 2)))),
    ]);
}
