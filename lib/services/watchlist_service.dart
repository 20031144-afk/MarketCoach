import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing user's watchlist in Firestore
class WatchlistService {
  final FirebaseFirestore _db;
  final String userId;

  WatchlistService(this._db, {required this.userId});

  /// Check if a symbol is in the watchlist
  Future<bool> isInWatchlist(String symbol) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('watchlist')
          .doc(symbol)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking watchlist: $e');
      return false;
    }
  }

  /// Add a symbol to the watchlist
  Future<void> addToWatchlist(String symbol) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('watchlist')
          .doc(symbol)
          .set({
        'symbol': symbol,
        'added_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding to watchlist: $e');
      rethrow;
    }
  }

  /// Remove a symbol from the watchlist
  Future<void> removeFromWatchlist(String symbol) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('watchlist')
          .doc(symbol)
          .delete();
    } catch (e) {
      print('Error removing from watchlist: $e');
      rethrow;
    }
  }

  /// Toggle watchlist status
  Future<bool> toggleWatchlist(String symbol) async {
    final isInList = await isInWatchlist(symbol);

    if (isInList) {
      await removeFromWatchlist(symbol);
      return false;
    } else {
      await addToWatchlist(symbol);
      return true;
    }
  }

  /// Stream to watch if a symbol is in the watchlist
  Stream<bool> watchSymbol(String symbol) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('watchlist')
        .doc(symbol)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }
}
