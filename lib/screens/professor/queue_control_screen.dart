import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../providers/token_provider.dart';
import '../../providers/message_provider.dart';
import '../../models/queue_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/up_next_list.dart';
import '../../widgets/faculty_action_buttons.dart';
import '../../widgets/hold_timer_widget.dart';
import '../../widgets/inbox_badge.dart';
import '../auth/login_screen.dart';
import 'faculty_appointments_screen.dart';
import 'faculty_inbox_screen.dart';
import 'queue_history_screen.dart';

class QueueControlScreen extends ConsumerStatefulWidget {
  const QueueControlScreen({super.key});

  @override
  ConsumerState<QueueControlScreen> createState() => _QueueControlScreenState();
}

class _QueueControlScreenState extends ConsumerState<QueueControlScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  String? _selectedQueueId;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _createQueue() async {
    final nameController = TextEditingController();
    final roomController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Queue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Professor Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: roomController,
              decoration: const InputDecoration(
                labelText: 'Room Number',
                prefixIcon: Icon(Icons.room_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (nameController.text.trim().isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final db = ref.read(databaseServiceProvider);
      final id = await db.createQueue(
        professorName: nameController.text.trim(),
        roomNumber: roomController.text.trim(),
        professorId: user.uid,
      );
      setState(() => _selectedQueueId = id);
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create queue: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleLive(String queueId, bool currentState) async {
    final db = ref.read(databaseServiceProvider);
    await db.toggleQueueLive(queueId, !currentState);
    HapticFeedback.lightImpact();
  }

  Future<void> _nextStudent(String queueId) async {
    final db = ref.read(databaseServiceProvider);
    await db.nextStudent(queueId);
    HapticFeedback.heavyImpact();
  }

  Future<void> _acceptStudent(String queueId) async {
    final db = ref.read(databaseServiceProvider);
    await db.acceptStudent(queueId);
    HapticFeedback.mediumImpact();
  }

  Future<void> _holdStudent(String queueId, int minutes) async {
    final db = ref.read(databaseServiceProvider);
    await db.holdStudent(queueId, minutes);
    HapticFeedback.mediumImpact();
  }

  Future<void> _clearHold(String queueId) async {
    final db = ref.read(databaseServiceProvider);
    await db.clearHold(queueId);
    HapticFeedback.lightImpact();
  }

  Future<void> _rejectStudent(String queueId) async {
    final messageController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Student?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will reject the current student and advance to the next one. '
              'You can optionally provide a message (e.g. for a next schedule).',
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == null) return; // User cancelled

    final db = ref.read(databaseServiceProvider);
    final user = ref.read(currentUserProvider);
    await db.rejectStudent(
      queueId, 
      message: result, 
      professorId: user?.uid,
      professorName: user?.displayName,
      professorEmail: user?.email,
    );
    HapticFeedback.heavyImpact();
  }

  Future<void> _resetQueue(String queueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Queue?'),
        content: const Text(
          'This will reset the serving counter and token numbers to 0. '
          'All existing tokens will remain in the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final db = ref.read(databaseServiceProvider);
    await db.resetQueue(queueId);
    HapticFeedback.heavyImpact();
  }

  Future<void> _deleteQueue(String queueId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Queue?'),
        content: const Text(
          'Are you sure you want to delete this queue entirely? '
          'All history and tokens will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final db = ref.read(databaseServiceProvider);
    await db.deleteQueue(queueId);
    HapticFeedback.heavyImpact();
    // After deletion, clear selection so the dashboard will default to the first available queue
    if (mounted && _selectedQueueId == queueId) {
      setState(() => _selectedQueueId = null);
    }
  }

  Future<void> _signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    ref.read(userRoleProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.uid ?? '';

    final queuesAsync = ref.watch(professorQueuesProvider(userId));
    final unreadAsync = ref.watch(unreadCountProvider(userId));
    final unreadCount = unreadAsync.value ?? 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _fadeController,
              curve: Curves.easeOut,
            ),
            child: Column(
              children: [
                // ── App Bar ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9B59B6), Color(0xFF6C3483)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.cast_for_education_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Queue Control',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Manage your office hours',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Appointments button
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                const FacultyAppointmentsScreen(),
                          ));
                        },
                        icon: const Icon(Icons.calendar_month_rounded,
                            color: AppColors.textMuted),
                        tooltip: 'Appointments',
                      ),
                      // Inbox button with badge
                      InboxBadge(
                        count: unreadCount,
                        child: IconButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  const FacultyInboxScreen(),
                            ));
                          },
                          icon: const Icon(Icons.inbox_rounded,
                              color: AppColors.textMuted),
                          tooltip: 'Inbox',
                        ),
                      ),
                      IconButton(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout_rounded,
                            color: AppColors.textMuted),
                        tooltip: 'Sign Out',
                      ),
                    ],
                  ),
                ),

                // ── Content ──
                Expanded(
                  child: queuesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                    error: (error, _) => Center(
                      child: Text('Error: $error',
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ),
                    data: (queues) {
                      if (queues.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Auto-select the first queue if none selected
                      final selectedId = _selectedQueueId ?? queues.first.id;

                      return _buildQueueDashboard(queues, selectedId);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createQueue,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Queue',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            size: 72,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          const Text(
            'No queues yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first queue to start\nmanaging office hours',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createQueue,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Queue'),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueDashboard(List<QueueModel> queues, String selectedId) {
    // If there are multiple queues, show a selector
    final selectedQueue = queues.firstWhere(
      (q) => q.id == selectedId,
      orElse: () => queues.first,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ── Queue Selector (if multiple) ──
          if (queues.length > 1)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: queues.length,
                itemBuilder: (context, index) {
                  final q = queues[index];
                  final isSelected = q.id == selectedQueue.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(q.professorName),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedQueueId = q.id),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceCard,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          // ── Live Toggle + Status ──
          _LiveControlCard(
            queue: selectedQueue,
            onToggle: () =>
                _toggleLive(selectedQueue.id, selectedQueue.isLive),
            onReset: () => _resetQueue(selectedQueue.id),
            onDelete: () => _deleteQueue(selectedQueue.id),
            onViewHistory: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QueueHistoryScreen(
                  queueId: selectedQueue.id,
                  professorName: selectedQueue.professorName,
                  roomNumber: selectedQueue.roomNumber,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Hold Timer (if on hold) ──
          if (selectedQueue.isOnHold && selectedQueue.holdUntil != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: HoldTimerWidget(
                holdUntil: selectedQueue.holdUntil!,
                onExpired: () => _clearHold(selectedQueue.id),
                onCancelHold: () => _clearHold(selectedQueue.id),
              ),
            ),

          // ── Faculty Action Buttons (Accept/Hold/Reject) ──
          FacultyActionButtons(
            hasWaiting: selectedQueue.waitingCount > 0,
            isOnHold: selectedQueue.isOnHold,
            currentStudentStatus: selectedQueue.currentStudentStatus,
            onAccept: () => _acceptStudent(selectedQueue.id),
            onReject: () => _rejectStudent(selectedQueue.id),
            onNext: () => _nextStudent(selectedQueue.id),
            onHold: (minutes) => _holdStudent(selectedQueue.id, minutes),
          ),
          const SizedBox(height: 16),

          // ── Up Next List ──
          Consumer(
            builder: (context, ref, _) {
              final upNextAsync = ref.watch(upNextProvider(selectedQueue.id));
              return upNextAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => Text('Error: $e'),
                data: (tokens) => UpNextList(
                  tokens: tokens,
                  currentServing: selectedQueue.currentServing,
                ),
              );
            },
          ),
          const SizedBox(height: 100), // FAB clearance
        ],
      ),
    );
  }
}

// ── Live Control Card ──────────────────────────────────────────────

class _LiveControlCard extends StatelessWidget {
  final QueueModel queue;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;

  const _LiveControlCard({
    required this.queue,
    required this.onToggle,
    required this.onReset,
    required this.onDelete,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = queue.isLive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: GlassDecoration.elevated(
        glowColor: statusColor,
      ),
      child: Column(
        children: [
          // Top row: name + toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      queue.professorName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.room_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          queue.roomNumber,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Live toggle
              Column(
                children: [
                  Switch(
                    value: queue.isLive,
                    onChanged: (_) => onToggle(),
                  ),
                  Text(
                    queue.isLive ? 'LIVE' : 'CLOSED',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Currently Serving ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'CURRENTLY SERVING',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '#${queue.currentServing}',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                // Show status badge
                if (queue.currentStudentStatus != null &&
                    queue.currentServing > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _StatusBadge(
                        status: queue.currentStudentStatus!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Stats Row ──
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.people_outline_rounded,
                  label: 'Waiting',
                  value: '${queue.waitingCount}',
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Total Issued',
                  value: '${queue.lastIssuedToken}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              // Reset button
              IconButton(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.textMuted,
                tooltip: 'Reset Queue',
              ),
              // History button
              IconButton(
                onPressed: onViewHistory,
                icon: const Icon(Icons.history_rounded),
                color: AppColors.primary,
                tooltip: 'Queue History',
              ),
              // Delete button
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.error.withValues(alpha: 0.8),
                tooltip: 'Delete Queue',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'accepted':
        color = AppColors.success;
        label = 'ACCEPTED';
        icon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'REJECTED';
        icon = Icons.cancel_rounded;
        break;
      case 'on_hold':
        color = AppColors.warning;
        label = 'ON HOLD';
        icon = Icons.pause_circle_rounded;
        break;
      default:
        color = AppColors.primary;
        label = 'SERVING';
        icon = Icons.play_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
