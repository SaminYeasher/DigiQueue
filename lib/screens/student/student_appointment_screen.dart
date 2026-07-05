import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/queue_provider.dart';
import '../../theme/app_theme.dart';

class StudentAppointmentScreen extends ConsumerStatefulWidget {
  const StudentAppointmentScreen({super.key});

  @override
  ConsumerState<StudentAppointmentScreen> createState() =>
      _StudentAppointmentScreenState();
}

class _StudentAppointmentScreenState
    extends ConsumerState<StudentAppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

              // ── Tab Bar ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Request New'),
                    Tab(text: 'My Appointments'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Tab Content ──
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _RequestAppointmentTab(),
                    _MyAppointmentsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Request Appointment Tab ──

class _RequestAppointmentTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RequestAppointmentTab> createState() =>
      _RequestAppointmentTabState();
}

class _RequestAppointmentTabState
    extends ConsumerState<_RequestAppointmentTab> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  UserModel? _selectedFaculty;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
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
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
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
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFaculty == null || _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final timeStr = _selectedTime!.format(context);

      final db = ref.read(databaseServiceProvider);
      await db.createAppointment(
        studentId: user.uid,
        studentName: user.displayName ?? 'Student',
        studentEmail: user.email ?? '',
        facultyId: _selectedFaculty!.uid,
        facultyName: _selectedFaculty!.displayName,
        facultyEmail: _selectedFaculty!.email,
        requestedDate: _selectedDate!,
        requestedTime: timeStr,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment request sent!'),
            backgroundColor: AppColors.success,
          ),
        );
        _subjectController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedDate = null;
          _selectedTime = null;
          _selectedFaculty = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Faculty selector
            const Text(
              'Select Faculty',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ref.watch(facultyUsersProvider).when(
              loading: () => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading faculty...', style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
              error: (e, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text('Failed to load faculty: $e',
                    style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
              data: (facultyList) {
                // Reset selection if the selected faculty is no longer in the list
                if (_selectedFaculty != null &&
                    !facultyList.any((f) => f.uid == _selectedFaculty!.uid)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selectedFaculty = null);
                  });
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  child: DropdownButton<UserModel>(
                    value: _selectedFaculty,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceLight,
                    underline: const SizedBox(),
                    hint: Text(
                      facultyList.isEmpty
                          ? 'No faculty registered yet'
                          : 'Choose faculty member',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    items: facultyList
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(
                                f.displayName,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14),
                              ),
                            ))
                        .toList(),
                    onChanged: facultyList.isEmpty
                        ? null
                        : (v) => setState(() => _selectedFaculty = v),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Date & Time pickers
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              AppColors.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 10),
                          Text(
                            _selectedDate != null
                                ? dateFormat.format(_selectedDate!)
                                : 'Select Date',
                            style: TextStyle(
                              color: _selectedDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              AppColors.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 10),
                          Text(
                            _selectedTime != null
                                ? _selectedTime!.format(context)
                                : 'Select Time',
                            style: TextStyle(
                              color: _selectedTime != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Subject
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                prefixIcon: Icon(Icons.subject_rounded),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a subject' : null,
            ),
            const SizedBox(height: 16),

            // Description (2 lines max)
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Brief Description (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitRequest,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                    _isSubmitting ? 'Sending...' : 'Request Appointment'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── My Appointments Tab ──

class _MyAppointmentsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.uid ?? '';
    final appointmentsAsync =
        ref.watch(studentAppointmentsProvider(userId));

    return appointmentsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
      data: (appointments) {
        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_rounded,
                    size: 64,
                    color: AppColors.textMuted.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                const Text(
                  'No appointments yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Request an appointment from\nthe "Request New" tab',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return _StudentAppointmentCard(
                appointment: appointments[index]);
          },
        );
      },
    );
  }
}

class _StudentAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _StudentAppointmentCard({required this.appointment});

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
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final color = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: GlassDecoration.card(
        borderColor: color.withValues(alpha: 0.3),
        opacity: 0.07,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appointment.subject,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
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
          const SizedBox(height: 8),
          Text(
            'Faculty: ${appointment.facultyName}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                dateFormat.format(appointment.requestedDate),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time_rounded,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                appointment.requestedTime,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
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
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text(
                    'New: ${dateFormat.format(appointment.rescheduledDate!)} at ${appointment.rescheduledTime}',
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
        ],
      ),
    );
  }
}
