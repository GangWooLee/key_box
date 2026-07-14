import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/backup/last_backup_store.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../domain/backup_export.dart';
import '../../domain/settings_preferences.dart';

/// The settings screen (DESIGN.md §settings): Bench/Terminal, a left section
/// rail + a right form. Surfaces existing backend that had no UI — the theme,
/// and the backup export that pairs with the restore path.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

enum _Section { appearance, security, preferences, backup }

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  _Section _section = _Section.appearance;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;

    return Scaffold(
      backgroundColor: s.canvas,
      body: Column(
        children: [
          _TopBar(),
          Expanded(
            child: Row(
              children: [
                _SectionRail(
                  selected: _section,
                  onSelect: (sec) => setState(() => _section = sec),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: switch (_section) {
                      _Section.appearance => const _AppearanceForm(),
                      _Section.security => const _SecurityForm(),
                      _Section.preferences => const _PreferencesForm(),
                      _Section.backup => const _BackupForm(),
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top bar ───

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: s.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => context.pop(),
            icon: Icon(LucideIcons.arrowLeft, size: 18, color: s.muted),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'SETTINGS',
            style: AppTypography.tableHeader.copyWith(color: s.muted),
          ),
        ],
      ),
    );
  }
}

// ─── Left section rail ───

class _SectionRail extends StatelessWidget {
  const _SectionRail({required this.selected, required this.onSelect});

  final _Section selected;
  final ValueChanged<_Section> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: s.tray,
        border: Border(right: BorderSide(color: s.hairline)),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _railItem(context, s, _Section.appearance, 'Appearance'),
          _railItem(context, s, _Section.security, 'Security'),
          _railItem(context, s, _Section.preferences, 'Preferences'),
          _railItem(context, s, _Section.backup, 'Backup'),
        ],
      ),
    );
  }

  Widget _railItem(
    BuildContext context,
    KbSurface s,
    _Section section,
    String label,
  ) {
    final active = section == selected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(section),
        hoverColor: s.hover,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: active ? s.hover : Colors.transparent,
            border: active
                ? Border(left: BorderSide(color: s.accent, width: 2))
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? s.accent : s.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Appearance form (theme) ───

class _AppearanceForm extends ConsumerWidget {
  const _AppearanceForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final mode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'THEME',
          style: AppTypography.tableHeader.copyWith(color: s.muted),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final option in const [
          (ThemeMode.light, 'Light — the Bench'),
          (ThemeMode.dark, 'Dark — the Terminal'),
          (ThemeMode.system, 'Follow the system'),
        ])
          _ThemeOption(
            label: option.$2,
            selected: mode == option.$1,
            onTap: () =>
                ref.read(themeModeProvider.notifier).setThemeMode(option.$1),
          ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: s.hover,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                selected ? LucideIcons.checkCircle : LucideIcons.circle,
                size: 16,
                color: selected ? s.accent : s.muted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(color: s.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Security form (change master password → key rotation) ───

class _SecurityForm extends ConsumerStatefulWidget {
  const _SecurityForm();

  @override
  ConsumerState<_SecurityForm> createState() => _SecurityFormState();
}

class _SecurityFormState extends ConsumerState<_SecurityForm> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _success = false;
  String? _message;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final error = await ref
        .read(authProvider.notifier)
        .changePassword(
          oldPassword: _current.text,
          newPassword: _next.text,
          confirmation: _confirm.text,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _success = error == null;
      _message = error ?? 'password changed';
      if (_success) {
        _current.clear();
        _next.clear();
        _confirm.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHANGE MASTER PASSWORD',
          style: AppTypography.tableHeader.copyWith(color: s.muted),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Rotates the key that protects your vault. Your secrets are re-sealed '
          'under the new password.',
          style: AppTypography.bodySmall.copyWith(color: s.muted),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(s, 'current password', _current),
              const SizedBox(height: AppSpacing.sm),
              _field(s, 'new password', _next),
              const SizedBox(height: AppSpacing.sm),
              _field(
                s,
                'confirm new password',
                _confirm,
                onSubmit: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: s.accent,
                    foregroundColor: s.onAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                  child: _busy
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: s.onAccent,
                          ),
                        )
                      : Text(
                          'Change password',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: s.onAccent,
                          ),
                        ),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _message!,
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    color: _success ? s.accent : s.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(
    KbSurface s,
    String label,
    TextEditingController controller, {
    ValueChanged<String>? onSubmit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.tableHeader.copyWith(color: s.muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            obscureText: true,
            onSubmitted: onSubmit,
            style: AppTypography.mono.copyWith(color: s.ink),
            decoration: InputDecoration(
              filled: true,
              fillColor: s.canvas,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: BorderSide(color: s.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: BorderSide(color: s.accent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Preferences form (auto-lock + reveal default) ───

class _PreferencesForm extends ConsumerWidget {
  const _PreferencesForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final autoLock = ref.watch(autoLockMinutesProvider);
    final revealDefault = ref.watch(revealByDefaultProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AUTO-LOCK',
          style: AppTypography.tableHeader.copyWith(color: s.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Lock the vault after this much idle time.',
          style: AppTypography.bodySmall.copyWith(color: s.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final minutes in autoLockOptions)
              _Chip(
                label: '${minutes}m',
                selected: autoLock == minutes,
                onTap: () =>
                    ref.read(autoLockMinutesProvider.notifier).set(minutes),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'REVEAL',
          style: AppTypography.tableHeader.copyWith(color: s.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                'Show secret values immediately when opened',
                style: AppTypography.bodySmall.copyWith(color: s.ink),
              ),
            ),
            Switch(
              value: revealDefault,
              activeThumbColor: s.onAccent,
              activeTrackColor: s.accent,
              onChanged: (v) =>
                  ref.read(revealByDefaultProvider.notifier).set(v),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? s.accent : s.canvas,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: selected ? s.accent : s.hairline),
          ),
          child: Text(
            label,
            style: AppTypography.mono.copyWith(
              fontSize: 12,
              color: selected ? s.onAccent : s.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Backup form (export) ───

class _BackupForm extends ConsumerStatefulWidget {
  const _BackupForm();

  @override
  ConsumerState<_BackupForm> createState() => _BackupFormState();
}

class _BackupFormState extends ConsumerState<_BackupForm> {
  bool _busy = false;
  String? _status;

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final archive = await ref.read(vaultArchiveBuilderProvider)();
      if (archive == null) {
        if (mounted) setState(() => _status = "couldn't read the vault");
        return;
      }
      final saved = await ref.read(backupFileSaverProvider)(archive);
      if (!mounted) return;
      if (saved) {
        await ref.read(lastBackupProvider.notifier).record(DateTime.now());
        if (mounted) setState(() => _status = 'backup saved');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final lastBackup = ref.watch(lastBackupProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BACKUP',
          style: AppTypography.tableHeader.copyWith(color: s.muted),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Export an encrypted .kbx archive you can restore from later.',
          style: AppTypography.bodySmall.copyWith(color: s.muted),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 36,
          child: ElevatedButton(
            onPressed: _busy ? null : _export,
            style: ElevatedButton.styleFrom(
              backgroundColor: s.accent,
              foregroundColor: s.onAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            child: _busy
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: s.onAccent,
                    ),
                  )
                : Text(
                    'Export backup',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: s.onAccent,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _status ??
              (lastBackup == null
                  ? 'never backed up'
                  : 'last backup ${DateFormatters.timeAgo(lastBackup)}'),
          style: AppTypography.mono.copyWith(fontSize: 11, color: s.muted),
        ),
      ],
    );
  }
}
