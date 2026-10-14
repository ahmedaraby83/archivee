import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'models.dart';

class DB {
  static final DB instance = DB._();
  DB._();
  static Database? _db;

  Future<Database> get db async => _db ??= await _init();

  Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'archivee.db');
    return await openDatabase(path, version: 1, onCreate: (d, v) async {
      await d.execute('CREATE TABLE folders(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, color INTEGER, locked INTEGER DEFAULT 0, created_at TEXT)');
      await d.execute('CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, folder_id INTEGER, name TEXT, path TEXT, type TEXT, favorite INTEGER DEFAULT 0, created_at TEXT)');
    });
  }

  Future<String> filesDir() async {
    final dir = Directory(join((await getApplicationDocumentsDirectory()).path, 'files'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<List<Folder>> folders() async {
    final d = await db;
    return (await d.query('folders', orderBy: 'id DESC')).map(Folder.fromMap).toList();
  }

  Future<Folder> addFolder(String name, int color, bool locked) async {
    final d = await db;
    final id = await d.insert('folders', {'name': name, 'color': color, 'locked': locked ? 1 : 0, 'created_at': DateTime.now().toIso8601String()});
    return Folder(id: id, name: name, color: color, locked: locked, createdAt: DateTime.now().toIso8601String());
  }

  Future<void> deleteFolder(int id) async {
    final d = await db;
    final items = await d.query('items', where: 'folder_id = ?', whereArgs: [id]);
    for (final it in items) { try { await File(it['path'] as String).delete(); } catch (_) {} }
    await d.delete('items', where: 'folder_id = ?', whereArgs: [id]);
    await d.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Item>> items(int folderId, {String? type, String query = '', bool favOnly = false}) async {
    final d = await db;
    String where = 'folder_id = ?';
    List args = [folderId];
    if (type != null && type != 'all') { where += ' AND type = ?'; args.add(type); }
    if (favOnly) where += ' AND favorite = 1';
    if (query.isNotEmpty) { where += ' AND name LIKE ?'; args.add('%$query%'); }
    return (await d.query('items', where: where, whereArgs: args, orderBy: 'id DESC')).map(Item.fromMap).toList();
  }

  Future<Item> addItem(int folderId, String name, String path, String type) async {
    final d = await db;
    final id = await d.insert('items', {'folder_id': folderId, 'name': name, 'path': path, 'type': type, 'favorite': 0, 'created_at': DateTime.now().toIso8601String()});
    return Item(id: id, folderId: folderId, name: name, path: path, type: type, favorite: false, createdAt: DateTime.now().toIso8601String());
  }

  Future<void> toggleFav(Item item) async {
    final d = await db;
    await d.update('items', {'favorite': item.favorite ? 0 : 1}, where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteItem(Item item) async {
    final d = await db;
    try { await File(item.path).delete(); } catch (_) {}
    await d.delete('items', where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> countItems(int folderId) async {
    final d = await db;
    final r = await d.rawQuery('SELECT COUNT(*) c FROM items WHERE folder_id = ?', [folderId]);
    return (r.first['c'] as int?) ?? 0;
  }

  Future<List<Item>> searchAll(String query) async {
    final d = await db;
    return (await d.query('items', where: 'name LIKE ?', whereArgs: ['%$query%'])).map(Item.fromMap).toList();
  }

  Future<int> storageBytes() async {
    final dir = Directory(await filesDir());
    int total = 0;
    if (await dir.exists()) {
      await for (final f in dir.list(recursive: true)) {
        if (f is File) total += await f.length();
      }
    }
    return total;
  }
}