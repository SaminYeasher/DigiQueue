import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Accept / Hold / Reject action buttons for faculty queue control
class FacultyActionButtons extends StatelessWidget {
  final bool hasWaiting;
  final bool isOnHold;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onNext;
  final ValueChanged<int> onHold; // passes hold minutes

  const FacultyActionButtons({
    super.key,
    required this.hasWaiting,
    required this.isOnHold,
    required this.onAccept,
    required this.onReject,
    required this.onNext,
    required this.onHold,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary action row: Accept / Hold / Reject
        Row(
          children: [
            // Accept
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: hasWaiting && !isOnHold ? onAccept : null,
                  icon: const Icon(Icons.check_circle_rounded, size: 22),
                  label: const Text(
                    'Accept',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.success.withValues(alpha: 0.2),
                    disabledForegroundColor:
                        AppColors.success.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Hold (dropdown)
            SizedBox(
              height: 56,
              child: PopupMenuButton<int>(
                enabled: hasWaiting && !isOnHold,
                onSelected: onHold,
                offset: const Offset(0, -200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: AppColors.surfaceLight,
                itemBuilder: (context) => [
                  _holdMenuItem(2),
                  _holdMenuItem(5),
                  _holdMenuItem(10),
                  _holdMenuItem(15),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: hasWaiting && !isOnHold
                        ? AppColors.warning
                        : AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pause_circle_rounded,
                        size: 22,
                        color: hasWaiting && !isOnHold
                            ? Colors.white
                            : AppColors.warning.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Hold',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: hasWaiting && !isOnHold
                              ? Colors.white
                              : AppColors.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down,
                        color: hasWaiting && !isOnHold
                            ? Colors.white
                            : AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Reject
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: hasWaiting ? onReject : null,
                  icon: const Icon(Icons.cancel_rounded, size: 22),
                  label: const Text(
                    'Reject',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.error.withValues(alpha: 0.2),
                    disabledForegroundColor:
                        AppColors.error.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Next Student button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: hasWaiting ? onNext : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 22),
            label: const Text(
              'Next Student',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: hasWaiting
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<int> _holdMenuItem(int minutes) {
    return PopupMenuItem<int>(
      value: minutes,
      child: Row(
        children: [
          const Icon(Icons.timer_outlined,
              size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Text(
            'Wait $minutes min',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
