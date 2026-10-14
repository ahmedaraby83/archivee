import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../db.dart';
import '../models.dart';

const kFolderColors = [0xFF3B82F6, 0xFF22C55E, 0xFFA855F7, 0xFFEF4444, 0xFF6B7280];

String typeOf(String path) {
  final ext = p.extension(path).toLowerCase();
  if (['.jpg','.jpeg','.png','.webp','.gif','.heic'].contains(ext)) return 'image';
  if (ext == '.pdf') return 'pdf';
  if (['.mp4','.mov','.avi','.mkv'].contains(ext)) return 'video';
  return 'other';
}

Future<void> importFiles(BuildContext context, int folderId) async {
  final res = await FilePicker.platform.pickFiles(allowMultiple: true, withData: false);
  if (res == null) return;
  final dir = await DB.instance.filesDir();
  for (final f in res.files) {
    if (f.path == null) continue;
    final dest = p.join(dir, '${DateTime.now().millisecondsSinceEpoch}_${f.name}');
    await File(f.path!).copy(dest);
    await DB.instance.addItem(folderId, f.name, dest, typeOf(dest));
  }
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الملفات')));
}

Future<void> importImages(BuildContext context, int folderId) async {
  final pics = await ImagePicker().pickMultiImage();
  if (pics.isEmpty) return;
  final dir = await DB.instance.filesDir();
  for (final x in pics) {
    final dest = p.join(dir, '${DateTime.now().millisecondsSinceEpoch}_${p.basename(x.path)}');
    await File(x.path).copy(dest);
    await DB.instance.addItem(folderId, p.basename(dest), dest, 'image');
  }
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الصور')));
}

Future<void> newFolderDialog(BuildContext context, {bool lockedDefault = false, VoidCallback? onDone}) async {
  final nameCtrl = TextEditingController();
  int color = 0;
  bool locked = lockedDefault;
  final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
    builder: (ctx, setS) => AlertDialog(
      title: const Text('مجلد جديد'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المجموعة'), autofocus: true),
        const SizedBox(height: 12),
        Row(children: [
          for (int i = 0; i < kFolderColors.length; i++)
            GestureDetector(
              onTap: () => setS(() => color = i),
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Color(kFolderColors[i]),
                  border: color == i ? Border.all(color: Colors.black, width: 2.5) : null,
                ),
              ),
            ),
        ]),
        SwitchListTile(
          title: const Text('مجلد مؤمّن (PIN / بصمة)'),
          value: locked,
          onChanged: (v) => setS(() => locked = v),
          contentPadding: EdgeInsets.zero,
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إنشاء')),
      ],
    ),
  ));
  if (ok == true && nameCtrl.text.trim().isNotEmpty) {
    await DB.instance.addFolder(nameCtrl.text.trim(), color, locked);
    onDone?.call();
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء المجلد')));
  }
}

void showAddSheet(BuildContext context, {int? folderId, VoidCallback? onChanged}) {
  showModalBottomSheet(context: context, builder: (ctx) => SafeArea(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.photo_library), title: const Text('رفع صور من المعرض'),
          onTap: () async { Navigator.pop(ctx); if (folderId != null) await importImages(context, folderId); onChanged?.call(); }),
      ListTile(leading: const Icon(Icons.upload_file), title: const Text('رفع ملفات (PDF / Word)'),
          onTap: () async { Navigator.pop(ctx); if (folderId != null) await importFiles(context, folderId); onChanged?.call(); }),
      ListTile(leading: const Icon(Icons.folder), title: const Text('مجلد جديد (مجموعة)'),
          onTap: () { Navigator.pop(ctx); newFolderDialog(context, onDone: onChanged); }),
      ListTile(leading: const Icon(Icons.lock), title: const Text('مجلد مؤمّن (بالبصمة / PIN)'),
          onTap: () { Navigator.pop(ctx); newFolderDialog(context, lockedDefault: true, onDone: onChanged); }),
    ]),
  ));
}