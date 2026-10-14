import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../db.dart';
import '../models.dart';
import '../widgets/add_sheet.dart';

class FolderScreen extends StatefulWidget {
  final Folder folder;
  const FolderScreen({super.key, required this.folder});
  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<Item> _items = [];
  String _filter = 'all';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final items = await DB.instance.items(widget.folder.id, type: _filter == 'all' ? null : _filter);
    if (!mounted) return;
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folder.name)),
      body: Column(children: [
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), children: [
            for (final e in {'all': 'الكل', 'image': 'صور', 'pdf': 'PDF', 'video': 'فيديو', 'other': 'ملفات'}.entries)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: _filter == e.key,
                  onSelected: (_) { setState(() => _filter = e.key); _load(); },
                ),
              ),
          ]),
        ),
        Expanded(
          child: _items.isEmpty
            ? const Center(child: Text('المجلد فارغ — اضغط + لإضافة محتوى'))
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final it = _items[i];
                  return GestureDetector(
                    onTap: () => OpenFile.open(it.path),
                    onLongPress: () => showModalBottomSheet(context: context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
                      ListTile(leading: Icon(it.favorite ? Icons.star : Icons.star_border), title: Text(it.favorite ? 'إزالة من المفضلة' : 'مفضلة'),
                          onTap: () async { Navigator.pop(ctx); await DB.instance.toggleFav(it); _load(); }),
                      ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('حذف', style: TextStyle(color: Colors.red)),
                          onTap: () async { Navigator.pop(ctx); await DB.instance.deleteItem(it); _load(); }),
                    ])),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                      clipBehavior: Clip.antiAlias,
                      child: it.type == 'image' && File(it.path).existsSync()
                        ? Image.file(File(it.path), fit: BoxFit.cover)
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(it.type == 'pdf' ? Icons.picture_as_pdf : it.type == 'video' ? Icons.videocam : Icons.insert_drive_file, color: Colors.grey.shade600),
                            Padding(padding: const EdgeInsets.all(4), child: Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                          ]),
                    ),
                  );
                },
              ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddSheet(context, folderId: widget.folder.id, onChanged: _load),
        child: const Icon(Icons.add),
      ),
    );
  }
}
