import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Badge overlay showing unread message count
class InboxBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const InboxBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -6,
            top: -4,
            child: AnimatedScale(
              scale: count > 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.elasticOut,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
