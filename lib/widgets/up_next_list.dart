import 'package:flutter/material.dart';
import '../models/token_model.dart';
import '../theme/app_theme.dart';

/// Displays the next N students waiting in the queue
class UpNextList extends StatelessWidget {
  final List<TokenModel> tokens;
  final int currentServing;

  const UpNextList({
    super.key,
    required this.tokens,
    required this.currentServing,
  });

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: GlassDecoration.card(opacity: 0.05),
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No students waiting',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: GlassDecoration.card(opacity: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.format_list_numbered_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Up Next',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tokens.length} waiting',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            color: AppColors.surfaceLight,
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          // List of students
          ...tokens.asMap().entries.map((entry) {
            final index = entry.key;
            final token = entry.value;
            final isNext = index == 0;

            return _StudentTile(
              token: token,
              isNext: isNext,
              index: index,
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final TokenModel token;
  final bool isNext;
  final int index;

  const _StudentTile({
    required this.token,
    required this.isNext,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isNext
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isNext
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          // Token number badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isNext
                  ? AppColors.primary
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${token.tokenNumber}',
                style: TextStyle(
                  color: isNext ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Student name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  token.studentName,
                  style: TextStyle(
                    color: isNext
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isNext ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
                if (isNext)
                  const Text(
                    'Next in line',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // Time waiting
          Text(
            _formatWaitTime(token.joinedAt),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatWaitTime(DateTime joinedAt) {
    final diff = DateTime.now().difference(joinedAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }
}
