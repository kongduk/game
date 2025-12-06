import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/game_logic.dart';
import 'game_screen.dart';
import 'package:uuid/uuid.dart';
import '../providers/game_provider.dart';
import 'replay_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController player1Controller = TextEditingController();
  final TextEditingController player2Controller = TextEditingController();
  bool _canStartGame = false;

  @override
  void initState() {
    super.initState();
    player1Controller.addListener(_validateInput);
    player2Controller.addListener(_validateInput);
  player1Controller.text = 'You';
  player2Controller.text = 'AI';
  // Do not auto-start. Allow user to choose start or view replays.
  }

  @override
  void dispose() {
    player1Controller.removeListener(_validateInput);
    player2Controller.removeListener(_validateInput);
    player1Controller.dispose();
    player2Controller.dispose();
    super.dispose();
  }

  void _validateInput() {
    final canStart = player1Controller.text.trim().isNotEmpty &&
        player2Controller.text.trim().isNotEmpty;
    if (_canStartGame != canStart) {
      setState(() {
        _canStartGame = canStart;
      });
    }
  }

  Future<void> _startGame() async {
    if (!_canStartGame) return;

    // Immediate UI hint to confirm click reached the handler (debug)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start pressed (debug)'),
          duration: Duration(milliseconds: 800),
        ),
      );
    }

    final player1Name = player1Controller.text.trim();
    final player2Name = player2Controller.text.trim();
    final gameId = const Uuid().v4();
    final gameState = GameLogic.initializeGame([player1Name, player2Name]);

    try {
      final repository = ref.read(gameRepositoryProvider);
      await repository.createGame(gameState.copyWith(id: gameId));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GameScreen(gameId: gameId, playerId: 'player_0'),
          ),
        );
      }
    } catch (e) {
  // log error for debugging
  // ignore: avoid_print
  print('HomeScreen._startGame: createGame failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게임 생성에 실패했습니다: $e'),
          ),
        );
      }
    }
  }

  // auto-start removed; user will manually start or view replays

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('원카드 게임'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            const Icon(
              Icons.casino,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 40),
            const Text(
              '게임 시작',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: player1Controller,
              decoration: const InputDecoration(
                labelText: '플레이어 1 이름',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: player2Controller,
              decoration: const InputDecoration(
                labelText: '플레이어 2 이름',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _canStartGame ? _startGame : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('게임 시작'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReplayListScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('다시보기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),), // Add closing parenthesis for SingleChildScrollView
      ),
    );
  }
}
