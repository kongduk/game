import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../domain/models/game_state.dart';

class SqliteGameDataSource {
  static const _dbName = 'onecard.db';
  static const _table = 'games';

  Database? _db;
  final StreamController<GameState?> _controller = StreamController.broadcast();

  Future<Database> get _database async {
    // Check if database is closed, if so reset the reference
    if (_db != null && !_db!.isOpen) {
      _db = null;
    }
    
    if (_db != null) return _db!;
    final databasesPath = await sqflite.getDatabasesPath();
    final path = join(databasesPath, _dbName);

    // Use ffi implementation on desktop (macOS, linux, windows) for development
    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      // initialize ffi and set global factory so sqflite.getDatabasesPath/openDatabase work in tests
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _db = await sqflite.openDatabase(path, version: 2, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE $_table (
          id TEXT PRIMARY KEY,
          json TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE game_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          game_id TEXT NOT NULL,
          json TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('''
          CREATE TABLE game_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            game_id TEXT NOT NULL,
            json TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      }
    });

    return _db!;
  }

  Future<void> saveGame(GameState gameState) async {
    final db = await _database;
    await db.insert(
      _table,
      {'id': gameState.id, 'json': jsonEncode(gameState.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _controller.add(gameState);
    // also record history
    await db.insert('game_history', {
      'game_id': gameState.id,
      'json': jsonEncode(gameState.toJson()),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> loadGameHistory(String gameId) async {
    final db = await _database;
    final rows = await db.query('game_history', where: 'game_id = ?', whereArgs: [gameId], orderBy: 'created_at ASC');
    return rows;
  }

  Future<GameState?> loadGame(String id) async {
    final db = await _database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final json = jsonDecode(rows.first['json'] as String) as Map<String, dynamic>;
    return GameState.fromJson(json);
  }

  Future<void> deleteGame(String id) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    _controller.add(null);
  }

  Stream<GameState?> watchGame(String id) async* {
    // initial
    final initial = await loadGame(id);
    yield initial;
    yield* _controller.stream;
  }

  Future<List<GameState>> listGames() async {
    final db = await _database;
    final rows = await db.query(_table);
    return rows.map((r) {
      final json = jsonDecode(r['json'] as String) as Map<String, dynamic>;
      return GameState.fromJson(json);
    }).toList();
  }

  Future<void> close() async {
    await _controller.close();
    await _db?.close();
    _db = null;
  }
}
