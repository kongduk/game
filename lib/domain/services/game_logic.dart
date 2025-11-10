import '../models/card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'deck_manager.dart';

class GameLogic {
  static bool canPlayCard(Card card, GameState gameState) {
    final topCard = gameState.topCard;
    if (topCard == null) return true;

    // 선택된 무늬가 있는 경우 (원카드 효과)
    if (gameState.selectedSuit != null) {
      return card.suit == gameState.selectedSuit;
    }

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
    if (card.rank == CardRank.jack) {
      // J: 방향 변경
      newDirection = !gameState.direction;
    } else if (card.rank == CardRank.ace) {
      // A: 다음 플레이어 넘기기 (방향 전환 후 계산 필요)
    } else if (card.rank == CardRank.seven) {
      // 7: 다음 플레이어 2장 뽑기
      drawnCards = 2;
    }

    int nextPlayerIndex = _getNextPlayerIndex(
      gameState.players,
      playerId,
      newDirection,
    );

    if (card.rank == CardRank.ace) {
      // A 효과로 다음 플레이어를 한 번 더 건너뜁니다.
      nextPlayerIndex = _getNextPlayerIndex(
        gameState.players,
        gameState.players[nextPlayerIndex].id,
        newDirection,
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
    final drawnCard = updatedDeck.removeAt(0);

    final updatedPlayers = gameState.players.map((player) {
      if (player.id == playerId) {
        final updatedHand = List<Card>.from(player.hand)..add(drawnCard);
        return player.copyWith(hand: updatedHand);
      }
      return player;
    }).toList();

    // 강제 드로우 (7카드 효과)
    if (gameState.drawnCards != null) {
      final remainingDraws = gameState.drawnCards! - 1;
      if (remainingDraws > 0) {
        // 아직 더 뽑아야 할 카드가 남음
        return gameState.copyWith(
          players: updatedPlayers,
          deck: updatedDeck,
          drawnCards: remainingDraws,
        );
      } else {
        // 벌칙으로 뽑는 마지막 카드. 턴이 다음 플레이어에게 넘어감
        final nextPlayerIndex = _getNextPlayerIndex(
          gameState.players,
          playerId,
          gameState.direction,
        );
        final newCurrentPlayer = updatedPlayers[nextPlayerIndex];

        return gameState.copyWith(
          players: updatedPlayers.map((p) {
            return p.copyWith(isActive: p.id == newCurrentPlayer.id);
          }).toList(),
          currentPlayer: newCurrentPlayer,
          deck: updatedDeck,
          drawnCards: null, // 벌칙 종료
        );
      }
    }

    // 자발적 드로우
    final canPlay = canPlayCard(drawnCard, gameState);

    if (canPlay) {
      // 뽑은 카드를 자동으로 냄
      final tempState = gameState.copyWith(
        players: updatedPlayers,
        deck: updatedDeck,
      );
      return playCard(tempState, playerId, drawnCard);
    } else {
      // 낼 수 없으면 턴이 다음 플레이어에게 넘어감
      final nextPlayerIndex = _getNextPlayerIndex(
        gameState.players,
        playerId,
        gameState.direction,
      );
      final newCurrentPlayer = updatedPlayers[nextPlayerIndex];

      return gameState.copyWith(
        players: updatedPlayers.map((p) {
          return p.copyWith(isActive: p.id == newCurrentPlayer.id);
        }).toList(),
        currentPlayer: newCurrentPlayer,
        deck: updatedDeck,
        selectedSuit: null,
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
