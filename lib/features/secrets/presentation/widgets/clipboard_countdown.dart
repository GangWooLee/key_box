import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/secrets_providers.dart';

/// The quiet clipboard auto-clear countdown (DESIGN.md 보안 UX #3 — 조용한
/// 가시화). When a secret is copied, a conic ring drains alongside a mono
/// `clipboard clears in Ns` line, mirroring the service's 30s wipe timer.
///
/// Driven by a 1-second periodic ticker (not an `AnimationController`) so the
/// countdown remains real information under reduce-motion, not a decorative
/// animation that a11y settings would collapse to instant. Idle → the widget
/// takes no space (`SizedBox.shrink`).
class ClipboardCountdown extends ConsumerStatefulWidget {
  const ClipboardCountdown({super.key});

  /// Test hook: identifies the conic countdown ring while it is showing.
  static const ringKey = ValueKey('clipboard-countdown-ring');

  @override
  ConsumerState<ClipboardCountdown> createState() => _ClipboardCountdownState();
}

class _ClipboardCountdownState extends ConsumerState<ClipboardCountdown> {
  static const _total = AppConstants.clipboardClearSeconds;

  Timer? _ticker;
  int? _remaining; // null = idle (nothing pending)

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _restart() {
    _ticker?.cancel();
    setState(() => _remaining = _total);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        final next = (_remaining ?? 0) - 1;
        if (next <= 0) {
          _remaining = null; // wiped — the ring vanishes
          t.cancel();
        } else {
          _remaining = next;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(clipboardCopyEventProvider, (prev, next) {
      if (next > 0 && next != prev) _restart();
    });

    final remaining = _remaining;
    if (remaining == null) return const SizedBox.shrink();

    final s = Theme.of(context).extension<KbSurface>()!;
    return Semantics(
      label: 'Clipboard clears in $remaining seconds',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            key: ClipboardCountdown.ringKey,
            width: 12,
            height: 12,
            child: CustomPaint(
              painter: _RingPainter(
                fraction: remaining / _total,
                track: s.hairline,
                arc: s.accent,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xsm),
          Text(
            'clipboard clears in ${remaining}s',
            style: AppTypography.mono.copyWith(fontSize: 11, color: s.muted),
          ),
        ],
      ),
    );
  }
}

/// A thin conic ring that drains clockwise from full to empty as [fraction]
/// runs 1 → 0.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.track,
    required this.arc,
  });

  final double fraction;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1;
    final circle = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = track,
    );
    // From 12 o'clock (-π/2), sweep clockwise for the remaining fraction.
    canvas.drawArc(
      circle,
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.arc != arc || old.track != track;
}
