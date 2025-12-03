import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/game_state.dart';
import '../datasources/local_game_datasource.dart';

class GameRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalGameDataSource _local = LocalGameDataSource();
  static const String _collectionName = 'games';

  Future<String> createGame(GameState gameState) async {
    try {
      final docRef =
          await _firestore.collection(_collectionName).add(gameState.toJson());
      // save local copy
      await _local.saveGame(gameState.copyWith(id: docRef.id));
      return docRef.id;
    } catch (_) {
      // log error for debugging
      try {
        // Can't assume _ has toString, so capture
        debugPrint('GameRepository.createGame: Firestore add failed: ' + _.toString());
      } catch (e) {
        // ignore
      }
      // fallback: save locally and return a generated id
      await _local.saveGame(gameState);
      return gameState.id;
    }
  }

  Future<void> updateGame(String gameId, GameState gameState) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(gameId)
          .update(gameState.toJson());
      await _local.saveGame(gameState.copyWith(id: gameId));
    } catch (_) {
      // still save locally
      await _local.saveGame(gameState.copyWith(id: gameId));
    }
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
    try {
      final doc = await _firestore.collection(_collectionName).doc(gameId).get();
      if (!doc.exists) return null;
      final game = GameState.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
      // save locally
      await _local.saveGame(game);
      return game;
    } catch (_) {
      // fallback to local
      return await _local.loadGame();
    }
  }

  Future<void> deleteGame(String gameId) async {
    try {
      await _firestore.collection(_collectionName).doc(gameId).delete();
    } catch (_) {}
    await _local.deleteSavedGame();
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
