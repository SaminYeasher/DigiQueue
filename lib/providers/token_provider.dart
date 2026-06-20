import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/token_model.dart';
import 'queue_provider.dart';

/// Streams the active "waiting" token for a student in a specific queue.
/// Parameters: (queueId, studentId)
final studentActiveTokenProvider =
    StreamProvider.family<TokenModel?, ({String queueId, String studentId})>(
        (ref, params) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamStudentToken(params.queueId, params.studentId);
});

/// Streams all active tokens for a student across all queues.
final allStudentTokensProvider =
    StreamProvider.family<List<TokenModel>, String>((ref, studentId) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamAllStudentTokens(studentId);
});

/// Streams the "Up Next" list — next N waiting students in a queue.
final upNextProvider =
    StreamProvider.family<List<TokenModel>, String>((ref, queueId) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamUpNext(queueId, limit: 5);
});

/// Computes how many people are ahead of a student in a queue.
/// Returns null if the student is not in the queue.
int? computePeopleAhead({
  required int? tokenNumber,
  required int? currentServing,
}) {
  if (tokenNumber == null || currentServing == null) return null;
  final ahead = tokenNumber - currentServing - 1;
  return ahead < 0 ? 0 : ahead;
}

/// Whether it's currently the student's turn
bool isStudentTurn({
  required int? tokenNumber,
  required int? currentServing,
}) {
  if (tokenNumber == null || currentServing == null) return false;
  return tokenNumber == currentServing;
}
