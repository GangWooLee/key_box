import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/crypto_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/auth_notifier.dart';

/// The Slab setup screen (DESIGN.md §"setup(Slab)") — first vault creation.
///
/// Same sealed grammar as unlock (no chrome, mono wordmark, pilot light,
/// tray inputs) with different copy (`CREATE MASTER PASSWORD`), a confirm
/// field, and a non-blocking strength hint. Touch ID affordance space is
/// reserved here too. All colors come from [KbSurface] tokens only.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  /// Below this length the (non-blocking) weak hint shows. Blocking minimum
  /// stays [CryptoConstants.minPasswordLength] via the validator.
  static const _strongLength = 12;

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pilot light + weak hint react to focus/typing.
    _passwordFocus.addListener(_onChanged);
    _confirmFocus.addListener(_onChanged);
    _passwordController.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.removeListener(_onChanged);
    _confirmFocus.removeListener(_onChanged);
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final error = await ref
          .read(authProvider.notifier)
          .setup(
            password: _passwordController.text,
            confirmation: _confirmController.text,
          );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = error;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Setup failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;

    return Scaffold(
      backgroundColor: s.canvas,
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 320,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _wordmark(s),
                  const SizedBox(height: AppSpacing.xxl),
                  _passwordRow(s),
                  const SizedBox(height: AppSpacing.md),
                  _confirmRow(s),
                  const SizedBox(height: AppSpacing.md),
                  _statusLine(s),
                  const SizedBox(height: AppSpacing.lg),
                  _createButton(s),
                  const SizedBox(height: AppSpacing.md),
                  _noRecoveryNote(s),
                  const SizedBox(height: AppSpacing.xl),
                  _touchIdAffordance(s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Pieces (sealed grammar shared with unlock_screen) ───

  Widget _wordmark(KbSurface s) {
    return Text(
      'KEY_BOX',
      textAlign: TextAlign.center,
      style: AppTypography.logoText.copyWith(color: s.muted),
    );
  }

  Widget _pilotDot(KbSurface s) {
    // Standby lamp — ignites while either field is awake.
    final lit = _passwordFocus.hasFocus || _confirmFocus.hasFocus || _isLoading;
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

  Widget _passwordRow(KbSurface s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _pilotDot(s),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _field(
            s,
            controller: _passwordController,
            focusNode: _passwordFocus,
            hint: 'master password',
            obscure: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            autofocus: true,
            validator: (value) {
              if (value == null ||
                  value.length < CryptoConstants.minPasswordLength) {
                return 'At least ${CryptoConstants.minPasswordLength} characters';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _confirmRow(KbSurface s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Aligns the confirm field under the password field (dot width).
        const SizedBox(width: 7),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _field(
            s,
            controller: _confirmController,
            focusNode: _confirmFocus,
            hint: 'confirm password',
            obscure: _obscureConfirm,
            onToggleObscure: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleSetup(),
          ),
        ),
      ],
    );
  }

  Widget _field(
    KbSurface s, {
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleObscure,
    String? Function(String?)? validator,
    ValueChanged<String>? onFieldSubmitted,
    bool autofocus = false,
  }) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: c),
    );

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      autofocus: autofocus,
      enabled: !_isLoading,
      cursorColor: s.live,
      style: AppTypography.mono.copyWith(color: s.ink),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        filled: true,
        // Rise to the lamp face on focus.
        fillColor: focusNode.hasFocus ? s.lamp : s.tray,
        hintText: hint,
        hintStyle: AppTypography.mono.copyWith(color: s.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        enabledBorder: border(s.hairline),
        disabledBorder: border(s.hairline),
        focusedBorder: border(s.accent),
        errorBorder: border(s.error),
        focusedErrorBorder: border(s.error),
        errorStyle: AppTypography.authInputLabel.copyWith(color: s.error),
        suffixIcon: IconButton(
          tooltip: obscure ? 'Show password' : 'Hide password',
          icon: Icon(
            obscure ? LucideIcons.eyeOff : LucideIcons.eye,
            size: 16,
            color: s.muted,
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }

  Widget _statusLine(KbSurface s) {
    const mono = AppTypography.authInputLabel;
    if (_error != null) {
      // Calm clay — never an alarm.
      return Text(
        _error!,
        textAlign: TextAlign.center,
        style: mono.copyWith(color: s.error, letterSpacing: 1.0),
      );
    }
    // Non-blocking strength hint (DESIGN.md: 약하면 muted mono 한 줄).
    final password = _passwordController.text;
    if (password.length >= CryptoConstants.minPasswordLength &&
        password.length < _strongLength) {
      return Text(
        'weak — a longer password is stronger',
        textAlign: TextAlign.center,
        style: mono.copyWith(color: s.muted, letterSpacing: 1.0),
      );
    }
    return Text(
      'CREATE MASTER PASSWORD',
      textAlign: TextAlign.center,
      style: mono.copyWith(color: s.muted, letterSpacing: 1.5),
    );
  }

  Widget _createButton(KbSurface s) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSetup,
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
                'Create Vault',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: s.onAccent,
                ),
              ),
      ),
    );
  }

  Widget _noRecoveryNote(KbSurface s) {
    // The one hard truth, stated quietly — no warning box, no alarm icon.
    return Text(
      'forgotten passwords cannot be recovered',
      textAlign: TextAlign.center,
      style: AppTypography.authInputLabel.copyWith(
        color: s.muted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _touchIdAffordance(KbSurface s) {
    // Reserved placeholder for the C-card Touch ID work — disabled.
    // The dot is a widget, not a glyph: Plex Mono lacks ◉/● and renders tofu.
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
}
