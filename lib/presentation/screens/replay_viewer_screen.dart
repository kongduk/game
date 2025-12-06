import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../data/datasources/sqlite_game_datasource.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/card.dart' as models;

class ReplayViewerScreen extends StatefulWidget {
  final String gameId;
  const ReplayViewerScreen({super.key, required this.gameId});

  @override
  State<ReplayViewerScreen> createState() => _ReplayViewerScreenState();
}

class _ReplayViewerScreenState extends State<ReplayViewerScreen> {
  final SqliteGameDataSource _datasource = SqliteGameDataSource();
  late Future<List<Map<String, dynamic>>> _historyFuture;

  int _currentIndex = 0;
  Timer? _playTimer;
  Duration _interval = const Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _historyFuture = _datasource.loadGameHistory(widget.gameId);
  }

  Widget _cardPill(models.Card card) {
    final isRed = card.suit == models.CardSuit.hearts || card.suit == models.CardSuit.diamonds;
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        card.display,
        style: TextStyle(color: isRed ? Colors.red : Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _startAutoPlay(int total) {
    _playTimer?.cancel();
    _playTimer = Timer.periodic(_interval, (_) {
      if (!mounted) return;
      setState(() {
        if (_currentIndex < total - 1) {
          _currentIndex++;
        } else {
          _playTimer?.cancel();
        }
      });
    });
  }

  void _stopAutoPlay() {
    _playTimer?.cancel();
    _playTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('재생보기')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('재생 기록이 없습니다.'));
          }

          final rows = snapshot.data!;

          // parse rows into GameState list
          final states = rows.map((r) {
            final json = jsonDecode(r['json'] as String) as Map<String, dynamic>;
            return GameState.fromJson(json);
          }).toList();

          // clamp current index
          if (_currentIndex >= states.length) _currentIndex = states.length - 1;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: states.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final state = states[index];
                    final prev = index > 0 ? states[index - 1] : null;
                    final ts = DateTime.fromMillisecondsSinceEpoch(rows[index]['created_at'] as int);

                    // for each player, compute which cards were played since prev
                    final playerWidgets = state.players.map((p) {
                      final prevPlayer = prev?.players.firstWhere((pp) => pp.id == p.id, orElse: () => p);
                      final prevHand = prevPlayer?.hand ?? [];
                      final currentHand = p.hand;
                      final played = <models.Card>[];
                      for (final c in prevHand) {
                        if (!currentHand.any((cc) => cc == c)) played.add(c);
                      }

                      final label = (p.name == 'You') ? 'You' : (p.name == 'AI' ? 'AI' : p.name);

                      return Row(
                        children: [
                          SizedBox(width: 72, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
                          if (played.isNotEmpty)
                            Row(children: played.map((c) => _cardPill(c)).toList())
                          else
                            const Text('-'),
                          const SizedBox(width: 12),
                          Text('손: ${currentHand.length}장'),
                        ],
                      );
                    }).toList();

                    final isSelected = index == _currentIndex;

                    return Container(
                      color: isSelected ? Colors.blue.shade50 : null,
                      child: ListTile(
                        title: Text('상태 ${index + 1} - ${ts.toLocal()}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            ...playerWidgets.map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: w)),
                          ],
                        ),
                        onTap: () {
                          setState(() => _currentIndex = index);
                        },
                      ),
                    );
                  },
                ),
              ),

              // playback controls
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: '이전',
                      icon: const Icon(Icons.skip_previous),
                      onPressed: () {
                        setState(() {
                          _stopAutoPlay();
                          if (_currentIndex > 0) _currentIndex--;
                        });
                      },
                    ),
                    IconButton(
                      tooltip: _playTimer == null || !_playTimer!.isActive ? '재생' : '일시정지',
                      icon: Icon(_playTimer == null || !_playTimer!.isActive ? Icons.play_arrow : Icons.pause),
                      onPressed: () {
                        setState(() {
                          if (_playTimer == null || !_playTimer!.isActive) {
                            _startAutoPlay(states.length);
                          } else {
                            _stopAutoPlay();
                          }
                        });
                      },
                    ),
                    IconButton(
                      tooltip: '다음',
                      icon: const Icon(Icons.skip_next),
                      onPressed: () {
                        setState(() {
                          _stopAutoPlay();
                          if (_currentIndex < states.length - 1) _currentIndex++;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    const Text('속도:'),
                    Expanded(
                      child: Slider(
                        value: _interval.inMilliseconds.toDouble(),
                        min: 300,
                        max: 3000,
                        divisions: 9,
                        label: '${_interval.inMilliseconds}ms',
                        onChanged: (v) {
                          setState(() {
                            _interval = Duration(milliseconds: v.round());
                            if (_playTimer != null && _playTimer!.isActive) {
                              // restart timer with new interval
                              _startAutoPlay(states.length);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${_currentIndex + 1}/${states.length}'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _datasource.close();
    super.dispose();
  }
}
