import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/card.dart';
import '../../data/repositories/game_repository.dart';
import '../../domain/services/game_logic.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository();
});

final gameStateProvider =
    StreamProvider.family<GameState?, String>((ref, gameId) {
  final repository = ref.watch(gameRepositoryProvider);
  return repository.watchGame(gameId);
});

class GameNotifier extends StateNotifier<GameState?> {
  final GameRepository _repository;
  final String _gameId;

  GameNotifier(this._repository, this._gameId) : super(null) {
    _loadGame();
  }

  Future<void> _loadGame() async {
    final game = await _repository.getGame(_gameId);
    state = game;
  }

  Future<void> createNewGame(List<String> playerNames) async {
    final gameState = GameLogic.initializeGame(playerNames);
    final gameId = await _repository.createGame(gameState);
    state = gameState.copyWith(id: gameId);
  }

  Future<void> playCard(String playerId, Card card) async {
    if (state == null) return;

    final newState = GameLogic.playCard(state!, playerId, card);
    await _repository.updateGame(_gameId, newState);
    state = newState;
  }

  Future<void> drawCard(String playerId) async {
    if (state == null) return;

    final newState = GameLogic.drawCard(state!, playerId);
    await _repository.updateGame(_gameId, newState);
    state = newState;
  }

  Future<void> selectSuit(CardSuit suit) async {
    if (state == null) return;

    final newState = GameLogic.selectSuit(state!, suit);
    await _repository.updateGame(_gameId, newState);
    state = newState;
  }

  Future<void> updateGame(GameState gameState) async {
    await _repository.updateGame(_gameId, gameState);
    state = gameState;
  }
}

final gameNotifierProvider =
    StateNotifierProvider.family<GameNotifier, GameState?, String>(
  (ref, gameId) {
    final repository = ref.watch(gameRepositoryProvider);
    return GameNotifier(repository, gameId);
  },
);
