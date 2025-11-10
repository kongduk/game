import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/game_logic.dart';
import 'game_screen.dart';
import 'package:uuid/uuid.dart';
import '../providers/game_provider.dart';

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

    final player1Name = player1Controller.text.trim();
    final player2Name = player2Controller.text.trim();

    final gameId = const Uuid().v4();
    final gameState = GameLogic.initializeGame([player1Name, player2Name]);

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
  }

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
            ElevatedButton.icon(
              onPressed: _canStartGame ? _startGame : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('게임 시작'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),), // Add closing parenthesis for SingleChildScrollView
      ),
    );
  }
}
