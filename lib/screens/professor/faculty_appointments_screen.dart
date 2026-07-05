import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/queue_provider.dart';
import '../../theme/app_theme.dart';

class FacultyAppointmentsScreen extends ConsumerWidget {
  const FacultyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.uid ?? '';
    final appointmentsAsync = ref.watch(facultyAppointmentsProvider(userId));

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
                        'Appointments',
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
                child: appointmentsAsync.when(
                  loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e',
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
                  ),
                  data: (appointments) {
                    if (appointments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 64,
                                color: AppColors.textMuted
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            const Text(
                              'No appointment requests',
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
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        return _AppointmentCard(
                            appointment: appointments[index]);
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

class _AppointmentCard extends ConsumerWidget {
  final AppointmentModel appointment;

  const _AppointmentCard({required this.appointment});

  Color _statusColor() {
    switch (appointment.status) {
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'rescheduled':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final color = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: GlassDecoration.card(
        borderColor: color.withValues(alpha: 0.3),
        opacity: 0.07,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Student name + status
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    appointment.studentName.isNotEmpty
                        ? appointment.studentName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.studentName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      appointment.studentEmail,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appointment.status.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Subject
          Text(
            appointment.subject,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (appointment.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              appointment.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Date/Time
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                dateFormat.format(appointment.requestedDate),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time_rounded,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                appointment.requestedTime,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          // Rescheduled info
          if (appointment.isRescheduled &&
              appointment.rescheduledDate != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.update_rounded,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Text(
                    'Rescheduled to: ${dateFormat.format(appointment.rescheduledDate!)} at ${appointment.rescheduledTime}',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons (only for pending)
          if (appointment.isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final db = ref.read(databaseServiceProvider);
                        await db.acceptAppointment(appointment.id);
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Accept',
                          style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showRescheduleDialog(context, ref),
                      icon: const Icon(Icons.schedule_rounded, size: 18),
                      label: const Text('Reschedule',
                          style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) async {
    final messageController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Appointment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to reject this appointment request?'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Email for next schedule (optional)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(messageController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == null) return;
    
    final db = ref.read(databaseServiceProvider);
    await db.rejectAppointment(appointment.id, message: result);
  }

  void _showRescheduleDialog(BuildContext context, WidgetRef ref) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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

    if (selectedDate == null || !context.mounted) return;

    selectedTime = await showTimePicker(
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

    if (selectedTime == null || !context.mounted) return;

    final timeStr = selectedTime.format(context);

    final db = ref.read(databaseServiceProvider);
    await db.rescheduleAppointment(
      appointmentId: appointment.id,
      newDate: selectedDate,
      newTime: timeStr,
    );
  }
}
