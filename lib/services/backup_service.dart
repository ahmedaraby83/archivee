import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class BackupService {
  static const _fileName = 'archivee-backup.enc';
  static const _scopes = ['email', 'https://www.googleapis.com/auth/drive.file'];
  final _gsi = GoogleSignIn(scopes: _scopes);

  // الإيميل المخزن في الإعدادات
  static Future<String> driveEmail() async =>
      (await SharedPreferences.getInstance()).getString('drive_email') ?? '';

  static Future<void> saveDriveEmail(String email) async =>
      (await SharedPreferences.getInstance()).setString('drive_email', email.trim());

  Future<GoogleSignInAccount?> _signIn(String expectedEmail) async {
    final account = await _gsi.signInSilently() ?? await _gsi.signIn();
    if (account == null) return null;
    if (expectedEmail.isNotEmpty && account.email.toLowerCase() != expectedEmail.toLowerCase()) {
      throw Exception('الحساب المختار (${account.email}) مختلف عن الإيميل المسجل في الإعدادات');
    }
    return account;
  }

  Future<File> _buildEncryptedBackup() async {
    final docs = await getApplicationDocumentsDirectory();
    final archive = Archive();
    for (final entity in docs.listSync(recursive: true)) {
      if (entity is File) {
        final rel = relative(entity.path, from: docs.path);
        archive.addFile(ArchiveFile(rel, entity.lengthSync(), entity.readAsBytesSync()));
      }
    }
    final zipBytes = ZipEncoder().encode(archive)!;
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(await AuthService.backupKey()));
    final encrypted = encrypter.encryptBytes(zipBytes, iv: iv);
    final out = File(join((await getTemporaryDirectory()).path, _fileName));
    await out.writeAsBytes([...iv.bytes, ...encrypted.bytes]);
    return out;
  }

  Future<String> backupNow() async {
    final expected = await driveEmail();
    if (expected.isEmpty) throw Exception('اكتب إيميل Google Drive في الإعدادات أولًا');
    final account = await _signIn(expected);
    if (account == null) throw Exception('لم يتم اختيار حساب');
    final auth = await account.authentication;
    final backup = await _buildEncryptedBackup();

    // ابحث عن نسخة سابقة واحدثها وإلا أنشئ ملفًا جديدًا في appDataFolder
    final listRes = await http.get(
      Uri.parse("https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&q=name='$_fileName'&fields=files(id)"),
      headers: {'Authorization': 'Bearer ${auth.accessToken}'},
    );
    final files = (jsonDecode(listRes.body)['files'] as List?) ?? [];
    String fileId;
    if (files.isNotEmpty) {
      fileId = files.first['id'];
    } else {
      final createRes = await http.post(
        Uri.parse('https://www.googleapis.com/drive/v3/files?fields=id'),
        headers: {'Authorization': 'Bearer ${auth.accessToken}', 'Content-Type': 'application/json'},
        body: jsonEncode({'name': _fileName, 'parents': ['appDataFolder']}),
      );
      fileId = jsonDecode(createRes.body)['id'];
    }
    final upRes = await http.patch(
      Uri.parse('https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media'),
      headers: {'Authorization': 'Bearer ${auth.accessToken}', 'Content-Type': 'application/octet-stream'},
      body: await backup.readAsBytes(),
    );
    if (upRes.statusCode > 299) throw Exception('فشل الرفع: ${upRes.statusCode}');
    await (await SharedPreferences.getInstance()).setString('last_backup', DateTime.now().toIso8601String());
    return 'تم رفع النسخة على حساب ${account.email}';
  }

  Future<String> restore() async {
    final expected = await driveEmail();
    final account = await _signIn(expected);
    if (account == null) throw Exception('لم يتم اختيار حساب');
    final auth = await account.authentication;
    final listRes = await http.get(
      Uri.parse("https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&q=name='$_fileName'&fields=files(id)"),
      headers: {'Authorization': 'Bearer ${auth.accessToken}'},
    );
    final files = (jsonDecode(listRes.body)['files'] as List?) ?? [];
    if (files.isEmpty) throw Exception('لا توجد نسخة احتياطية على هذا الحساب');
    final dl = await http.get(
      Uri.parse('https://www.googleapis.com/drive/v3/files/${files.first['id']}?alt=media'),
      headers: {'Authorization': 'Bearer ${auth.accessToken}'},
    );
    if (dl.statusCode > 299) throw Exception('فشل التنزيل: ${dl.statusCode}');
    final all = dl.bodyBytes;
    final iv = enc.IV(Uint8List.fromList(all.sublist(0, 16)));
    final data = Uint8List.fromList(all.sublist(16));
    final encrypter = enc.Encrypter(enc.AES(await AuthService.backupKey()));
    final zipBytes = encrypter.decryptBytes(enc.Encrypted(data), iv: iv);
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final docs = await getApplicationDocumentsDirectory();
    for (final f in archive.files) {
      if (f.isFile) {
        final out = File(join(docs.path, f.name));
        await out.create(recursive: true);
        await out.writeAsBytes(f.content as List<int>);
      }
    }
    return 'تم استرجاع النسخة بنجاح — أعد فتح التطبيق';
  }
}
