import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/queue_model.dart';
import '../../models/token_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/queue_provider.dart';
import '../../providers/token_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ticket_display.dart';

class ActiveTicketScreen extends ConsumerStatefulWidget {
  final String queueId;
  final String professorName;
  final String roomNumber;

  const ActiveTicketScreen({
    super.key,
    required this.queueId,
    required this.professorName,
    required this.roomNumber,
  });

  @override
  ConsumerState<ActiveTicketScreen> createState() => _ActiveTicketScreenState();
}

class _ActiveTicketScreenState extends ConsumerState<ActiveTicketScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _leaveQueue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Queue?'),
        content: const Text(
          'You will lose your position in the queue. '
          'You can rejoin, but you\'ll get a new token number.',
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
            child: const Text('Leave Queue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final tokenAsync = ref.read(studentActiveTokenProvider(
      (queueId: widget.queueId, studentId: user.uid),
    ));
    final token = tokenAsync.value;
    if (token == null) return;

    try {
      final db = ref.read(databaseServiceProvider);
      await db.leaveQueue(token.id);
      HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave queue: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.uid ?? '';

    final queueAsync = ref.watch(queueProvider(widget.queueId));
    final tokenAsync = ref.watch(studentActiveTokenProvider(
      (queueId: widget.queueId, studentId: userId),
    ));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _entranceController,
              curve: Curves.easeOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _entranceController,
                curve: Curves.easeOutCubic,
              )),
              child: Column(
                children: [
                  // ── App Bar ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AppColors.textPrimary,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                widget.professorName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.room_outlined,
                                      size: 13, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.roomNumber,
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
                        // Queue live status
                        queueAsync.when(
                          data: (queue) {
                            if (queue == null) return const SizedBox(width: 48);
                            final color = queue.isLive
                                ? AppColors.success
                                : AppColors.error;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    queue.isLive ? 'Live' : 'Closed',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loading: () => const SizedBox(width: 48),
                          error: (error, stackTrace) => const SizedBox(width: 48),
                        ),
                      ],
                    ),
                  ),

                  // ── Main Content ──
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: _buildTicketContent(queueAsync, tokenAsync),
                      ),
                    ),
                  ),

                  // ── Leave Queue Button ──
                  if (tokenAsync.value != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _leaveQueue,
                          icon: const Icon(Icons.exit_to_app_rounded,
                              color: AppColors.error),
                          label: const Text(
                            'Leave Queue',
                            style: TextStyle(color: AppColors.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketContent(
    AsyncValue<QueueModel?> queueAsync,
    AsyncValue<TokenModel?> tokenAsync,
  ) {
    final queue = queueAsync.valueOrNull;
    final token = tokenAsync.valueOrNull;

    if (token == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'No active ticket',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Go back and join a queue to get a token',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    final currentServing = queue?.currentServing ?? 0;
    final peopleAhead = computePeopleAhead(
      tokenNumber: token.tokenNumber,
      currentServing: currentServing,
    ) ?? 0;

    return TicketDisplay(
      tokenNumber: token.tokenNumber,
      currentServing: currentServing,
      peopleAhead: peopleAhead,
    );
  }
}
