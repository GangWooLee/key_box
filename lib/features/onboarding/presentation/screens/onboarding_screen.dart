import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../secrets/domain/secrets_providers.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurfaceSecondary : null,
      body: Center(
        child: _AuthCard(
          width: 420,
          isDark: isDark,
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
                    _buildWelcomeStep(isDark),
                    _buildFirstSecretStep(isDark),
                    _buildShortcutsStep(isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _StepDots(current: _currentStep, total: 3, isDark: isDark),
              const SizedBox(height: 24),
              _buildActions(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 1: Welcome ─────────────────────────

  Widget _buildWelcomeStep(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.keyRound, size: 48, color: AppColors.brand500),
        const SizedBox(height: 16),
        Text(
          'Welcome to KeyBox',
          style: AppTypography.titleMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 280,
          child: Text(
            'Your secure vault for API keys and credentials',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // ─── Step 2: First Secret ────────────────────

  Widget _buildFirstSecretStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add your first secret',
          style: AppTypography.titleMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'You can always add more later',
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Name
        Text(
          'Name',
          style: AppTypography.authInputLabel.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextField(
            controller: _nameController,
            autofocus: true,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? AppColors.authInputBg : null,
              hintText: 'e.g., Stripe API Key',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Value
        Text(
          'Value',
          style: AppTypography.authInputLabel.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextField(
            controller: _valueController,
            style: AppTypography.mono.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? AppColors.authInputBg : null,
              hintText: 'e.g., sk_live_...',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
        ),

        if (_saveError != null) ...[
          const SizedBox(height: 8),
          Text(
            _saveError!,
            style: AppTypography.caption.copyWith(color: AppColors.errorText),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ─── Step 3: Shortcuts ───────────────────────

  Widget _buildShortcutsStep(bool isDark) {
    return Column(
      children: [
        Text(
          'Quick Shortcuts',
          style: AppTypography.titleMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Master these to work faster',
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        _ShortcutRow(shortcut: '⌘K', label: 'Search secrets', isDark: isDark),
        const SizedBox(height: 8),
        _ShortcutRow(shortcut: '⌘N', label: 'New secret', isDark: isDark),
        const SizedBox(height: 8),
        _ShortcutRow(shortcut: '⌘C', label: 'Copy value', isDark: isDark),
      ],
    );
  }

  // ─── Action Buttons ──────────────────────────

  static final _buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.buttonPrimary,
    foregroundColor: AppColors.buttonPrimaryText,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  Widget _buildActions(bool isDark) {
    return switch (_currentStep) {
      0 => SizedBox(
        width: 200,
        height: 44,
        child: ElevatedButton(
          onPressed: () => _goToStep(1),
          style: _buttonStyle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.buttonPrimaryText,
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
              height: 44,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _addSecret,
                style: _buttonStyle,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.buttonPrimaryText,
                        ),
                      )
                    : Text(
                        'Add Secret',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.buttonPrimaryText,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: _isSaving ? null : () => _goToStep(2),
            child: Row(
              children: [
                Text(
                  'Skip',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.arrowRight,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                ),
              ],
            ),
          ),
        ],
      ),

      2 => SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: _finishOnboarding,
          style: _buttonStyle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Go to Dashboard',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.buttonPrimaryText,
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

// ─── Auth Card (shared decoration for auth/onboarding screens) ──

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.width,
    required this.isDark,
    required this.child,
  });
  final double width;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.authCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.authCardStroke
              : AppColors.lightBorderPrimary,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Step Dots ───────────────────────────────────

class _StepDots extends StatelessWidget {
  const _StepDots({
    required this.current,
    required this.total,
    required this.isDark,
  });
  final int current;
  final int total;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${current + 1} of $total',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final isActive = i == current;
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColors.brand500
                  : isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.15),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Shortcut Row ────────────────────────────────

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({
    required this.shortcut,
    required this.label,
    required this.isDark,
  });
  final String shortcut;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: AppTypography.mono.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
