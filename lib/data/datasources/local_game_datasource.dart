import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/models/game_state.dart';

class LocalGameDataSource {
  static const _fileName = 'last_game.json';

  Future<File> _localFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> saveGame(GameState gameState) async {
    final file = await _localFile();
    final jsonString = jsonEncode(gameState.toJson());
    await file.writeAsString(jsonString);
  }

  Future<GameState?> loadGame() async {
    try {
      final file = await _localFile();
      if (!await file.exists()) return null;
      final contents = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(contents);
      return GameState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteSavedGame() async {
    try {
      final file = await _localFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
