import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson.dart';
import '../models/lesson_screen.dart';
import '../models/lesson_progress.dart';

/// Service for all Firestore database operations.
///
/// Provides methods for:
/// - Learning content (lessons, lesson screens)
/// - Market data (stocks, indices)
/// - User progress tracking
/// - Lesson bookmarking
///
/// All methods throw [Exception] on failure for proper error propagation.
/// Use try-catch blocks when calling these methods.
class FirestoreService {
  FirestoreService(this._db);
  final FirebaseFirestore _db;

  Future<void> addLearning({
    required String title,
    required String summary,
    required String category,
    required String level,
    List<String> tags = const [],
    int durationMinutes = 0,
    Map<String, dynamic> content = const {},
    DateTime? publishedAt,
  }) {
    return _db.collection('learning').add({
      'title': title,
      'summary': summary,
      'category': category,
      'level': level,
      'tags': tags,
      'duration_minutes': durationMinutes,
      'published_at': publishedAt ?? DateTime.now(),
      'content': content,
    });
  }

  Future<void> addMarketData({
    required String symbol,
    required String name,
    required String exchange,
    required String sector,
    required double price,
    required double changePct,
    required double marketCap,
    required double peRatio,
    DateTime? lastUpdated,
    Map<String, dynamic> metadata = const {},
  }) {
    return _db.collection('market_data').doc(symbol).set({
      'symbol': symbol,
      'name': name,
      'exchange': exchange,
      'sector': sector,
      'price': price,
      'change_pct': changePct,
      'market_cap': marketCap,
      'pe_ratio': peRatio,
      'last_updated': lastUpdated ?? DateTime.now(),
      'metadata': metadata,
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> learningStream() => _db
      .collection('learning')
      .orderBy('published_at', descending: true)
      .snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> marketDataStream(
    String symbol,
  ) => _db.collection('market_data').doc(symbol).snapshots();

  /// Fetches a single lesson by ID.
  ///
  /// Returns `null` if the lesson doesn't exist.
  /// Throws [Exception] if the fetch operation fails.
  Future<Lesson?> fetchLesson(String lessonId) async {
    try {
      final doc = await _db.collection('lessons').doc(lessonId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return Lesson.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch lesson $lessonId: $e');
    }
  }

  /// Fetches all screens for a lesson, ordered by the `order` field.
  ///
  /// Returns an empty list if no screens exist.
  /// Throws [Exception] if the fetch operation fails.
  Future<List<LessonScreen>> fetchLessonScreens(String lessonId) async {
    try {
      final snapshot = await _db
          .collection('lessons')
          .doc(lessonId)
          .collection('screens')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => LessonScreen.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch lesson screens for $lessonId: $e');
    }
  }

  // ============ Lesson Progress Tracking ============

  /// Fetch progress for a single lesson
  Future<LessonProgress?> fetchLessonProgress(
    String userId,
    String lessonId,
  ) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('lesson_progress')
          .doc(lessonId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return LessonProgress.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch lesson progress: $e');
    }
  }

  /// Update progress when user navigates between screens
  Future<void> updateLessonProgress({
    required String userId,
    required String lessonId,
    required int currentScreen,
    required int totalScreens,
    bool completed = false,
  }) async {
    try {
      final progressRef = _db
          .collection('users')
          .doc(userId)
          .collection('lesson_progress')
          .doc(lessonId);

      final data = {
        'lesson_id': lessonId,
        'user_id': userId,
        'current_screen': currentScreen,
        'total_screens': totalScreens,
        'completed': completed,
        'last_accessed_at': FieldValue.serverTimestamp(),
      };

      if (completed) {
        data['completed_at'] = FieldValue.serverTimestamp();
      }

      await progressRef.set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update lesson progress: $e');
    }
  }

  /// Mark lesson as complete
  Future<void> markLessonComplete(String userId, String lessonId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('lesson_progress')
          .doc(lessonId)
          .set({
        'completed': true,
        'completed_at': FieldValue.serverTimestamp(),
        'last_accessed_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to mark lesson complete: $e');
    }
  }

  /// Stream all progress for a user (for list view)
  Stream<List<LessonProgress>> userProgressStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('lesson_progress')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LessonProgress.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get progress for multiple lessons at once (batch fetch)
  Future<Map<String, LessonProgress>> batchFetchProgress(
    String userId,
    List<String> lessonIds,
  ) async {
    try {
      final result = <String, LessonProgress>{};

      // Firestore has a limit of 10 documents per getAll, so we batch
      for (var i = 0; i < lessonIds.length; i += 10) {
        final batch = lessonIds.skip(i).take(10).toList();
        final docs = await Future.wait(
          batch.map((id) => _db
              .collection('users')
              .doc(userId)
              .collection('lesson_progress')
              .doc(id)
              .get()),
        );

        for (final doc in docs) {
          if (doc.exists && doc.data() != null) {
            result[doc.id] = LessonProgress.fromMap(doc.data()!, doc.id);
          }
        }
      }

      return result;
    } catch (e) {
      throw Exception('Failed to batch fetch lesson progress: $e');
    }
  }

  // ============ Lesson Bookmarking ============

  /// Bookmark a lesson for the user
  Future<void> bookmarkLesson(String userId, String lessonId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(lessonId)
          .set({
        'lesson_id': lessonId,
        'user_id': userId,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to bookmark lesson: $e');
    }
  }

  /// Remove bookmark for a lesson
  Future<void> unbookmarkLesson(String userId, String lessonId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(lessonId)
          .delete();
    } catch (e) {
      throw Exception('Failed to unbookmark lesson: $e');
    }
  }

  /// Stream of bookmarked lesson IDs for a user
  Stream<List<String>> bookmarkedLessonsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Check if a lesson is bookmarked
  Future<bool> isLessonBookmarked(String userId, String lessonId) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(lessonId)
          .get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check bookmark status: $e');
    }
  }
}
