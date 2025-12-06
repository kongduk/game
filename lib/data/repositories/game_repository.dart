import '../../domain/models/game_state.dart';
import '../datasources/sqlite_game_datasource.dart';

class GameRepository {
  final SqliteGameDataSource _local = SqliteGameDataSource();

  Future<String> createGame(GameState gameState) async {
    // ensure id present
    final id = gameState.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : gameState.id;
    final toSave = gameState.copyWith(id: id);
    await _local.saveGame(toSave);
    return id;
  }

  Future<void> updateGame(String gameId, GameState gameState) async {
    await _local.saveGame(gameState.copyWith(id: gameId));
  }

  Stream<GameState?> watchGame(String gameId) {
    return _local.watchGame(gameId);
  }

  Future<GameState?> getGame(String gameId) async {
    return await _local.loadGame(gameId);
  }

  Future<void> deleteGame(String gameId) async {
    await _local.deleteGame(gameId);
  }

  Future<List<GameState>> listGames() async => await _local.listGames();
}
