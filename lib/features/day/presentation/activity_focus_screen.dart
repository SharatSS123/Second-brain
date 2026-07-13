import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../planner/providers/planner_providers.dart';
import '../../planner/utils/planner_utils.dart';

class ActivityFocusScreen extends ConsumerStatefulWidget {
  const ActivityFocusScreen({super.key, required this.activity});
  final PlannerActivity activity;

  @override
  ConsumerState<ActivityFocusScreen> createState() => _ActivityFocusScreenState();
}

class _ActivityFocusScreenState extends ConsumerState<ActivityFocusScreen>
    with SingleTickerProviderStateMixin {
  late int _totalDurationSeconds;
  late int _secondsLeft;
  Timer? _timer;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initTimer();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 4.0, end: 16.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _initTimer() {
    final now = DateTime.now();
    final parts = widget.activity.endTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final targetTime = DateTime(now.year, now.month, now.day, hour, minute);

    final diff = targetTime.difference(now).inSeconds;
    _secondsLeft = diff > 0 ? diff : 0;

    // Calculate total duration of block
    final sParts = widget.activity.startTime.split(':');
    final sHour = int.parse(sParts[0]);
    final sMinute = int.parse(sParts[1]);
    final startTime = DateTime(now.year, now.month, now.day, sHour, sMinute);
    _totalDurationSeconds = targetTime.difference(startTime).inSeconds;
    if (_totalDurationSeconds <= 0) _totalDurationSeconds = 3600; // default 1h fallback

    if (_secondsLeft > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_secondsLeft > 0) {
            _secondsLeft--;
          } else {
            _timer?.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _completeActivity() async {
    try {
      await ref
          .read(plannerRepositoryProvider)
          .toggleComplete(widget.activity.id, widget.activity.isCompleted);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity completed! Great focus! 🎉'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete activity: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, _) = categoryStyle(widget.activity.category);

    final progress = _totalDurationSeconds > 0
        ? (_secondsLeft / _totalDurationSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Focus Session',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Title
              Text(
                widget.activity.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.activity.category.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),

              // Glowing circular progress timer
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.2),
                              blurRadius: _glowAnimation.value,
                              spreadRadius: _glowAnimation.value / 4,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 210,
                              height: 210,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 10,
                                backgroundColor: AppColors.border.withValues(alpha: 0.5),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatDuration(_secondsLeft),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w200,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _secondsLeft > 0 ? 'REMAINING' : "TIME'S UP",
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Complete Button at bottom
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _completeActivity,
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Complete Activity',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
