import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── High-Contrast Button Colors ──────────────────────────────────────────
// These are tuned to pop on the deep burgundy background (#1E000E / #4A0023)
// while remaining warm-toned and harmonious with the Gold primary (#F1C232).

class _BtnColors {
  // Emerald green — high contrast "done / complete" signal
  static const done = Color(0xFF00C896);
  static const doneGlow = Color(0x2600C896);

  // Amber — warm hold signal, distinct from the Gold primary
  static const hold = Color(0xFFF59E0B);
  static const holdGlow = Color(0x26F59E0B);

  // Saturated coral-red — visible reject signal on dark bg
  static const reject = Color(0xFFFF4757);
  static const rejectGlow = Color(0x26FF4757);
}

/// Done / Hold / Reject action buttons for faculty queue control.
///
/// Button enable/disable logic enforces a realistic workflow:
///
///   [Next Student] ──► serving ──► [Done ✓]  ──► [Next Student] or "Queue Empty"
///                              ──► [Reject]   ──► auto-advances (or "Queue Empty")
///                              ──► [Hold]     ──► Cancel Hold ──► back to serving
///
/// Key fix: Accept/Reject/Done gate on [isActivelyServing] — not on [hasWaiting].
/// This ensures the last student in the queue can still be processed.
class FacultyActionButtons extends StatelessWidget {
  /// True when a real student is currently at the desk
  /// (currentServing > 0 && currentServing <= lastIssuedToken).
  final bool isActivelyServing;

  /// True when there are students queued *after* the current one.
  final bool hasWaiting;

  final bool isOnHold;
  final String? currentStudentStatus;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onNext;
  final ValueChanged<int> onHold; // passes hold minutes

  const FacultyActionButtons({
    super.key,
    required this.isActivelyServing,
    required this.hasWaiting,
    required this.isOnHold,
    this.currentStudentStatus,
    required this.onAccept,
    required this.onReject,
    required this.onNext,
    required this.onHold,
  });

  @override
  Widget build(BuildContext context) {
    final isServing = currentStudentStatus == 'serving';
    final isAccepted = currentStudentStatus == 'accepted';

    // ── Button enable rules ─────────────────────────────────────────────
    // Done ✓: only when a student is actively at the desk and being served
    final canDone = isActivelyServing && isServing && !isOnHold;

    // Reject: when actively serving or on hold — professor must be able to
    // reject even the last student
    final canReject = isActivelyServing && (isServing || isOnHold);

    // Hold: any time unless already on hold (no serving restriction)
    final canHold = !isOnHold;

    // Next Student:
    //   • After marking done (accepted state) — move to next
    //   • No one actively being served AND students are waiting (fresh start, post-reject, or refilled after empty)
    final canNext =
        (isActivelyServing && isAccepted) ||
        (!isActivelyServing &&
            hasWaiting &&
            (currentStudentStatus == null ||
                currentStudentStatus == 'rejected'));

    return Column(
      children: [
        // ── Primary row: Done / Hold / Reject ──────────────────────────
        Row(
          children: [
            // Done ✓
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: canDone ? onAccept : null,
                  icon: const Icon(Icons.check_circle_rounded, size: 22),
                  label: const Text(
                    'Done ✓',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _BtnColors.done,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _BtnColors.doneGlow,
                    disabledForegroundColor:
                        _BtnColors.done.withValues(alpha: 0.35),
                    elevation: canDone ? 4 : 0,
                    shadowColor: _BtnColors.doneGlow,
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
                enabled: canHold,
                onSelected: onHold,
                offset: const Offset(0, -210),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: AppColors.surfaceHighlight,
                itemBuilder: (context) => [
                  _holdMenuItem(2),
                  _holdMenuItem(5),
                  _holdMenuItem(10),
                  _holdMenuItem(15),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: canHold
                        ? _BtnColors.hold
                        : _BtnColors.holdGlow,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: canHold
                        ? [
                            BoxShadow(
                              color: _BtnColors.holdGlow,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pause_circle_rounded,
                        size: 22,
                        color: canHold
                            ? Colors.white
                            : _BtnColors.hold.withValues(alpha: 0.35),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Hold',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: canHold
                              ? Colors.white
                              : _BtnColors.hold.withValues(alpha: 0.35),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down,
                        color: canHold
                            ? Colors.white
                            : _BtnColors.hold.withValues(alpha: 0.35),
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
                  onPressed: canReject ? onReject : null,
                  icon: const Icon(Icons.cancel_rounded, size: 22),
                  label: const Text(
                    'Reject',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _BtnColors.reject,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _BtnColors.rejectGlow,
                    disabledForegroundColor:
                        _BtnColors.reject.withValues(alpha: 0.35),
                    elevation: canReject ? 4 : 0,
                    shadowColor: _BtnColors.rejectGlow,
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

        // ── Next Student ────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: canNext ? onNext : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 22),
            label: const Text(
              'Next Student',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: canNext
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.2),
                width: canNext ? 1.5 : 1,
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
          Icon(Icons.timer_outlined, size: 18, color: _BtnColors.hold),
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
