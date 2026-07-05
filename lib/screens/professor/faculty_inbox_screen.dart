import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/queue_provider.dart';
import '../../theme/app_theme.dart';

class FacultyInboxScreen extends ConsumerWidget {
  const FacultyInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.uid ?? '';
    final inboxAsync = ref.watch(inboxProvider(userId));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.textPrimary,
                    ),
                    const Expanded(
                      child: Text(
                        'Inbox',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // ── Content ──
              Expanded(
                child: inboxAsync.when(
                  loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
                  ),
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 64,
                                color: AppColors.textMuted
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            const Text(
                              'No messages yet',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _MessageCard(message: messages[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends ConsumerWidget {
  final MessageModel message;

  const _MessageCard({required this.message});

  IconData _typeIcon() {
    switch (message.type) {
      case 'appointment_request':
        return Icons.calendar_month_rounded;
      case 'appointment_response':
        return Icons.event_available_rounded;
      case 'schedule_notification':
        return Icons.schedule_rounded;
      default:
        return Icons.mail_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return GestureDetector(
      onTap: () {
        // Mark as read
        if (!message.isRead) {
          final db = ref.read(databaseServiceProvider);
          db.markMessageRead(message.id);
        }
        // Show appropriate dialog based on message type
        if (message.isAppointmentRequest &&
            message.relatedAppointmentId != null) {
          _showAppointmentReplyDialog(context, ref);
        } else {
          _showMessageDetail(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: message.isRead
              ? Colors.white.withValues(alpha: 0.04)
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: message.isRead
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(),
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: message.isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'From: ${message.fromName}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Time + unread dot
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateFormat.format(message.createdAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (!message.isRead)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced dialog for appointment request messages — lets faculty
  /// reply with a proposed date/time and message, or reject.
  void _showAppointmentReplyDialog(BuildContext context, WidgetRef ref) {
    final replyController = TextEditingController();
    DateTime? proposedDate;
    TimeOfDay? proposedTime;
    bool isSubmitting = false;
    final dateFormat = DateFormat('MMM dd, yyyy');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceLight,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Appointment Request',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_rounded,
                                size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                message.fromName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message.body,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Proposed date/time section
                  const Text(
                    'Your Proposed Time',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Date picker
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 90)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppColors.primary,
                                      surface: AppColors.surfaceLight,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setDialogState(() => proposedDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    AppColors.textMuted.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 8),
                                Text(
                                  proposedDate != null
                                      ? dateFormat.format(proposedDate!)
                                      : 'Date',
                                  style: TextStyle(
                                    color: proposedDate != null
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time picker
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppColors.primary,
                                      surface: AppColors.surfaceLight,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              setDialogState(() => proposedTime = time);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    AppColors.textMuted.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 16, color: AppColors.textMuted),
                                const SizedBox(width: 8),
                                Text(
                                  proposedTime != null
                                      ? proposedTime!.format(context)
                                      : 'Time',
                                  style: TextStyle(
                                    color: proposedTime != null
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Reply message
                  const Text(
                    'Reply Message (optional)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: replyController,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: InputDecoration(
                      hintText: 'Add a message for the student...',
                      hintStyle:
                          const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Cancel
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              // Reject
              OutlinedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (message.relatedAppointmentId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error: Appointment ID is missing for this request.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        setDialogState(() => isSubmitting = true);
                        try {
                          final db = ref.read(databaseServiceProvider);
                          await db.rejectAppointment(
                            message.relatedAppointmentId!,
                            message: replyController.text,
                          );
                          if (context.mounted) Navigator.of(context).pop();
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Reject'),
              ),
              // Accept
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (message.relatedAppointmentId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error: Appointment ID is missing for this request.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        setDialogState(() => isSubmitting = true);
                        try {
                          final db = ref.read(databaseServiceProvider);
                          final timeStr = proposedTime?.format(context);
                          await db.acceptAppointment(
                            message.relatedAppointmentId!,
                            replyMessage: replyController.text,
                            proposedDate: proposedDate,
                            proposedTime: timeStr,
                          );
                          if (context.mounted) Navigator.of(context).pop();
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Accept'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Simple read-only detail dialog for non-appointment messages
  void _showMessageDetail(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(
          message.subject,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('From: ',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
                Text(message.fromName,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(message.createdAt),
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
            const Divider(height: 24, color: AppColors.surfaceCard),
            Text(
              message.body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
