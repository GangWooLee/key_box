import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/motion.dart';
import '../../domain/auth_notifier.dart';
import '../../domain/auth_state.dart';

/// The signature "lights come on" moment (DESIGN.md §Motion).
///
/// On any sealed → unlocked transition a slab-colored cover is painted over
/// the app and a diagonal (top-left → bottom-right) light front washes it
/// away over 320ms `easeOutExpo`, revealing the content **already rendered
/// on the new surface** in place — nothing slides (침착 유지). Locking has no
/// motion: the sweep only fires toward open, never back.
///
/// Reduced motion (`MediaQuery.disableAnimations`) replaces the sweep with a
/// 120ms uniform crossfade of the same cover.
///
/// Mounted once around the app via `MaterialApp.router(builder: ...)`. While
/// idle the overlay widget is absent from the tree entirely — no hit-test or
/// semantics pollution.
class UnlockSweep extends ConsumerStatefulWidget {
  const UnlockSweep({super.key, required this.child});

  final Widget child;

  /// Test hook: identifies the transient sweep cover overlay.
  static const coverKey = ValueKey('unlock-sweep-cover');

  @override
  ConsumerState<UnlockSweep> createState() => _UnlockSweepState();
}

class _UnlockSweepState extends ConsumerState<UnlockSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _fadeMode = false;

  /// The sealed canvas the front washes away. Resolved once through the
  /// theme compiler (no duplicated hex) — the slab is a constant surface.
  static final Color _slab = AppTheme.sealed().extension<KbSurface>()!.canvas;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.signature,
    );
    _controller.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {}); // sweep done — drop the overlay from the tree
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    _fadeMode = reduce;
    _controller.duration = reduce ? AppMotion.snap : AppMotion.signature;
    _controller.forward(from: 0);
    setState(() {}); // mount the overlay for this sweep
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      final wasSealed =
          prev is AuthLocked || prev is AuthFirstRun || prev is AuthVaultError;
      if (wasSealed && next is AuthUnlocked) _start();
    });

    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (_controller.isAnimating)
          Positioned.fill(
            key: UnlockSweep.coverKey,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _SweepCoverPainter(
                    t: Curves.easeOutExpo.transform(_controller.value),
                    slab: _slab,
                    fade: _fadeMode,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Paints the receding slab cover.
///
/// Sweep mode: a diagonal gradient whose transparent side grows from the
/// top-left — colors `[clear, clear, slab, slab]` with a soft front edge of
/// width [_edge] around the front position `p`. `p` runs `-e → 1+e` so the
/// cover is fully opaque at t=0 and fully gone at t=1.
///
/// Fade mode (reduced motion): a uniform slab fill at opacity `1 - t`.
class _SweepCoverPainter extends CustomPainter {
  _SweepCoverPainter({required this.t, required this.slab, required this.fade});

  final double t;
  final Color slab;
  final bool fade;

  /// Soft-edge half-width of the light front, as a fraction of the diagonal.
  static const _edge = 0.12;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    if (fade) {
      canvas.drawRect(
        rect,
        Paint()..color = slab.withValues(alpha: (1 - t).clamp(0.0, 1.0)),
      );
      return;
    }

    final p = t * (1 + 2 * _edge) - _edge;
    // Transparent stop uses slab-at-zero-alpha so the gradient never
    // interpolates through transparent-black (no dark fringe on the front).
    final clear = slab.withValues(alpha: 0.0);
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [clear, clear, slab, slab],
      stops: [
        0.0,
        (p - _edge).clamp(0.0, 1.0),
        (p + _edge).clamp(0.0, 1.0),
        1.0,
      ],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_SweepCoverPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.fade != fade ||
      oldDelegate.slab != slab;
}
