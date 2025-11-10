import 'package:equatable/equatable.dart';
import 'card.dart';
import 'player.dart';

enum GameStatus {
  waiting, // 대기 중
  playing, // 플레이 중
  finished, // 게임 종료
}

class GameState extends Equatable {
  final String id;
  final List<Player> players;
  final Player? currentPlayer;
  final List<Card> deck;
  final Card? topCard; // 맨 위 카드
  final GameStatus status;
  final CardSuit? selectedSuit; // 원카드 효과로 선택된 무늬
  final int? drawnCards; // 플레이어가 뽑은 카드 수
  final bool direction; // true: 정방향, false: 역방향
  final String? winnerId;

  const GameState({
    required this.id,
    required this.players,
    this.currentPlayer,
    required this.deck,
    this.topCard,
    required this.status,
    this.selectedSuit,
    this.drawnCards,
    required this.direction,
    this.winnerId,
  });

  GameState copyWith({
    String? id,
    List<Player>? players,
    Player? currentPlayer,
    List<Card>? deck,
    Card? topCard,
    GameStatus? status,
    CardSuit? selectedSuit,
    int? drawnCards,
    bool? direction,
    String? winnerId,
  }) =>
      GameState(
        id: id ?? this.id,
        players: players ?? this.players,
        currentPlayer: currentPlayer ?? this.currentPlayer,
        deck: deck ?? this.deck,
        topCard: topCard ?? this.topCard,
        status: status ?? this.status,
        selectedSuit: selectedSuit ?? this.selectedSuit,
        drawnCards: drawnCards ?? this.drawnCards,
        direction: direction ?? this.direction,
        winnerId: winnerId ?? this.winnerId,
      );

  @override
  List<Object?> get props => [
        id,
        players,
        currentPlayer,
        deck,
        topCard,
        status,
        selectedSuit,
        drawnCards,
        direction,
        winnerId,
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'players': players.map((player) => player.toJson()).toList(),
        'currentPlayer': currentPlayer?.toJson(),
        'deck': deck.map((card) => card.toJson()).toList(),
        'topCard': topCard?.toJson(),
        'status': status.name,
        'selectedSuit': selectedSuit?.name,
        'drawnCards': drawnCards,
        'direction': direction,
        'winnerId': winnerId,
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        id: json['id'],
        players: (json['players'] as List)
            .map((playerJson) => Player.fromJson(playerJson))
            .toList(),
        currentPlayer: json['currentPlayer'] != null
            ? Player.fromJson(json['currentPlayer'])
            : null,
        deck: (json['deck'] as List)
            .map((cardJson) => Card.fromJson(cardJson))
            .toList(),
        topCard:
            json['topCard'] != null ? Card.fromJson(json['topCard']) : null,
        status: GameStatus.values.firstWhere((e) => e.name == json['status']),
        selectedSuit: json['selectedSuit'] != null
            ? CardSuit.values.firstWhere((e) => e.name == json['selectedSuit'])
            : null,
        drawnCards: json['drawnCards'],
        direction: json['direction'] ?? true,
        winnerId: json['winnerId'],
      );
}
