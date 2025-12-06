import 'package:flutter/material.dart';
import '../../data/datasources/sqlite_game_datasource.dart';
import 'dart:convert';

class ReplayViewerScreen extends StatefulWidget {
  final String gameId;
  const ReplayViewerScreen({super.key, required this.gameId});

  @override
  State<ReplayViewerScreen> createState() => _ReplayViewerScreenState();
}

class _ReplayViewerScreenState extends State<ReplayViewerScreen> {
  final SqliteGameDataSource _datasource = SqliteGameDataSource();
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _datasource.loadGameHistory(widget.gameId);
  }

  @override
  void dispose() {
    _datasource.close();
    super.dispose();
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
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final row = rows[index];
              final json = jsonDecode(row['json'] as String) as Map<String, dynamic>;
              final ts = DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int);
              return ListTile(
                title: Text('상태 ${index + 1} - ${ts.toLocal()}'),
                subtitle: Text('간단 요약: 플레이어 수: \\${(json['players'] as List).length}'),
                onTap: () {
                  // For now show full JSON in a dialog
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('상태 ${index + 1} - ${ts.toLocal()}'),
                      content: SingleChildScrollView(child: Text(const JsonEncoder.withIndent('  ').convert(json))),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
