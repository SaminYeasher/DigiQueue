import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queue_model.dart';
import '../models/token_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Collection References ───────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _queuesRef =>
      _db.collection('queues');

  CollectionReference<Map<String, dynamic>> get _tokensRef =>
      _db.collection('tokens');

  // ─── Queue Streams ───────────────────────────────────────────────

  /// Stream all queues, ordered by professorName
  Stream<List<QueueModel>> streamAllQueues() {
    return _queuesRef
        .orderBy('professorName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QueueModel.fromFirestore(doc))
            .toList());
  }

  /// Stream a single queue by ID
  Stream<QueueModel?> streamQueue(String queueId) {
    return _queuesRef.doc(queueId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return QueueModel.fromFirestore(doc);
    });
  }

  // ─── Queue Mutations ────────────────────────────────────────────

  /// Create a new queue (professor self-service)
  Future<String> createQueue({
    required String professorName,
    required String roomNumber,
    required String professorId,
  }) async {
    final docRef = await _queuesRef.add({
      'professorName': professorName,
      'roomNumber': roomNumber,
      'isLive': false,
      'currentServing': 0,
      'lastIssuedToken': 0,
      'professorId': professorId,
    });
    return docRef.id;
  }

  /// Toggle queue live/closed status
  Future<void> toggleQueueLive(String queueId, bool isLive) {
    return _queuesRef.doc(queueId).update({'isLive': isLive});
  }

  /// Reset queue counters (for a new session)
  Future<void> resetQueue(String queueId) {
    return _queuesRef.doc(queueId).update({
      'currentServing': 0,
      'lastIssuedToken': 0,
      'isLive': false,
    });
  }

  /// Delete a queue and all its tokens
  Future<void> deleteQueue(String queueId) async {
    // Delete all tokens for this queue
    final tokens = await _tokensRef
        .where('queueId', isEqualTo: queueId)
        .get();
    final batch = _db.batch();
    for (final doc in tokens.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_queuesRef.doc(queueId));
    await batch.commit();
  }

  // ─── Token Operations ───────────────────────────────────────────

  /// Join a queue — uses a transaction to atomically increment lastIssuedToken
  /// and create the token document. Prevents race conditions.
  Future<TokenModel> joinQueue({
    required String queueId,
    required String studentId,
    required String studentName,
  }) async {
    return _db.runTransaction<TokenModel>((transaction) async {
      // Read the queue document
      final queueDoc = await transaction.get(_queuesRef.doc(queueId));
      if (!queueDoc.exists) {
        throw Exception('Queue not found');
      }

      final queue = QueueModel.fromFirestore(queueDoc);

      if (!queue.isLive) {
        throw Exception('Queue is not currently open');
      }

      // Check if student is already in this queue
      final existingTokens = await _tokensRef
          .where('queueId', isEqualTo: queueId)
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'waiting')
          .limit(1)
          .get();

      if (existingTokens.docs.isNotEmpty) {
        throw Exception('You are already in this queue');
      }

      // Increment the token counter
      final newTokenNumber = queue.lastIssuedToken + 1;

      // Update the queue
      transaction.update(_queuesRef.doc(queueId), {
        'lastIssuedToken': newTokenNumber,
      });

      // Create the token document
      final tokenRef = _tokensRef.doc();
      final now = DateTime.now();
      final tokenData = {
        'queueId': queueId,
        'studentId': studentId,
        'studentName': studentName,
        'tokenNumber': newTokenNumber,
        'status': 'waiting',
        'joinedAt': Timestamp.fromDate(now),
      };
      transaction.set(tokenRef, tokenData);

      return TokenModel(
        id: tokenRef.id,
        queueId: queueId,
        studentId: studentId,
        studentName: studentName,
        tokenNumber: newTokenNumber,
        status: 'waiting',
        joinedAt: now,
      );
    });
  }

  /// Leave queue — marks the token as "skipped"
  Future<void> leaveQueue(String tokenId) {
    return _tokensRef.doc(tokenId).update({'status': 'skipped'});
  }

  /// Advance to the next student — increments currentServing and marks the
  /// previous token as "completed"
  Future<void> nextStudent(String queueId) async {
    await _db.runTransaction((transaction) async {
      final queueDoc = await transaction.get(_queuesRef.doc(queueId));
      if (!queueDoc.exists) return;

      final queue = QueueModel.fromFirestore(queueDoc);
      final newServing = queue.currentServing + 1;

      // Mark the current token as completed
      final currentTokens = await _tokensRef
          .where('queueId', isEqualTo: queueId)
          .where('tokenNumber', isEqualTo: queue.currentServing)
          .where('status', isEqualTo: 'waiting')
          .limit(1)
          .get();

      for (final doc in currentTokens.docs) {
        transaction.update(doc.reference, {'status': 'completed'});
      }

      // Update queue's currentServing
      transaction.update(_queuesRef.doc(queueId), {
        'currentServing': newServing,
      });
    });
  }

  /// Skip the current student — marks as "skipped" and advances
  Future<void> skipStudent(String queueId) async {
    await _db.runTransaction((transaction) async {
      final queueDoc = await transaction.get(_queuesRef.doc(queueId));
      if (!queueDoc.exists) return;

      final queue = QueueModel.fromFirestore(queueDoc);
      final newServing = queue.currentServing + 1;

      // Mark the current token as skipped
      final currentTokens = await _tokensRef
          .where('queueId', isEqualTo: queueId)
          .where('tokenNumber', isEqualTo: queue.currentServing)
          .where('status', isEqualTo: 'waiting')
          .limit(1)
          .get();

      for (final doc in currentTokens.docs) {
        transaction.update(doc.reference, {'status': 'skipped'});
      }

      // Update queue's currentServing
      transaction.update(_queuesRef.doc(queueId), {
        'currentServing': newServing,
      });
    });
  }

  // ─── Token Streams ──────────────────────────────────────────────

  /// Stream the active "waiting" token for a specific student in a queue
  Stream<TokenModel?> streamStudentToken(String queueId, String studentId) {
    return _tokensRef
        .where('queueId', isEqualTo: queueId)
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return TokenModel.fromFirestore(snapshot.docs.first);
    });
  }

  /// Stream all active tokens for a student across all queues
  Stream<List<TokenModel>> streamAllStudentTokens(String studentId) {
    return _tokensRef
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TokenModel.fromFirestore(doc))
            .toList());
  }

  /// Stream the next N waiting students in a queue, ordered by token number
  Stream<List<TokenModel>> streamUpNext(String queueId, {int limit = 5}) {
    return _tokensRef
        .where('queueId', isEqualTo: queueId)
        .where('status', isEqualTo: 'waiting')
        .orderBy('tokenNumber')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TokenModel.fromFirestore(doc))
            .toList());
  }

  /// Stream queues owned by a specific professor
  Stream<List<QueueModel>> streamProfessorQueues(String professorId) {
    return _queuesRef
        .where('professorId', isEqualTo: professorId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QueueModel.fromFirestore(doc))
            .toList());
  }
}
