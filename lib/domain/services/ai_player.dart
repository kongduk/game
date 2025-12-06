import 'dart:math';

import '../models/card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'game_logic.dart';

class AiPlayer {
  final Random _random = Random();

  // Return either a card to play or null to draw
  Card? chooseCard(Player aiPlayer, GameState gameState) {
    final playable = aiPlayer.hand.where((c) => GameLogic.canPlayCard(c, gameState)).toList();
    if (playable.isEmpty) return null;
    // Simple strategy: play highest rank value card
    playable.sort((a, b) => b.rank.value.compareTo(a.rank.value));
    return playable.first;
  }

  // Optionally a small delay to simulate thinking
  Future<void> think() async {
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(800)));
  }
}
