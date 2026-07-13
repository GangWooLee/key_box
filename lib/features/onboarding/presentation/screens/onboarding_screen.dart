import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../secrets/domain/secrets_providers.dart';

/// Onboarding — starts on the Slab surface (DESIGN.md §onboarding) and hands
/// off to the bench/terminal dashboard on completion.
///
/// NOTE (deferred): the 320ms signature "lights come on" sweep into the bench
/// belongs to the unlock-motion pass — completion currently switches surfaces
/// immediately. Step structure and logic are V8-preserved; only surface tokens
/// and typography are V9.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 2 fields
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  bool _isSaving = false;
  String? _saveError;

  // Cached default folder ID — fetched once in initState
  int? _defaultFolderId;

  @override
  void initState() {
    super.initState();
    _loadDefaultFolder();
  }

  Future<void> _loadDefaultFolder() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthUnlocked) return;
    final db = ref.read(databaseProvider);
    final folders = await db.folderDao.getByVaultId(auth.vaultId);
    if (folders.isNotEmpty && mounted) {
      setState(() => _defaultFolderId = folders.first.id);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _goToStep(int step) async {
    // Animate first, then update chrome (buttons/dots) when animation completes
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    if (mounted) setState(() => _currentStep = step);
  }

  Future<void> _addSecret() async {
    final name = _nameController.text.trim();
    final value = _valueController.text.trim();
    if (name.isEmpty || value.isEmpty) {
      setState(() => _saveError = 'Both fields are required');
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    if (_defaultFolderId == null) {
      setState(() {
        _isSaving = false;
        _saveError = 'No folder available. Please restart the app.';
      });
      return;
    }

    final ops = ref.read(secretOpsProvider);
    final result = await ops.create(
      name: name,
      value: value,
      folderId: _defaultFolderId!,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    switch (result) {
      case Success():
        _goToStep(2);
      case Failure(:final message):
        setState(() => _saveError = message);
    }
  }

  void _finishOnboarding() {
    ref.read(authProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;

    return Scaffold(
      backgroundColor: s.canvas,
      body: Center(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // All steps use uniform height to avoid layout jumps during animation
              SizedBox(
                height: 260,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildWelcomeStep(s),
                    _buildFirstSecretStep(s),
                    _buildShortcutsStep(s),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _StepDots(current: _currentStep, total: 3),
              const SizedBox(height: AppSpacing.lg),
              _buildActions(s),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 1: Welcome ─────────────────────────

  Widget _buildWelcomeStep(KbSurface s) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Wordmark instead of a key icon — no security iconography.
        Text(
          'KEY_BOX',
          textAlign: TextAlign.center,
          style: AppTypography.logoText.copyWith(color: s.ink),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Welcome to KeyBox',
          style: AppTypography.titleMedium.copyWith(color: s.ink),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: 280,
          child: Text(
            'Your secure vault for API keys and credentials',
            style: AppTypography.bodySmall.copyWith(color: s.muted),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // ─── Step 2: First Secret ────────────────────

  Widget _buildFirstSecretStep(KbSurface s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add your first secret',
          style: AppTypography.titleMedium.copyWith(color: s.ink),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'You can always add more later',
          style: AppTypography.bodySmall.copyWith(color: s.muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg - 4),
        const _FieldLabel(text: 'NAME'),
        const SizedBox(height: 6),
        _StepField(
          controller: _nameController,
          hint: 'e.g., Stripe API Key',
          autofocus: true,
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        const _FieldLabel(text: 'VALUE'),
        const SizedBox(height: 6),
        _StepField(
          controller: _valueController,
          hint: 'e.g., sk_live_...',
          isMono: true,
        ),
        if (_saveError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _saveError!,
            style: AppTypography.authInputLabel.copyWith(color: s.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ─── Step 3: Shortcuts ───────────────────────

  Widget _buildShortcutsStep(KbSurface s) {
    return Column(
      children: [
        Text(
          'Quick Shortcuts',
          style: AppTypography.titleMedium.copyWith(color: s.ink),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Master these to work faster',
          style: AppTypography.bodySmall.copyWith(color: s.muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg - 4),
        const _ShortcutRow(keyLabel: 'K', label: 'Search secrets'),
        const SizedBox(height: AppSpacing.sm),
        const _ShortcutRow(keyLabel: 'N', label: 'New secret'),
        const SizedBox(height: AppSpacing.sm),
        const _ShortcutRow(keyLabel: 'C', label: 'Copy value'),
      ],
    );
  }

  // ─── Action Buttons ──────────────────────────

  ButtonStyle _primaryStyle(KbSurface s) => ElevatedButton.styleFrom(
    backgroundColor: s.accent,
    foregroundColor: s.onAccent,
    disabledBackgroundColor: s.accent.withValues(alpha: 0.4),
    disabledForegroundColor: s.onAccent.withValues(alpha: 0.4),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
  );

  Widget _buildActions(KbSurface s) {
    return switch (_currentStep) {
      0 => SizedBox(
        width: 200,
        height: 40,
        child: ElevatedButton(
          onPressed: () => _goToStep(1),
          style: _primaryStyle(s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: s.onAccent,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(LucideIcons.arrowRight, size: 16),
            ],
          ),
        ),
      ),

      1 => Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _addSecret,
                style: _primaryStyle(s),
                child: _isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: s.onAccent,
                        ),
                      )
                    : Text(
                        'Add Secret',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: s.onAccent,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          TextButton(
            onPressed: _isSaving ? null : () => _goToStep(2),
            child: Row(
              children: [
                Text(
                  'Skip',
                  style: AppTypography.bodySmall.copyWith(color: s.muted),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(LucideIcons.arrowRight, size: 14, color: s.muted),
              ],
            ),
          ),
        ],
      ),

      2 => SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton(
          onPressed: _finishOnboarding,
          style: _primaryStyle(s),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Go to Dashboard',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: s.onAccent,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(LucideIcons.arrowRight, size: 16),
            ],
          ),
        ),
      ),

      _ => const SizedBox.shrink(),
    };
  }
}

// ─── Field label (mono caption, uppercase) ──────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Text(
      text,
      style: AppTypography.authInputLabel.copyWith(color: s.muted),
    );
  }
}

// ─── Step 2 input (tray field, sealed grammar) ──

class _StepField extends StatelessWidget {
  const _StepField({
    required this.controller,
    required this.hint,
    this.isMono = false,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool isMono;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: c),
    );

    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        cursorColor: s.live,
        style: (isMono ? AppTypography.mono : AppTypography.bodySmall).copyWith(
          color: s.ink,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: s.tray,
          hintText: hint,
          hintStyle: (isMono ? AppTypography.mono : AppTypography.bodySmall)
              .copyWith(color: s.muted, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 6,
            vertical: AppSpacing.sm + 2,
          ),
          enabledBorder: border(s.hairline),
          focusedBorder: border(s.accent),
        ),
      ),
    );
  }
}

// ─── Step Dots (status dots — full radius allowed) ──

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Semantics(
      label: 'Step ${current + 1} of $total',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final isActive = i == current;
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Active = live phosphor; inactive = dormant muted.
              color: isActive ? s.live : s.muted.withValues(alpha: 0.3),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Shortcut Row ────────────────────────────────

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.keyLabel, required this.label});

  /// The letter key after ⌘ (the ⌘ itself is a Lucide icon — Plex Mono has
  /// no U+2318 glyph and renders tofu).
  final String keyLabel;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: s.tray,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: s.hairline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: s.lamp,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: s.hairline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.command, size: 11, color: s.ink),
                const SizedBox(width: 2),
                Text(
                  keyLabel,
                  style: AppTypography.mono.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: s.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Text(label, style: AppTypography.bodySmall.copyWith(color: s.muted)),
        ],
      ),
    );
  }
}
