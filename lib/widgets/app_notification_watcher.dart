import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../models/token_model.dart';
import '../providers/message_provider.dart';
import '../providers/queue_provider.dart';
import '../providers/token_provider.dart';
import '../services/notification_service.dart';

/// Wraps the main logged-in area to listen for incoming messages
/// (e.g. appointment replies, reschedule notices) and queue turn events.
class AppNotificationWatcher extends ConsumerStatefulWidget {
  final String userId;
  final Widget child;

  const AppNotificationWatcher({
    super.key,
    required this.userId,
    required this.child,
  });

  @override
  ConsumerState<AppNotificationWatcher> createState() =>
      _AppNotificationWatcherState();
}

class _AppNotificationWatcherState
    extends ConsumerState<AppNotificationWatcher> {
  final Set<String> _knownMessageIds = {};
  final Set<String> _notifiedTurnTokenKeys = {};
  bool _isFirstMessageLoad = true;

  @override
  void initState() {
    super.initState();
    // Request notification permissions when user logs in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── 1. Listen for new inbox messages (Appointment replies, etc.) ──
    ref.listen<AsyncValue<List<MessageModel>>>(
      inboxProvider(widget.userId),
      (prev, next) {
        final messages = next.value;
        if (messages == null) return;

        if (_isFirstMessageLoad) {
          // On first load, record existing IDs without firing old notifications
          _knownMessageIds.addAll(messages.map((m) => m.id));
          _isFirstMessageLoad = false;
          return;
        }

        // Check for new unread messages
        for (final message in messages) {
          if (!_knownMessageIds.contains(message.id)) {
            _knownMessageIds.add(message.id);

            if (!message.isRead) {
              final notif = ref.read(notificationServiceProvider);
              notif.showAppointmentNotification(
                title: message.subject.isNotEmpty
                    ? message.subject
                    : 'New Message from ${message.fromName}',
                body: message.body,
                payload: message.id,
              );
            }
          }
        }
      },
    );

    // ── 2. Listen for active student tokens across queues ───────────────
    ref.listen<AsyncValue<List<TokenModel>>>(
      allStudentTokensProvider(widget.userId),
      (prev, next) {
        final tokens = next.value;
        if (tokens == null || tokens.isEmpty) return;

        for (final token in tokens) {
          if (token.isServing) {
            final key = '${token.queueId}_${token.tokenNumber}';
            if (!_notifiedTurnTokenKeys.contains(key)) {
              _notifiedTurnTokenKeys.add(key);

              // Look up queue info for professor name & room
              ref.read(databaseServiceProvider).getQueue(token.queueId).then((queue) {
                if (queue != null && mounted) {
                  ref.read(notificationServiceProvider).showTurnNotification(
                        professorName: queue.professorName,
                        roomNumber: queue.roomNumber,
                        tokenNumber: token.tokenNumber,
                      );
                }
              });
            }
          }
        }
      },
    );

    return widget.child;
  }
}
