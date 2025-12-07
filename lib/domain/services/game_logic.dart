import '../models/card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'deck_manager.dart';

class GameLogic {
  static bool canPlayCard(Card card, GameState gameState) {
    final topCard = gameState.topCard;
    if (topCard == null) return true;

    // If there is a pending draw penalty, only allow defensive stacking
    // Defensive stacking: playing the same penalty card (two, ace, joker)
    // to accumulate the penalty. Other plays are disallowed until penalty resolved.
    if (gameState.drawnCards != null && gameState.drawnCards! > 0) {
      // allow stacking with another two, ace, or joker
  if (card.rank == CardRank.two || card.rank == CardRank.ace || card.rank == CardRank.joker) {
        return true;
      }
      // otherwise can't play while penalty pending
      return false;
    }

    // 선택된 무늬가 있는 경우 (원카드 효과)
    if (gameState.selectedSuit != null) {
      return card.suit == gameState.selectedSuit;
    }

    // Joker can be played on any top card (wild).
    if (card.rank == CardRank.joker) return true;

    // Seven (7) can also be played on any card (allows suit change)
    if (card.rank == CardRank.seven) return true;

    // 같은 무늬 또는 같은 숫자이면 낼 수 있음
    return card.suit == topCard.suit || card.rank == topCard.rank;
  }

  static bool canPlayAnyCard(Player player, GameState gameState) {
    return player.hand.any((card) => canPlayCard(card, gameState));
  }

  static GameState playCard(
    GameState gameState,
    String playerId,
    Card card,
  ) {
    final updatedPlayers = gameState.players.map((player) {
      if (player.id == playerId) {
        final updatedHand = List<Card>.from(player.hand)..remove(card);
        return player.copyWith(hand: updatedHand);
      }
      return player;
    }).toList();

    // 승리 체크
    final currentPlayer = updatedPlayers.firstWhere((p) => p.id == playerId);
    if (currentPlayer.hand.isEmpty) {
      return gameState.copyWith(
        players: updatedPlayers,
        topCard: card,
        status: GameStatus.finished,
        winnerId: playerId,
      );
    }

    // 원카드 효과 처리
    bool newDirection = gameState.direction;
    int? drawnCards;
    CardSuit? selectedSuit;

  // 특수 카드 효과
  // When there is an existing penalty, stacking should accumulate rather than replace.
  if (card.rank == CardRank.queen) {
      // Q: 순서(방향) 변경
      newDirection = !gameState.direction;
    } else if (card.rank == CardRank.jack) {
      // J: 다음 플레이어 한 명 스킵
      // handled below by advancing nextPlayerIndex an extra time
    } else if (card.rank == CardRank.king) {
      // K: 자신이 한 번 더 플레이 (current player stays)
    } else if (card.rank == CardRank.two) {
      // 2: 다음 플레이어가 2장 뽑기 (stackable)
      drawnCards = (gameState.drawnCards ?? 0) + 2;
    } else if (card.rank == CardRank.ace) {
      // A: 다음 플레이어가 1장 뽑기 (stackable)
      drawnCards = (gameState.drawnCards ?? 0) + 1;
    } else if (card.rank == CardRank.joker) {
      // Joker: 다음 플레이어가 5장 뽑기 (stackable)
      drawnCards = (gameState.drawnCards ?? 0) + 5;
    } else if (card.rank == CardRank.seven) {
      // 7: 무늬 변경만 가능 (플레이한 플레이어가 무늬를 선택)
      selectedSuit = null;
    }

    int nextPlayerIndex = _getNextPlayerIndex(
      gameState.players,
      playerId,
      newDirection,
    );

    // Handle special next-player mechanics
    if (card.rank == CardRank.seven) {
      // For seven, keep current player as the one who must choose the suit.
      final newCurrentPlayer = updatedPlayers.firstWhere((p) => p.id == playerId);

      return gameState.copyWith(
        players: updatedPlayers.map((p) {
          return p.copyWith(isActive: p.id == newCurrentPlayer.id);
        }).toList(),
        topCard: card,
        currentPlayer: newCurrentPlayer,
        selectedSuit: selectedSuit,
        drawnCards: drawnCards,
        direction: newDirection,
      );
    }

    if (card.rank == CardRank.jack) {
      // Skip next player once
      nextPlayerIndex = _getNextPlayerIndex(
        gameState.players,
        gameState.players[nextPlayerIndex].id,
        newDirection,
      );
    }

    if (card.rank == CardRank.king) {
      // Keep turn with the same player (player plays again)
      final newCurrentPlayer = updatedPlayers.firstWhere((p) => p.id == playerId);
      return gameState.copyWith(
        players: updatedPlayers.map((p) => p.copyWith(isActive: p.id == newCurrentPlayer.id)).toList(),
        topCard: card,
        currentPlayer: newCurrentPlayer,
        selectedSuit: selectedSuit,
        drawnCards: drawnCards,
        direction: newDirection,
      );
    }

    // 현재 플레이어 업데이트
    final newCurrentPlayer = updatedPlayers[nextPlayerIndex];

    return gameState.copyWith(
      players: updatedPlayers.map((p) {
        return p.copyWith(isActive: p.id == newCurrentPlayer.id);
      }).toList(),
      topCard: card,
      currentPlayer: newCurrentPlayer,
      selectedSuit: selectedSuit,
      drawnCards: drawnCards,
      direction: newDirection,
    );
  }

  static GameState drawCard(GameState gameState, String playerId) {
    if (gameState.deck.isEmpty) {
      return gameState;
    }

    final updatedDeck = List<Card>.from(gameState.deck);

    // 강제 드로우 (여러 장 한 번에) - only if there's an actual penalty (> 0)
    if (gameState.drawnCards != null && gameState.drawnCards! > 0) {
      final count = gameState.drawnCards!;
      final drawn = DeckManager.drawCards(updatedDeck, count);

      final updatedPlayers = gameState.players.map((player) {
        if (player.id == playerId) {
          final updatedHand = List<Card>.from(player.hand)..addAll(drawn);
          return player.copyWith(hand: updatedHand);
        }
        return player;
      }).toList();

      // 벌칙 완료 후 다음 플레이어로 이동
      final nextPlayerIndex = _getNextPlayerIndex(
        gameState.players,
        playerId,
        gameState.direction,
      );
      final newCurrentPlayer = updatedPlayers[nextPlayerIndex];

      // After penalty drawing, reset drawnCards to 0 (penalty resolved)
      return gameState.copyWith(
        players: updatedPlayers.map((p) => p.copyWith(isActive: p.id == newCurrentPlayer.id)).toList(),
        currentPlayer: newCurrentPlayer,
        deck: updatedDeck,
        drawnCards: 0,
      );
    }

    // 일반 드로우 (자발적)
    final drawnCard = updatedDeck.removeAt(0);
    final updatedPlayers = gameState.players.map((player) {
      if (player.id == playerId) {
        final updatedHand = List<Card>.from(player.hand)..add(drawnCard);
        return player.copyWith(hand: updatedHand);
      }
      return player;
    }).toList();

    final canPlay = canPlayCard(drawnCard, gameState);

    if (canPlay) {
      final tempState = gameState.copyWith(
        players: updatedPlayers,
        deck: updatedDeck,
      );
      // Explicitly set drawnCards to 0 to clear any penalty
      final clearedState = GameState(
        id: tempState.id,
        players: tempState.players,
        currentPlayer: tempState.currentPlayer,
        deck: tempState.deck,
        topCard: tempState.topCard,
        status: tempState.status,
        selectedSuit: tempState.selectedSuit,
        drawnCards: 0,
        direction: tempState.direction,
        winnerId: tempState.winnerId,
      );
      return playCard(clearedState, playerId, drawnCard);
    } else {
      final nextPlayerIndex = _getNextPlayerIndex(
        gameState.players,
        playerId,
        gameState.direction,
      );
      final newCurrentPlayer = updatedPlayers[nextPlayerIndex];

      return GameState(
        id: gameState.id,
        players: updatedPlayers.map((p) {
          return p.copyWith(isActive: p.id == newCurrentPlayer.id);
        }).toList(),
        currentPlayer: newCurrentPlayer,
        deck: updatedDeck,
        topCard: gameState.topCard,
        status: gameState.status,
        selectedSuit: null,
        drawnCards: 0, // Clear any existing penalty
        direction: gameState.direction,
        winnerId: gameState.winnerId,
      );
    }
  }

  static GameState selectSuit(GameState gameState, CardSuit suit) {
    // 원카드 낸 후 무늬 선택
    final nextPlayerIndex = _getNextPlayerIndex(
      gameState.players,
      gameState.currentPlayer!.id,
      gameState.direction,
    );
    final newCurrentPlayer = gameState.players[nextPlayerIndex];

    return gameState.copyWith(
      players: gameState.players.map((p) {
        return p.copyWith(isActive: p.id == newCurrentPlayer.id);
      }).toList(),
      currentPlayer: newCurrentPlayer,
      selectedSuit: suit,
    );
  }

  static int _getNextPlayerIndex(
    List<Player> players,
    String currentPlayerId,
    bool direction,
  ) {
    final currentIndex =
        players.indexWhere((player) => player.id == currentPlayerId);
    if (currentIndex == -1) return 0;

    // 방향에 따라 다음 플레이어 결정
    if (direction) {
      return (currentIndex + 1) % players.length;
    } else {
      return (currentIndex - 1 + players.length) % players.length;
    }
  }

  static GameState initializeGame(List<String> playerNames) {
    final deck = DeckManager.createDeck();
    final players = <Player>[];

    // 각 플레이어에게 7장씩 카드 나누기
    for (var i = 0; i < playerNames.length; i++) {
      final hand = deck.take(7).toList();
      deck.removeRange(0, 7);
      players.add(Player(
        id: 'player_$i',
        name: playerNames[i],
        hand: hand,
        isActive: i == 0,
      ));
    }

    // 맨 위 카드
    final topCard = deck.removeAt(0);

    return GameState(
      id: '',
      players: players,
      currentPlayer: players[0],
      deck: deck,
      topCard: topCard,
      status: GameStatus.playing,
      direction: true,
    );
  }

  static GameState declareOneCard(GameState gameState, String playerId) {
    final updatedPlayers = gameState.players.map((player) {
      if (player.id == playerId) {
        return player.copyWith(hasDeclaredOneCard: true);
      }
      return player;
    }).toList();

    return gameState.copyWith(players: updatedPlayers);
  }
}
