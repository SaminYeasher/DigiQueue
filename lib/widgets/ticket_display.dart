import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Large animated token number display widget.
/// Changes color and animations based on queue position.
class TicketDisplay extends StatefulWidget {
  final int tokenNumber;
  final int currentServing;
  final int peopleAhead;

  const TicketDisplay({
    super.key,
    required this.tokenNumber,
    required this.currentServing,
    required this.peopleAhead,
  });

  @override
  State<TicketDisplay> createState() => _TicketDisplayState();
}

class _TicketDisplayState extends State<TicketDisplay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _numberController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  int _displayedServing = 0;

  @override
  void initState() {
    super.initState();
    _displayedServing = widget.currentServing;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _numberController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _numberController, curve: Curves.elasticOut),
    );

    if (_isYourTurn) {
      _pulseController.repeat(reverse: true);
    }
    _numberController.forward();
  }

  @override
  void didUpdateWidget(TicketDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentServing != widget.currentServing) {
      _numberController.reset();
      _numberController.forward();
      setState(() => _displayedServing = widget.currentServing);
    }
    if (_isYourTurn && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_isYourTurn && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  bool get _isYourTurn => widget.peopleAhead == 0;
  bool get _isAlmostTurn => widget.peopleAhead <= 2 && !_isYourTurn;

  Color get _statusColor {
    if (_isYourTurn) return AppColors.success;
    if (_isAlmostTurn) return AppColors.warning;
    return AppColors.primary;
  }

  Color get _glowColor {
    if (_isYourTurn) return AppColors.successGlow;
    if (_isAlmostTurn) return AppColors.warningGlow;
    return AppColors.surfaceOverlay;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── "It's Your Turn!" Banner ──
        if (_isYourTurn)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: AppColors.successGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.celebration_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    "It's Your Turn!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Your Token Number ──
        Text(
          'YOUR TOKEN',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = _isYourTurn ? _pulseAnimation.value : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _statusColor,
                  _statusColor.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _statusColor.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${widget.tokenNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // ── Currently Serving ──
        Text(
          'CURRENTLY SERVING',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: GlassDecoration.elevated(glowColor: _statusColor),
            child: Text(
              '#$_displayedServing',
              style: TextStyle(
                color: _statusColor,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── People Ahead ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _glowColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _statusColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isYourTurn
                    ? Icons.arrow_forward_rounded
                    : Icons.people_outline_rounded,
                color: _statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isYourTurn
                    ? 'Head to the office now!'
                    : '${widget.peopleAhead} ${widget.peopleAhead == 1 ? 'person' : 'people'} ahead',
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
