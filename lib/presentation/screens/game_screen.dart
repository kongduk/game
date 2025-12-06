import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/card.dart' as models;
import '../providers/game_provider.dart';

class GameScreen extends ConsumerWidget {
  final String gameId;
  final String playerId;

  const GameScreen({
    super.key,
    required this.gameId,
    required this.playerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameStateAsync = ref.watch(gameStateProvider(gameId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('원카드 게임'),
        centerTitle: true,
      ),
      body: gameStateAsync.when(
        data: (gameState) {
          if (gameState == null) {
            return const Center(child: Text('게임을 찾을 수 없습니다.'));
          }

          if (gameState.status == GameStatus.finished) {
            return _buildGameOverScreen(context, gameState);
          }

          return _buildGameBoard(context, ref, gameState);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('에러: $error')),
      ),
    );
  }

  Widget _buildGameBoard(
      BuildContext context, WidgetRef ref, GameState gameState) {
    final currentPlayer = gameState.currentPlayer;
    final myPlayer = gameState.players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => gameState.players[0],
    );
    final opponent = gameState.players.firstWhere(
      (p) => p.id != playerId,
      orElse: () => gameState.players[1],
    );
    final isMyTurn = currentPlayer?.id == playerId;

  return Column(
      children: [
        // 상대방 정보
        Expanded(
          child: _buildOpponentSection(opponent, gameState.topCard),
        ),

        // 중앙 영역 (맨 위 카드, 방향 등)
        Expanded(
          child: _buildCenterSection(gameState),
        ),

        // 내 카드 및 액션
        Expanded(
          child: _buildMyHandSection(
            context,
            ref,
            myPlayer,
            gameState,
            isMyTurn,
          ),
        ),
      ],
    );
  }

  Widget _buildOpponentSection(opponent, models.Card? topCard) {
    // Reduced height area for opponent (smaller black rectangle)
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      height: 160, // smaller fixed height
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            opponent.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '카드: ${opponent.hand.length}장',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (opponent.hasDeclaredOneCard)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '원카드!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (opponent.isActive)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '턴 진행중',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenterSection(GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (gameState.topCard != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  const BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: _buildCardWidget(gameState.topCard!),
            ),
            const SizedBox(height: 16),
          ],
          if (gameState.selectedSuit != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 8),
                  Text(
                    '선택된 무늬: ${gameState.selectedSuit!.symbol} ${gameState.selectedSuit!.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          if (gameState.drawnCards != null && gameState.drawnCards! > 0)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded),
                  const SizedBox(width: 8),
                  Text(
                    '${gameState.drawnCards}장 뽑기!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyHandSection(
    BuildContext context,
    WidgetRef ref,
    myPlayer,
    GameState gameState,
    bool isMyTurn,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                myPlayer.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '카드: ${myPlayer.hand.length}장',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Fixed-height area to show two rows (4 columns) by default (8 cards visible)
          SizedBox(
            height: 2 * (140 + 8), // approximate card height + spacing
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemCount: myPlayer.hand.length,
              itemBuilder: (context, index) {
                final card = myPlayer.hand[index];
                final canPlay = gameState.topCard != null
                    ? (card.suit == gameState.topCard!.suit ||
                        card.rank == gameState.topCard!.rank ||
                        gameState.selectedSuit == card.suit)
                    : true;

                return GestureDetector(
                  onTap: isMyTurn && canPlay
                      ? () => _playCard(context, ref, card, gameState, myPlayer)
                      : null,
                  child: Opacity(
                    opacity: (isMyTurn && canPlay) ? 1.0 : 0.5,
                    child: _buildCardWidget(card),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (isMyTurn)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _drawCard(ref, gameState, myPlayer),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('카드 뽑기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (myPlayer.hand.length == 2) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _declareOneCard(ref),
                    icon: const Icon(Icons.flag),
                    label: const Text('원카드'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardWidget(models.Card card) {
    final isRed = card.suit == models.CardSuit.hearts ||
        card.suit == models.CardSuit.diamonds;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.2),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          card.display,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isRed ? Colors.red : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverScreen(BuildContext context, GameState gameState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events,
            size: 100,
            color: Colors.amber,
          ),
          const SizedBox(height: 24),
          const Text(
            '게임 종료!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (gameState.winnerId != null)
            Text(
              '${gameState.players
                      .firstWhere((p) => p.id == gameState.winnerId)
                      .name} 승리!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home),
            label: const Text('홈으로'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playCard(BuildContext context, WidgetRef ref, models.Card card, GameState gameState, myPlayer) async {
    final gameNotifier = ref.read(gameNotifierProvider(gameId).notifier);
    final newState = await gameNotifier.playCard(playerId, card);

    // If this player played a seven, require suit selection
    if (newState != null && newState.topCard != null && newState.topCard!.rank == models.CardRank.seven) {
      // If suit not yet selected (logic sets selectedSuit null for seven), prompt player
      if (newState.selectedSuit == null && newState.currentPlayer?.id == playerId) {
        if (!context.mounted) return;
        final chosen = await showDialog<models.CardSuit?>(
          context: context,
          builder: (context) {
            return SimpleDialog(
              title: const Text('무늬를 선택하세요'),
              children: models.CardSuit.values.map((suit) {
                return SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, suit),
                  child: Text('${suit.symbol} ${suit.name}'),
                );
              }).toList(),
            );
          },
        );

        if (chosen != null) {
          await gameNotifier.selectSuit(chosen);
        }
      }
    }
  }

  Future<void> _drawCard(WidgetRef ref, GameState gameState, myPlayer) async {
    final gameNotifier = ref.read(gameNotifierProvider(gameId).notifier);
    await gameNotifier.drawCard(playerId);
  }

  Future<void> _declareOneCard(WidgetRef ref) async {
    final gameNotifier = ref.read(gameNotifierProvider(gameId).notifier);
    await gameNotifier.declareOneCard(playerId);
  }
}
