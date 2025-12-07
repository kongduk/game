import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/card.dart' as models;
import '../providers/game_provider.dart';

/// Clean GameScreen: reduced opponent area and responsive two-row player hand.
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
      appBar: AppBar(title: const Text('원카드 게임'), centerTitle: true),
      body: SafeArea(
        child: gameStateAsync.when(
        data: (gameState) {
          if (gameState == null) return const Center(child: Text('게임을 찾을 수 없습니다.'));
          if (gameState.status == GameStatus.finished) return _buildGameOverScreen(context, gameState);
          return _buildGameBoard(context, ref, gameState);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('에러: $e')),
        ),
      ),
    );
  }

  Widget _buildGameBoard(BuildContext context, WidgetRef ref, GameState gameState) {
    final currentPlayer = gameState.currentPlayer;
    final myPlayer = gameState.players.firstWhere((p) => p.id == playerId, orElse: () => gameState.players[0]);
    final opponent = gameState.players.firstWhere((p) => p.id != playerId, orElse: () => gameState.players[1]);
    final isMyTurn = currentPlayer?.id == playerId;

    return LayoutBuilder(builder: (context, constraints) {
      final totalHeight = constraints.maxHeight;
      final opponentHeight = 110.0;
      // Reserve proportions: center ~40%, hand ~ remaining
      final centerHeight = (totalHeight - opponentHeight) * 0.45;
      final handHeight = totalHeight - opponentHeight - centerHeight;

      return Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(height: opponentHeight, child: _buildOpponentSection(opponent)),
          SizedBox(height: centerHeight, child: _buildCenterSection(context, ref, gameState)),
          SizedBox(height: handHeight, child: _buildMyHandSection(context, ref, myPlayer, gameState, isMyTurn)),
        ],
      );
    });
  }

  Widget _buildOpponentSection(opponent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      height: 110,
      decoration: BoxDecoration(color: Colors.grey[850], borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(opponent.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('카드: ${opponent.hand.length}장', style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ]),
    );
  }

  Widget _buildCenterSection(BuildContext context, WidgetRef ref, GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (gameState.topCard != null) ...[
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(12)), child: _buildCardWidget(gameState.topCard!)),
          const SizedBox(height: 12),
        ],
        if (gameState.selectedSuit != null) Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(8)), child: Text('선택된 무늬: ${gameState.selectedSuit!.symbol} ${gameState.selectedSuit!.name}', style: const TextStyle(fontWeight: FontWeight.bold))),
        if (gameState.drawnCards != null && gameState.drawnCards! > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: gameState.currentPlayer?.id == playerId
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[100], foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
                    onPressed: () => _drawCard(ref, gameState, gameState.currentPlayer?.id),
                    child: Text('${gameState.drawnCards}장 뽑기!', style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                : Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(8)), child: Text('${gameState.drawnCards}장 뽑기!', style: const TextStyle(fontWeight: FontWeight.bold))),
          ),
      ]),
    );
  }

  Widget _buildMyHandSection(BuildContext context, WidgetRef ref, myPlayer, GameState gameState, bool isMyTurn) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(myPlayer.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), Text('카드: ${myPlayer.hand.length}장', style: const TextStyle(fontSize: 13))]),
        const SizedBox(height: 3),

        LayoutBuilder(builder: (context, constraints) {
          final columns = 4;
          final spacing = 6.0;
          final itemWidth = (constraints.maxWidth - (columns - 1) * spacing) / columns;
          final itemHeight = itemWidth / 0.7; // aspect ratio adjusted for less height
          final rowsVisible = 2;
          final gridHeight = itemHeight * rowsVisible + spacing * (rowsVisible - 1);
          final childAspect = itemWidth / itemHeight;

          return SizedBox(
            height: gridHeight,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: spacing, mainAxisSpacing: spacing, childAspectRatio: childAspect),
              itemCount: myPlayer.hand.length,
              itemBuilder: (context, index) {
                final card = myPlayer.hand[index];
                final canPlay = gameState.topCard != null ? (card.suit == gameState.topCard!.suit || card.rank == gameState.topCard!.rank || gameState.selectedSuit == card.suit) : true;
                return GestureDetector(onTap: isMyTurn && canPlay ? () => _playCard(context, ref, card, gameState, myPlayer) : null, child: Opacity(opacity: (isMyTurn && canPlay) ? 1.0 : 0.5, child: _buildCardWidget(card)));
              },
            ),
          );
        }),

        const SizedBox(height: 4),
        if (isMyTurn)
          Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: () => _drawCard(ref, gameState, myPlayer.id), icon: const Icon(Icons.add_circle_outline, size: 18), label: const Text('카드 뽑기', style: TextStyle(fontSize: 13)), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)))),
            if (myPlayer.hand.length == 2) ...[const SizedBox(width: 6), Expanded(child: ElevatedButton.icon(onPressed: () => _declareOneCard(ref), icon: const Icon(Icons.flag, size: 18), label: const Text('원카드', style: TextStyle(fontSize: 13)), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 6))))]
          ])
      ]),
    );
  }

  Widget _buildCardWidget(models.Card card) {
    final isRed = card.suit == models.CardSuit.hearts || card.suit == models.CardSuit.diamonds;
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.2), blurRadius: 4, offset: Offset(0, 2))]),
      child: Center(child: Text(card.display, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isRed ? Colors.red : Colors.black))),
    );
  }

  Widget _buildGameOverScreen(BuildContext context, GameState gameState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
          const SizedBox(height: 20),
          const Text('게임 종료!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          if (gameState.winnerId != null)
            Text(
              '${gameState.players.firstWhere((p) => p.id == gameState.winnerId).name} 승리!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.home), label: const Text('홈으로')),
        ],
      ),
    );
  }

  Future<void> _playCard(BuildContext context, WidgetRef ref, models.Card card, GameState gameState, myPlayer) async {
    final gameNotifier = ref.read(gameNotifierProvider(gameId).notifier);
    final newState = await gameNotifier.playCard(playerId, card);
    if (newState != null && newState.topCard != null && newState.topCard!.rank == models.CardRank.seven) {
      if (newState.selectedSuit == null && newState.currentPlayer?.id == playerId) {
        if (!context.mounted) return;
        final chosen = await showDialog<models.CardSuit?>(
          context: context,
          builder: (c) => SimpleDialog(
            title: const Text('무늬를 선택하세요'),
            children: models.CardSuit.values.map((s) => SimpleDialogOption(onPressed: () => Navigator.pop(c, s), child: Text('${s.symbol} ${s.name}'))).toList(),
          ),
        );
        if (chosen != null) await gameNotifier.selectSuit(chosen);
      }
    }
  }

  Future<void> _drawCard(WidgetRef ref, GameState gameState, String? targetPlayerId) async {
    final gameNotifier = ref.read(gameNotifierProvider(gameId).notifier);
    final id = targetPlayerId ?? playerId;
    await gameNotifier.drawCard(id);
  }

  Future<void> _declareOneCard(WidgetRef ref) async {
    final gameNotifier = ref.read(gameNotifierProvider(gameId).notifier);
    await gameNotifier.declareOneCard(playerId);
  }
}
