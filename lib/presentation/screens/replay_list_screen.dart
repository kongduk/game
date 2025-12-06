import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/sqlite_game_datasource.dart';
import '../../domain/models/game_state.dart';
import 'replay_viewer_screen.dart';

class ReplayListScreen extends ConsumerStatefulWidget {
  const ReplayListScreen({super.key});

  @override
  ConsumerState<ReplayListScreen> createState() => _ReplayListScreenState();
}

class _ReplayListScreenState extends ConsumerState<ReplayListScreen> {
  final SqliteGameDataSource _datasource = SqliteGameDataSource();
  late Future<List<GameState>> _gamesFuture;

  @override
  void initState() {
    super.initState();
    _gamesFuture = _datasource.listGames();
  }

  @override
  void dispose() {
    _datasource.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('다시보기'),
      ),
      body: FutureBuilder<List<GameState>>(
        future: _gamesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('저장된 경기가 없습니다.'));
          }

          final games = snapshot.data!;
          return ListView.separated(
            itemCount: games.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final g = games[index];
              return ListTile(
                title: Text('경기 ${index + 1} - ${g.id.substring(0, 8)}'),
                subtitle: Text('플레이어: ${g.players.map((p) => p.name).join(', ')}'),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReplayViewerScreen(gameId: g.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
