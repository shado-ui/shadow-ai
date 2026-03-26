import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    // Required for Windows/Linux desktop support
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dirPath;
    if (Platform.isWindows) {
      dirPath = '${Platform.environment['LOCALAPPDATA']}${Platform.pathSeparator}ShadowHub';
    } else if (Platform.isLinux) {
      dirPath = '${Platform.environment['HOME']}${Platform.pathSeparator}.shadow_hub';
    } else {
      final appDir = await getApplicationSupportDirectory();
      dirPath = appDir.path;
    }
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final path = '$dirPath${Platform.pathSeparator}shadow_hub_v2.db';

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        // Ensure tables and default project always exist
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects(
        id TEXT PRIMARY KEY,
        title TEXT,
        memory TEXT,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages(
        id TEXT PRIMARY KEY,
        project_id TEXT,
        content TEXT,
        role TEXT,
        mode TEXT,
        timestamp INTEGER,
        model_used TEXT,
        FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Ensure default project exists
    final existing = await db.query('projects', where: 'id = ?', whereArgs: ['default']);
    if (existing.isEmpty) {
      await db.insert('projects', {
        'id': 'default',
        'title': 'General Chat',
        'memory': '',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // --- Projects ---
  Future<List<Map<String, dynamic>>> getProjects() async {
    final db = await database;
    return await db.query('projects', orderBy: 'updated_at DESC');
  }

  Future<void> createProject(String id, String title, {String memory = ''}) async {
    final db = await database;
    await db.insert('projects', {
      'id': id,
      'title': title,
      'memory': memory,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProjectMemory(String id, String memory) async {
    final db = await database;
    await db.update('projects', {'memory': memory, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // --- Messages ---
  Future<List<Map<String, dynamic>>> getMessages(String projectId) async {
    final db = await database;
    return await db.query('messages', where: 'project_id = ?', whereArgs: [projectId], orderBy: 'timestamp ASC');
  }

  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    
    // Ensure parent project exists before inserting child message (FK constraint)
    final pid = message['project_id'] as String?;
    if (pid != null) {
      final existing = await db.query('projects', where: 'id = ?', whereArgs: [pid]);
      if (existing.isEmpty) {
        await db.insert('projects', {
          'id': pid,
          'title': pid == 'default' ? 'General Chat' : 'New Chat',
          'memory': '',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
    
    await db.insert('messages', message, conflictAlgorithm: ConflictAlgorithm.replace);
    
    // Update project timestamp
    if (pid != null) {
      await db.update('projects', {'updated_at': message['timestamp']},
          where: 'id = ?', whereArgs: [pid]);
    }
  }

  Future<int> getMessageCount(String projectId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM messages WHERE project_id = ?', [projectId]);
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<void> updateProjectTitle(String id, String title) async {
    final db = await database;
    await db.update('projects', {'title': title}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEmptyProjects({String? excludeId}) async {
    final db = await database;
    final projects = await db.query('projects');
    for (final p in projects) {
      final pid = p['id'] as String;
      if (pid == 'default' || pid == excludeId) continue;
      final count = await getMessageCount(pid);
      if (count == 0) {
        await db.delete('projects', where: 'id = ?', whereArgs: [pid]);
      }
    }
  }

  Future<void> clearHistory(String projectId) async {
    final db = await database;
    await db.delete('messages', where: 'project_id = ?', whereArgs: [projectId]);
  }

  // --- Settings ---
  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (results.isNotEmpty) {
      return results.first['value'] as String?;
    }
    return null;
  }

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Backup & Restore ---
  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    final projects = await db.query('projects');
    final messages = await db.query('messages');
    final settings = await db.query('settings');
    return {
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'projects': projects,
      'messages': messages,
      'settings': settings,
    };
  }

  Future<int> importAllData(Map<String, dynamic> data) async {
    final db = await database;
    int count = 0;

    final projects = data['projects'] as List<dynamic>? ?? [];
    for (final p in projects) {
      await db.insert('projects', Map<String, dynamic>.from(p), conflictAlgorithm: ConflictAlgorithm.replace);
      count++;
    }

    final messages = data['messages'] as List<dynamic>? ?? [];
    for (final m in messages) {
      await db.insert('messages', Map<String, dynamic>.from(m), conflictAlgorithm: ConflictAlgorithm.replace);
      count++;
    }

    final settings = data['settings'] as List<dynamic>? ?? [];
    for (final s in settings) {
      await db.insert('settings', Map<String, dynamic>.from(s), conflictAlgorithm: ConflictAlgorithm.replace);
      count++;
    }

    return count;
  }
}

