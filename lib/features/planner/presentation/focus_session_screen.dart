import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../utils/planner_utils.dart';

class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({super.key, required this.block});
  final TimeBlock block;

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  bool _running = false;
  bool _started = false;
  int _elapsed = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _started = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _resume() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
    });
    setState(() => _running = true);
  }

  void _stop() {
    _timer?.cancel();
    Navigator.pop(context);
  }

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = categoryStyle(widget.block.category);
    final block = widget.block;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _stop,
        ),
        title: Text(block.name,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_outlined), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: _started ? _timerView(color, icon) : _detailView(color, icon),
      ),
    );
  }

  Widget _detailView(Color color, IconData icon) {
    final block = widget.block;
    return ListView(
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.8),
                  color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 44),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          block.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          '${displayTime(block.startTime)} – ${displayTime(block.endTime)}',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _freqLabel(block.frequency),
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (block.description != null &&
            block.description!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            block.description!,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
        _statRow('Duration', displayDuration(block.startTime, block.endTime)),
        _statRow('Category', block.category),
        _statRow('Frequency', _freqLabel(block.frequency)),
        const SizedBox(height: 48),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF5B21B6),
                AppColors.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _start,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_filled_rounded,
                      color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Start Focus Session',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _timerView(Color color, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(icon, color: color, size: 36),
        ),
        const SizedBox(height: 20),
        Text(
          widget.block.name,
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 40),
        Text(
          _fmt(_elapsed),
          style: TextStyle(
            color: color,
            fontSize: 72,
            fontWeight: FontWeight.w200,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ends at ${displayTime(widget.block.endTime)}',
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 56),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CircleButton(
              icon: Icons.stop_rounded,
              color: AppColors.red,
              onTap: _stop,
              label: 'Stop',
            ),
            const SizedBox(width: 32),
            _CircleButton(
              icon: _running
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: color,
              onTap: _running ? _pause : _resume,
              label: _running ? 'Pause' : 'Resume',
              large: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _freqLabel(String f) => switch (f) {
        'daily' => 'Daily',
        'weekdays' => 'Weekdays',
        'weekends' => 'Weekends',
        _ => 'Any day',
      };
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.label,
    this.large = false,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 52.0;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: large ? 32 : 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}
