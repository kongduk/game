import 'package:equatable/equatable.dart';
import 'card.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final List<Card> hand;
  final bool isActive;

  const Player({
    required this.id,
    required this.name,
    required this.hand,
    required this.isActive,
  });

  Player copyWith({
    String? id,
    String? name,
    List<Card>? hand,
    bool? isActive, required bool hasDeclaredOneCard,
  }) =>
      Player(
        id: id ?? this.id,
        name: name ?? this.name,
        hand: hand ?? this.hand,
        isActive: isActive ?? this.isActive,
      );

  bool get hasWon => hand.isEmpty;

  @override
  List<Object?> get props => [id, name, hand, isActive];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hand': hand.map((card) => card.toJson()).toList(),
        'isActive': isActive,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'],
        name: json['name'],
        hand: (json['hand'] as List)
            .map((cardJson) => Card.fromJson(cardJson))
            .toList(),
        isActive: json['isActive'] ?? false,
      );
}
