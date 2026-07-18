import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/backup/vault_recovery_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../domain/auth_notifier.dart';
import '../../domain/backup_file_picker.dart';

/// The restore-from-backup screen (DESIGN.md §restore-from-backup): the vault's
/// only out-trust recovery path. Stays on the sealed Slab — recovery is still
/// a closed vault — through three steps: ①pick a `.kbx` file ②master password
/// ③integrity check. Success flips auth to unlocked and the router redirects
/// away (the signature sweep plays); failure stays with a calm clay reason
/// distinguishing a damaged file (손상) from a wrong password (오답).
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

enum _Step { pick, password, checking }

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  final _passwordController = TextEditingController();
  final _focusNode = FocusNode();

  _Step _step = _Step.pick;
  PickedBackup? _backup;
  bool _obscure = true;
  String? _error; // clay reason for the current step

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _error = null);
    try {
      final picked = await ref.read(backupFilePickerProvider)();
      if (picked == null || !mounted) return; // cancelled
      setState(() {
        _backup = picked;
        _step = _Step.password;
      });
      _focusNode.requestFocus();
    } catch (_) {
      if (mounted) setState(() => _error = "couldn't read that file");
    }
  }

  Future<void> _restore() async {
    final backup = _backup;
    if (backup == null || _passwordController.text.isEmpty) return;

    setState(() {
      _step = _Step.checking;
      _error = null;
    });

    final outcome = await ref
        .read(authProvider.notifier)
        .restoreFromBackup(
          archive: backup.contents,
          password: _passwordController.text,
        );
    if (!mounted) return;

    switch (outcome) {
      case RestoreSuccess():
        // Auth is now unlocked — the router redirect carries us to the
        // dashboard with the signature sweep. Nothing to do here.
        return;
      case RestoreWrongPassword():
        setState(() {
          _step = _Step.password;
          _error = "the password doesn't match this backup";
        });
        _passwordController.clear();
        _focusNode.requestFocus();
      case RestoreCorrupt():
        setState(() {
          _step = _Step.pick;
          _error = 'this backup is damaged';
          _backup = null;
          _passwordController.clear();
        });
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
              Text(
                'KEY_BOX',
                textAlign: TextAlign.center,
                style: AppTypography.logoText.copyWith(color: s.muted),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'RESTORE FROM BACKUP',
                textAlign: TextAlign.center,
                style: AppTypography.authInputLabel.copyWith(
                  color: s.muted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              switch (_step) {
                _Step.pick => _pickStep(s),
                _Step.password => _passwordStep(s),
                _Step.checking => _checkingStep(s),
              },
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.authInputLabel.copyWith(
                    color: s.error,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 1: pick a .kbx file ───

  Widget _pickStep(KbSurface s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'choose a .kbx backup archive',
          textAlign: TextAlign.center,
          style: AppTypography.mono.copyWith(fontSize: 12.5, color: s.muted),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: _pickFile,
            style: _primaryStyle(s),
            child: Text(
              'Choose file…',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: s.onAccent,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Exit path — restore is always PUSHED (from setup or vault-error), so
        // maybePop returns there; a no-op if somehow at the root (never trapped).
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(
              'Cancel',
              style: AppTypography.bodySmall.copyWith(color: s.muted),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step 2: master password ───

  Widget _passwordStep(KbSurface s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _backup?.name ?? '',
          textAlign: TextAlign.center,
          style: AppTypography.mono.copyWith(fontSize: 11, color: s.muted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 44,
          child: TextField(
            controller: _passwordController,
            focusNode: _focusNode,
            obscureText: _obscure,
            autofocus: true,
            cursorColor: s.live,
            style: AppTypography.mono.copyWith(color: s.ink),
            onSubmitted: (_) => _restore(),
            decoration: InputDecoration(
              filled: true,
              fillColor: s.tray,
              hintText: 'master password',
              hintStyle: AppTypography.mono.copyWith(color: s.muted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              enabledBorder: _border(s.hairline),
              focusedBorder: _border(s.accent),
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
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: _restore,
            style: _primaryStyle(s),
            child: Text(
              'Restore',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: s.onAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step 3: integrity check ───

  Widget _checkingStep(KbSurface s) {
    return Column(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: s.accent),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'checking integrity…',
          style: AppTypography.mono.copyWith(fontSize: 12.5, color: s.muted),
        ),
      ],
    );
  }

  ButtonStyle _primaryStyle(KbSurface s) => ElevatedButton.styleFrom(
    backgroundColor: s.accent,
    foregroundColor: s.onAccent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    ),
  );

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.md),
    borderSide: BorderSide(color: c),
  );
}
