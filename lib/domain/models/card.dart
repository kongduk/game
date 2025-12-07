import 'package:equatable/equatable.dart';

enum CardSuit {
  spades,
  hearts,
  diamonds,
  clubs,
}

enum CardColor {
  black,
  red,
}

extension CardSuitExtension on CardSuit {
  CardColor get color {
    switch (this) {
      case CardSuit.spades:
      case CardSuit.clubs:
        return CardColor.black;
      case CardSuit.hearts:
      case CardSuit.diamonds:
        return CardColor.red;
    }
  }

  String get symbol {
    switch (this) {
      case CardSuit.spades:
        return '♠';
      case CardSuit.hearts:
        return '♥';
      case CardSuit.diamonds:
        return '♦';
      case CardSuit.clubs:
        return '♣';
    }
  }
}

enum CardRank {
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  joker,
}

extension CardRankExtension on CardRank {
  int get value {
    switch (this) {
      case CardRank.ace:
        return 1;
      case CardRank.two:
        return 2;
      case CardRank.three:
        return 3;
      case CardRank.four:
        return 4;
      case CardRank.five:
        return 5;
      case CardRank.six:
        return 6;
      case CardRank.seven:
        return 7;
      case CardRank.eight:
        return 8;
      case CardRank.nine:
        return 9;
      case CardRank.ten:
        return 10;
      case CardRank.jack:
        return 11;
      case CardRank.queen:
        return 12;
      case CardRank.king:
        return 13;
      case CardRank.joker:
        return 0;
    }
  }

  String get display {
    switch (this) {
      case CardRank.ace:
        return 'A';
      case CardRank.two:
        return '2';
      case CardRank.three:
        return '3';
      case CardRank.four:
        return '4';
      case CardRank.five:
        return '5';
      case CardRank.six:
        return '6';
      case CardRank.seven:
        return '7';
      case CardRank.eight:
        return '8';
      case CardRank.nine:
        return '9';
      case CardRank.ten:
        return '10';
      case CardRank.jack:
        return 'J';
      case CardRank.queen:
        return 'Q';
      case CardRank.king:
        return 'K';
      case CardRank.joker:
        // Joker should display without a suit symbol
        return 'JOK';
    }
  }
}

class Card extends Equatable {
  final CardSuit suit;
  final CardRank rank;

  const Card({
    required this.suit,
    required this.rank,
  });

  String get display {
    // Joker should not display suit symbol
    if (rank == CardRank.joker) return rank.display;
    return '${rank.display}${suit.symbol}';
  }

  @override
  List<Object?> get props => [suit, rank];

  Map<String, dynamic> toJson() => {
        'suit': suit.name,
        'rank': rank.name,
      };

  factory Card.fromJson(Map<String, dynamic> json) => Card(
        suit: CardSuit.values.firstWhere((e) => e.name == json['suit']),
        rank: CardRank.values.firstWhere((e) => e.name == json['rank']),
      );
}
