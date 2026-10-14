import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../db.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _email = TextEditingController();
  bool _bio = false;
  bool _busy = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    _email.text = await BackupService.driveEmail();
    setState(() => _bio = await AuthService.biometricOn());
  }

  Future<void> _run(Future<String> Function() fn) async {
    setState(() => _busy = true);
    try {
      final msg = await fn();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''), style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red.shade700));
    } finally { setState(() => _busy = false); }
  }

  Future<void> _setPin() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تعيين / تغيير رمز PIN'),
      content: TextField(controller: c, keyboardType: TextInputType.number, maxLength: 4, obscureText: true, decoration: const InputDecoration(labelText: 'رمز من 4 أرقام')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
      ],
    ));
    if (ok == true && c.text.length == 4) {
      await AuthService.setPin(c.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ رمز PIN')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(children: [
        const _Section('الأمان'),
        SwitchListTile(
          secondary: const Icon(Icons.fingerprint),
          title: const Text('فتح بالبصمة'),
          subtitle: const Text('Face ID / بصمة الإصبع'),
          value: _bio,
          onChanged: (v) async { await AuthService.setBiometric(v); setState(() => _bio = v); },
        ),
        ListTile(
          leading: const Icon(Icons.pin_outlined), title: const Text('رمز PIN للتطبيق'), subtitle: const Text('تعيين / تغيير'),
          onTap: _setPin,
        ),
        const _Section('النسخ الاحتياطي على Google Drive'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _email, keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'إيميل Google Drive',
              hintText: 'example@gmail.com',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
              suffixIcon: IconButton(icon: const Icon(Icons.save), onPressed: () async {
                await BackupService.saveDriveEmail(_email.text);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإيميل')));
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.cloud_upload), title: const Text('تصدير نسخة احتياطية الآن'), subtitle: const Text('ملف ZIP مشفّر يُرفع على Drive'),
          enabled: !_busy,
          onTap: () => _run(() => BackupService().backupNow()),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download), title: const Text('استيراد نسخة احتياطية'), subtitle: const Text('استرجاع من Drive'),
          enabled: !_busy,
          onTap: () => _run(() => BackupService().restore()),
        ),
        FutureBuilder<int>(
          future: DB.instance.storageBytes(),
          builder: (_, snap) {
            final used = (snap.data ?? 0) / (1024 * 1024);
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('مساحة التخزين: ${used.toStringAsFixed(1)} MB', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: used > 5000 ? 1 : used / 5000),
              ]),
            );
          },
        ),
        if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String t;
  const _Section(this.t);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(t, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
  );
}