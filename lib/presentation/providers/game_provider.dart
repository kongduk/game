import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/card.dart';
import '../../data/repositories/game_repository.dart';
import '../../domain/services/game_logic.dart';
import '../../domain/services/ai_player.dart';

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
  final AiPlayer _ai = AiPlayer();
  bool _busy = false;

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

  Future<GameState?> playCard(String playerId, Card card) async {
    if (state == null) return null;
    if (_busy) return null;
    // If there's a pending draw penalty, only allow stacking defensive cards
    if (state!.drawnCards != null && state!.drawnCards! > 0) {
      if (!(card.rank == CardRank.two || card.rank == CardRank.ace || card.rank == CardRank.joker)) {
        // Not allowed to play non-defensive card while penalty pending
        return null;
      }
    }
    _busy = true;
    try {
      final newState = GameLogic.playCard(state!, playerId, card);
      await _repository.updateGame(_gameId, newState);
      state = newState;

      // if next player is AI, let AI play
      await _maybeRunAi();
      return newState;
    } finally {
      _busy = false;
    }
  }

  Future<void> drawCard(String playerId) async {
    if (state == null) return;
    if (_busy) return;
    _busy = true;
    try {
      var newState = GameLogic.drawCard(state!, playerId);
      // Force drawnCards to 0 to clear any penalty (using 0 instead of null because copyWith preserves null)
      newState = newState.copyWith(drawnCards: 0);
      await _repository.updateGame(_gameId, newState);
      state = newState;

      // if next player is AI, let AI play
      await _maybeRunAi();
    } finally {
      _busy = false;
    }
  }

  Future<void> _maybeRunAi() async {
    if (state == null) return;
    final current = state!.currentPlayer;
    if (current == null) return;
    if (current.name != 'AI') return;

    // AI thinking and move loop until it's human's turn
    while (state != null && state!.currentPlayer != null && state!.currentPlayer!.name == 'AI') {
      await _ai.think();
      final aiPlayer = state!.players.firstWhere((p) => p.name == 'AI');
      final choice = _ai.chooseCard(aiPlayer, state!);
      if (choice != null) {
        final newState = GameLogic.playCard(state!, aiPlayer.id, choice);
        await _repository.updateGame(_gameId, newState);
        state = newState;
      } else {
        var newState = GameLogic.drawCard(state!, aiPlayer.id);
        // Force drawnCards to 0 to clear penalty (using 0 instead of null)
        newState = newState.copyWith(drawnCards: 0);
        await _repository.updateGame(_gameId, newState);
        state = newState;
      }
    }
  }

  Future<void> selectSuit(CardSuit suit) async {
    if (state == null) return;

    final newState = GameLogic.selectSuit(state!, suit);
    await _repository.updateGame(_gameId, newState);
    state = newState;
  // After selecting suit, if it's AI's turn, let AI run
  await _maybeRunAi();
  }

  Future<void> updateGame(GameState gameState) async {
    await _repository.updateGame(_gameId, gameState);
    state = gameState;
  }

  Future<void> declareOneCard(String playerId) async {
    if (state == null) return;

    final newState = GameLogic.declareOneCard(state!, playerId);
    await _repository.updateGame(_gameId, newState);
    state = newState;
  }
}

final gameNotifierProvider =
    StateNotifierProvider.family<GameNotifier, GameState?, String>(
  (ref, gameId) {
    final repository = ref.watch(gameRepositoryProvider);
    return GameNotifier(repository, gameId);
  },
);
