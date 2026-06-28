import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Circular countdown timer widget with glow animation for hold feature
class HoldTimerWidget extends StatefulWidget {
  final DateTime holdUntil;
  final VoidCallback onExpired;
  final VoidCallback? onCancelHold;

  const HoldTimerWidget({
    super.key,
    required this.holdUntil,
    required this.onExpired,
    this.onCancelHold,
  });

  @override
  State<HoldTimerWidget> createState() => _HoldTimerWidgetState();
}

class _HoldTimerWidgetState extends State<HoldTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final diff = widget.holdUntil.difference(now);
    if (diff.isNegative) {
      _timer.cancel();
      widget.onExpired();
      return;
    }
    if (mounted) {
      setState(() => _remaining = diff);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.holdUntil
        .difference(DateTime.now().subtract(_remaining))
        .inSeconds
        .toDouble();
    final remainingSeconds = _remaining.inSeconds.toDouble();
    final progress =
        totalSeconds > 0 ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + _pulseController.value * 0.03;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timer label
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pause_circle_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'ON HOLD',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Circular progress
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor:
                          AppColors.warning.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.warning),
                    ),
                  ),
                  Text(
                    _formatDuration(_remaining),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Cancel hold button
            if (widget.onCancelHold != null)
              TextButton.icon(
                onPressed: widget.onCancelHold,
                icon: const Icon(Icons.cancel_outlined,
                    size: 18, color: AppColors.textMuted),
                label: const Text(
                  'Cancel Hold',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
