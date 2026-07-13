import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/auth_notifier.dart';

/// The Slab unlock screen (DESIGN.md §"unlock(Slab)").
///
/// One central input, a pilot light, and a single mono hint line — no logo
/// wall, no card, no chrome. "Nothing begs for attention" is the trust signal.
/// The surface tokens come from [KbSurface]; when locked, `surfaceThemeProvider`
/// supplies the sealed Slab theme, so this screen never references colors or
/// branches on brightness.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen>
    with SingleTickerProviderStateMixin {
  static const _maxAttempts = 5;
  static const _lockoutSeconds = 30;

  final _passwordController = TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _shake;

  bool _obscure = true;
  bool _isLoading = false;
  String? _error;
  int _attempts = 0;
  int _lockoutRemaining = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    // Pilot light + focused fill react to focus changes.
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _shake.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock() async {
    if (_lockoutRemaining > 0 || _passwordController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final error = await ref
          .read(authProvider.notifier)
          .unlock(password: _passwordController.text);
      if (!mounted) return;

      if (error == null) {
        // Success — the router redirects away from this screen.
        setState(() => _isLoading = false);
        return;
      }

      _attempts++;
      setState(() {
        _isLoading = false;
        _error = error;
      });
      _passwordController.clear();
      _triggerShake();
      if (_attempts >= _maxAttempts) _startLockout();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unlock failed: $e';
      });
      _triggerShake();
    }
  }

  void _triggerShake() {
    // Respect reduce-motion: skip the shake, keep the clay message.
    if (MediaQuery.disableAnimationsOf(context)) return;
    _shake.forward(from: 0);
  }

  void _startLockout() {
    setState(() => _lockoutRemaining = _lockoutSeconds);
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _lockoutRemaining--;
        if (_lockoutRemaining <= 0) {
          t.cancel();
          _attempts = 0;
          _error = null;
        }
      });
    });
  }

  Future<void> _handleDevReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Vault?'),
        content: const Text(
          'This will delete ALL data and return to initial setup.\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(authProvider.notifier).resetAndReinitialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;

    return Scaffold(
      backgroundColor: s.canvas,
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _wordmark(s),
              const SizedBox(height: AppSpacing.xxl),
              _inputRow(s),
              const SizedBox(height: AppSpacing.md),
              _statusLine(s),
              const SizedBox(height: AppSpacing.lg),
              _unlockButton(s),
              const SizedBox(height: AppSpacing.xl),
              _touchIdAffordance(s),
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.lg),
                _devReset(s),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Pieces ───

  Widget _wordmark(KbSurface s) {
    // Mono wordmark, muted — the dormant restraint of a sealed slab. No icon.
    return Text(
      'KEY_BOX',
      textAlign: TextAlign.center,
      style: AppTypography.logoText.copyWith(color: s.muted),
    );
  }

  Widget _inputRow(KbSurface s) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        // Damped 3-cycle horizontal shake, amplitude 8px over 240ms.
        final dx =
            math.sin(_shake.value * math.pi * 6) * 8 * (1 - _shake.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Row(
        children: [
          _pilotDot(s),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _field(s)),
        ],
      ),
    );
  }

  Widget _pilotDot(KbSurface s) {
    // Standby lamp: dormant accent → live phosphor when the field wakes.
    final lit = _focusNode.hasFocus || _isLoading;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? s.live : s.accent,
      ),
    );
  }

  Widget _field(KbSurface s) {
    final focused = _focusNode.hasFocus;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: c, width: w),
    );

    return SizedBox(
      height: 44,
      child: TextField(
        controller: _passwordController,
        focusNode: _focusNode,
        obscureText: _obscure,
        autofocus: true,
        enabled: _lockoutRemaining == 0,
        cursorColor: s.live,
        style: AppTypography.mono.copyWith(color: s.ink),
        onSubmitted: (_) => _handleUnlock(),
        decoration: InputDecoration(
          filled: true,
          // Rise to the lamp face on focus.
          fillColor: focused ? s.lamp : s.tray,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          enabledBorder: border(s.hairline),
          disabledBorder: border(s.hairline),
          focusedBorder: border(s.accent),
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Show password' : 'Hide password',
            icon: Icon(
              _obscure ? LucideIcons.eyeOff : LucideIcons.eye,
              size: 16,
              color: s.muted,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
    );
  }

  Widget _statusLine(KbSurface s) {
    const mono = AppTypography.authInputLabel;
    if (_lockoutRemaining > 0) {
      final secs = _lockoutRemaining.toString().padLeft(2, '0');
      return Text(
        'try again in 0:$secs',
        textAlign: TextAlign.center,
        style: mono.copyWith(color: s.muted, letterSpacing: 1.0),
      );
    }
    if (_error != null) {
      // Calm, clay — never an alarm.
      final message = _error == 'Incorrect password'
          ? 'The vault stays sealed'
          : _error!;
      return Text(
        message,
        textAlign: TextAlign.center,
        style: mono.copyWith(color: s.error, letterSpacing: 1.0),
      );
    }
    return Text(
      'MASTER PASSWORD · RETURN TO OPEN',
      textAlign: TextAlign.center,
      style: mono.copyWith(color: s.muted, letterSpacing: 1.5),
    );
  }

  Widget _unlockButton(KbSurface s) {
    final disabled = _isLoading || _lockoutRemaining > 0;
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: disabled ? null : _handleUnlock,
        style: ElevatedButton.styleFrom(
          backgroundColor: s.accent,
          foregroundColor: s.onAccent, // never hardcoded — Slab onAccent
          disabledBackgroundColor: s.accent.withValues(alpha: 0.4),
          disabledForegroundColor: s.onAccent.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: s.onAccent,
                ),
              )
            : Text(
                'Unlock',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: s.onAccent,
                ),
              ),
      ),
    );
  }

  Widget _touchIdAffordance(KbSurface s) {
    // Reserved placeholder for the C-card Touch ID work — disabled, non-clickable.
    // The dot is a widget, not a glyph: Plex Mono lacks ◉ and renders tofu.
    final label = AppTypography.authInputLabel.copyWith(
      color: s.muted,
      letterSpacing: 1.0,
    );
    return Center(
      child: Opacity(
        opacity: 0.4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('[ ', style: label),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: s.muted, shape: BoxShape.circle),
            ),
            Text(' touch id ]', style: label),
          ],
        ),
      ),
    );
  }

  Widget _devReset(KbSurface s) {
    // Destructive = outline error (no fill), per the components matrix.
    return Center(
      child: OutlinedButton(
        onPressed: _handleDevReset,
        style: OutlinedButton.styleFrom(
          foregroundColor: s.error,
          side: BorderSide(color: s.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
        child: Text(
          'DEV: Reset Vault',
          style: AppTypography.authInputLabel.copyWith(color: s.error),
        ),
      ),
    );
  }
}
