import 'dart:math';
import '../models/card.dart';

class DeckManager {
  static List<Card> createDeck() {
    final List<Card> deck = [];
    for (final suit in CardSuit.values) {
      for (final rank in CardRank.values) {
        // skip joker here; we'll add exactly two jokers below
        if (rank == CardRank.joker) continue;
        deck.add(Card(suit: suit, rank: rank));
      }
    }

    // Add exactly two jokers. Use clubs as a placeholder suit for display.
    deck.add(const Card(suit: CardSuit.clubs, rank: CardRank.joker));
    deck.add(const Card(suit: CardSuit.clubs, rank: CardRank.joker));
  return _shuffleDeck(deck);
  }

  static List<Card> _shuffleDeck(List<Card> deck) {
    final shuffledDeck = List<Card>.from(deck);
    final random = Random();
    for (var i = shuffledDeck.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffledDeck[i];
      shuffledDeck[i] = shuffledDeck[j];
      shuffledDeck[j] = temp;
    }
    return shuffledDeck;
  }

  static List<Card> drawCards(List<Card> deck, int count) {
    if (deck.length < count) {
      final drawnCards = List<Card>.from(deck);
      deck.clear();
      return drawnCards;
    }
    final drawnCards = deck.sublist(0, count);
    deck.removeRange(0, count);
    return drawnCards;
  }

  static Card drawCard(List<Card> deck) {
    if (deck.isEmpty) {
      throw Exception('덱에 카드가 없습니다.');
    }
    return deck.removeAt(0);
  }
}
