import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import 'queue_provider.dart';

/// Streams all inbox messages for a user
final inboxProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, userId) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamInbox(userId);
});

/// Streams unread message count for a user
final unreadCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  final db = ref.watch(databaseServiceProvider);
  return db.streamUnreadCount(userId);
});
