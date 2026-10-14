import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';

class LockScreen extends StatefulWidget {
  final String title;
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked, this.title = 'الأرشيف مقفول'});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    if (await AuthService.biometricOn() && await AuthService.canBiometric()) {
      if (await AuthService.unlockWithBiometric()) widget.onUnlocked();
    }
  }

  Future<void> _press(String d) async {
    if (_pin.length >= 4) return;
    setState(() { _pin += d; _error = false; });
    if (_pin.length == 4) {
      final ok = await AuthService.checkPin(_pin);
      if (ok) { widget.onUnlocked(); }
      else { setState(() { _pin = ''; _error = true; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            const Icon(Icons.fingerprint, size: 44),
            const SizedBox(height: 12),
            Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(_error ? 'رمز خاطئ، حاول مرة أخرى' : 'استخدم البصمة أو أدخل رمز PIN',
                style: TextStyle(fontSize: 13, color: _error ? Theme.of(context).colorScheme.error : Colors.grey)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) {
              final filled = _pin.length > i;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 12, height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                  color: filled ? Colors.black : Colors.transparent,
                ),
              );
            })),
            const SizedBox(height: 32),
            Directionality(
              textDirection: TextDirection.ltr,
              child: GridView.count(
                shrinkWrap: true, crossAxisCount: 3,
                mainAxisSpacing: 12, crossAxisSpacing: 12,
                padding: const EdgeInsets.symmetric(horizontal: 60),
                childAspectRatio: 1.2,
                children: [
                  for (final k in ['1','2','3','4','5','6','7','8','9'])
                    _key(k),
                  const SizedBox(),
                  _key('0'),
                  _key('del', label: 'مسح'),
                ],
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _key(String k, {String? label}) => OutlinedButton(
    onPressed: () {
      if (k == 'del') setState(() { _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1); _error = false; });
      else _press(k);
    },
    style: OutlinedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(16)),
    child: Text(label ?? k, style: const TextStyle(fontSize: 20)),
  );
}