import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/queue_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../providers/token_provider.dart';
import '../../providers/message_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/queue_card.dart';
import '../../widgets/inbox_badge.dart';
import '../auth/login_screen.dart';
import 'active_ticket_screen.dart';
import 'student_appointment_screen.dart';
import 'student_inbox_screen.dart';

class QueueListScreen extends ConsumerStatefulWidget {
  const QueueListScreen({super.key});

  @override
  ConsumerState<QueueListScreen> createState() => _QueueListScreenState();
}

class _QueueListScreenState extends ConsumerState<QueueListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

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

  Future<void> _joinQueue(QueueModel queue) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final db = ref.read(databaseServiceProvider);
      await db.joinQueue(
        queueId: queue.id,
        studentId: user.uid,
        studentName: user.displayName ?? 'Anonymous Student',
        studentEmail: user.email ?? '',
      );
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ActiveTicketScreen(
              queueId: queue.id,
              professorName: queue.professorName,
              roomNumber: queue.roomNumber,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToTicket(QueueModel queue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveTicketScreen(
          queueId: queue.id,
          professorName: queue.professorName,
          roomNumber: queue.roomNumber,
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    ref.read(userRoleProvider.notifier).state = null;
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final queuesAsync = ref.watch(allQueuesProvider);
    final user = ref.watch(currentUserProvider);
    final userId = user?.uid ?? '';
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
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.queue_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Office Hours',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Find and join a queue',
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
                                const StudentAppointmentScreen(),
                          ));
                        },
                        icon: const Icon(Icons.calendar_month_rounded,
                            color: AppColors.textMuted),
                        tooltip: 'Appointments',
                      ),
                      // Inbox with badge
                      InboxBadge(
                        count: unreadCount,
                        child: IconButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  const StudentInboxScreen(),
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
                const SizedBox(height: 8),

                // ── Queue List ──
                Expanded(
                  child: queuesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (error, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load queues',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$error',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    data: (queues) {
                      if (queues.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color:
                                    AppColors.textMuted.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No queues available',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Check back when a professor\nopens their office hours',
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

                      return RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceCard,
                        onRefresh: () async {
                          ref.invalidate(allQueuesProvider);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: queues.length,
                          itemBuilder: (context, index) {
                            final queue = queues[index];
                            return _QueueCardWithToken(
                              queue: queue,
                              userId: user?.uid ?? '',
                              onJoin: () => _joinQueue(queue),
                              onTap: () => _navigateToTicket(queue),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps QueueCard with a check for whether the student already has a token
class _QueueCardWithToken extends ConsumerWidget {
  final QueueModel queue;
  final String userId;
  final VoidCallback onJoin;
  final VoidCallback onTap;

  const _QueueCardWithToken({
    required this.queue,
    required this.userId,
    required this.onJoin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenAsync = ref.watch(studentActiveTokenProvider(
      (queueId: queue.id, studentId: userId),
    ));

    final isJoined = tokenAsync.value != null;

    return QueueCard(
      queue: queue,
      isJoined: isJoined,
      canJoin: !isJoined,
      onJoin: onJoin,
      onTap: isJoined ? onTap : null,
    );
  }
}
