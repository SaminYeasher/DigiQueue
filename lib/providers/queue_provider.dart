import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/queue_model.dart';
import '../services/database_service.dart';

/// Provides a singleton DatabaseService instance
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Streams all queues from Firestore
final allQueuesProvider = StreamProvider<List<QueueModel>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamAllQueues();
});

/// Streams a single queue by ID (family provider)
final queueProvider =
    StreamProvider.family<QueueModel?, String>((ref, queueId) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamQueue(queueId);
});

/// Streams queues owned by a specific professor
final professorQueuesProvider =
    StreamProvider.family<List<QueueModel>, String>((ref, professorId) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamProfessorQueues(professorId);
});
