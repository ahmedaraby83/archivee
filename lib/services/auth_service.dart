import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;

class AuthService {
  static const _st = FlutterSecureStorage();
  static final _localAuth = LocalAuthentication();

  static Future<bool> hasPin() async => (await _st.read(key: 'pin_hash')) != null;

  static Future<void> setPin(String pin) async {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = sha256.convert(utf8.encode(salt + pin)).toString();
    await _st.write(key: 'pin_salt', value: salt);
    await _st.write(key: 'pin_hash', value: hash);
  }

  static Future<bool> checkPin(String pin) async {
    final salt = await _st.read(key: 'pin_salt');
    final hash = await _st.read(key: 'pin_hash');
    if (salt == null || hash == null) return false;
    return sha256.convert(utf8.encode(salt + pin)).toString() == hash;
  }

  static Future<bool> biometricOn() async => (await _st.read(key: 'biometric')) == '1';

  static Future<void> setBiometric(bool v) async => _st.write(key: 'biometric', value: v ? '1' : '0');

  static Future<bool> canBiometric() async {
    try {
      return await _localAuth.canCheckBiometrics && await _localAuth.isDeviceSupported();
    } catch (_) { return false; }
  }

  static Future<bool> unlockWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'افتح الأرشيف ببصمتك',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (_) { return false; }
  }

  static Future<enc.Key> backupKey() async {
    final existing = await _st.read(key: 'backup_key');
    if (existing != null) return enc.Key.fromBase64(existing);
    final key = enc.Key.fromSecureRandom(32);
    await _st.write(key: 'backup_key', value: key.base64);
    return key;
  }
}