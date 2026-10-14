class Folder {
  final int id;
  final String name;
  final int color;
  final bool locked;
  final String createdAt;
  Folder({required this.id, required this.name, required this.color, required this.locked, required this.createdAt});
  factory Folder.fromMap(Map<String, dynamic> m) => Folder(
    id: m['id'], name: m['name'], color: m['color'] ?? 0,
    locked: (m['locked'] ?? 0) == 1, createdAt: m['created_at'] ?? '');
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'color': color, 'locked': locked ? 1 : 0, 'created_at': createdAt};
}

class Item {
  final int id;
  final int folderId;
  final String name;
  final String path;
  final String type; // image / pdf / video / other
  final bool favorite;
  final String createdAt;
  Item({required this.id, required this.folderId, required this.name, required this.path, required this.type, required this.favorite, required this.createdAt});
  factory Item.fromMap(Map<String, dynamic> m) => Item(
    id: m['id'], folderId: m['folder_id'], name: m['name'], path: m['path'],
    type: m['type'] ?? 'other', favorite: (m['favorite'] ?? 0) == 1, createdAt: m['created_at'] ?? '');
  Map<String, dynamic> toMap() => {'id': id, 'folder_id': folderId, 'name': name, 'path': path, 'type': type, 'favorite': favorite ? 1 : 0, 'created_at': createdAt};
}

const kTypeLabels = {'image': 'صور', 'pdf': 'PDF', 'video': 'فيديو', 'other': 'ملفات'};