import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';
import '../widgets/add_sheet.dart';
import 'folder_screen.dart';
import 'lock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Folder> _folders = [];
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final folders = await DB.instance.folders();
    if (!mounted) return;
    setState(() => _folders = folders);
  }

  void _openFolder(Folder f) {
    if (f.locked) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => LockScreen(
        title: '${f.name} مقفول',
        onUnlocked: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => FolderScreen(folder: f))).then((_) => _load());
        },
      )));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => FolderScreen(folder: f))).then((_) => _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أرشيفي'), centerTitle: false),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _search, onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث في الأرشيف…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: _folders.isEmpty
            ? const Center(child: Text('لا توجد مجموعات بعد — اضغط + للبدء'))
            : ListView.builder(
                itemCount: _folders.length,
                itemBuilder: (_, i) {
                  final f = _folders[i];
                  return FutureBuilder<int>(
                    future: DB.instance.countItems(f.id),
                    builder: (_, snap) {
                      final n = snap.data ?? 0;
                      final match = _search.text.isEmpty || f.name.contains(_search.text);
                      if (!match) return const SizedBox.shrink();
                      return ListTile(
                        onTap: () => _openFolder(f),
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: Color(kFolderColors[f.color % kFolderColors.length]).withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                          child: Icon(f.locked ? Icons.lock : Icons.folder, color: Color(kFolderColors[f.color % kFolderColors.length])),
                        ),
                        title: Text(f.name),
                        subtitle: Text('$n عنصر${f.locked ? ' · محمي' : ''}'),
                        trailing: PopupMenuButton(itemBuilder: (_) => [
                          PopupMenuItem(value: 'del', child: const Text('حذف المجلد')),
                        ], onSelected: (v) async {
                          await DB.instance.deleteFolder(f.id);
                          _load();
                        }),
                      );
                    },
                  );
                },
              ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddSheet(context, onChanged: _load),
        child: const Icon(Icons.add),
      ),
    );
  }
}
