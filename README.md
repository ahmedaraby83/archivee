# أرشيفي (Archivee)

تطبيق أرشفة ملفات وصور بـ Flutter — مجلدات ومجموعات، قفل PIN + بصمة، ونسخ احتياطي مشفّر على Google Drive.

## التشغيل والبناء

1. ثبّت Flutter: https://flutter.dev/docs/get-started/install
2. افتح مجلد المشروع ونفّذ:

```bash
flutter create . --org com.example   # يولّد ملفات Android/iOS الناقصة
flutter pub get
flutter run                          # تشغيل على جهاز/محاكي
flutter build apk --release          # بناء ملف APK
```

ملف الـ APK النهائي يظهر في: `build/app/outputs/flutter-apk/app-release.apk`

## إعداد Google Drive (خطوة لازمة مرة واحدة)

1. افتح https://console.cloud.google.com وأنشئ مشروعًا جديدًا.
2. فعّل **Google Drive API**.
3. من "Credentials" أنشئ OAuth Client ID من نوع **Android**:
   - هات SHA-1 بالأمر:
     `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
4. حمّل ملف `google-services.json` إن طُلب، والأهم: ضع **Client ID** في ملف
   `android/app/src/main/res/values/strings.xml` (أنشئه):
   ```xml
   <resources>
     <string name="default_web_client_id">YOUR_WEB_CLIENT_ID.apps.googleusercontent.com</string>
   </resources>
   ```
   (google_sign_in في أندرويد يحتاج Web Client ID حتى مع تسجيل الدخول بحسابات أندرويد).

## طريقة الاستخدام

- **الرئيسية**: أنشئ مجموعات (مجلدات) ملوّنة، بعضها يمكن قفله.
- **داخل المجموعة**: أضف صورًا أو ملفات، صور مصغّرة، فلاتر حسب النوع، مفضلة وحذف بالضغط المطوّل.
- **القفل**: عند أول استخدام اذهب للإعدادات واعرض PIN (4 أرقام). أي مجلد مقفول يطلب الرمز أو البصمة.
- **Drive**: في الإعدادات اكتب إيميل Google Drive (مثلك@gmail.com) واحفظه، ثم "تصدير نسخة احتياطية الآن".
  عند أول نسخ سيظهر اختيار الحساب — اختر نفس الإيميل. النسخة مشفّرة بالكامل (AES-256) وتُرفع
  إلى مجلد التطبيق الخفي (appDataFolder) فلا تظهر في درايفك وتشوّش عليه.
- **الاستيراد**: من الإعدادات → "استيراد نسخة احتياطية" ثم أعد فتح التطبيق.

## بنية المشروع

```
lib/
  main.dart                  # نقطة الدخول + قفل التطبيق عند البدء
  models.dart                # نماذج البيانات
  db.dart                    # قاعدة البيانات المحلية (sqflite) + نسخ الملفات
  services/auth_service.dart # PIN (SHA-256) + البصمة (local_auth) + مفتاح التشفير
  services/backup_service.dart # ضغط ZIP + تشفير AES + رفع/تنزيل Drive
  screens/                   # الرئيسية، المجموعة، الإعدادات، شاشة القفل
  widgets/add_sheet.dart     # نافذة الإضافة (صور/ملفات/مجلد/مجلد مؤمّن)
```