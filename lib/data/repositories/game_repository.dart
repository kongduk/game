import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/game_state.dart';

class GameRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'games';

  Future<String> createGame(GameState gameState) async {
    final docRef =
        await _firestore.collection(_collectionName).add(gameState.toJson());
    return docRef.id;
  }

  Future<void> updateGame(String gameId, GameState gameState) async {
    await _firestore
        .collection(_collectionName)
        .doc(gameId)
        .update(gameState.toJson());
  }

  Stream<GameState?> watchGame(String gameId) {
    return _firestore
        .collection(_collectionName)
        .doc(gameId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return GameState.fromJson({
        'id': snapshot.id,
        ...snapshot.data()!,
      });
    });
  }

  Future<GameState?> getGame(String gameId) async {
    final doc = await _firestore.collection(_collectionName).doc(gameId).get();
    if (!doc.exists) return null;
    return GameState.fromJson({
      'id': doc.id,
      ...doc.data()!,
    });
  }

  Future<void> deleteGame(String gameId) async {
    await _firestore.collection(_collectionName).doc(gameId).delete();
  }

  Stream<List<GameState>> watchAvailableGames() {
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GameState.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    });
  }
}
