import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/database/database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../../domain/secrets_providers.dart';

/// Show a sheet-style modal for creating or editing a secret.
/// If [secret] is provided, the modal opens in edit mode.
///
/// V9 (DESIGN.md §create/edit secret): a lamp card floating on the surface
/// scrim — labels are mono captions above each field, inputs sit one tonal
/// step down (canvas), Save is the only filled button and stays disabled
/// until the form is dirty.
void showSecretSheetModal({
  required BuildContext context,
  required WidgetRef ref,
  Secret? secret,
}) {
  final s = Theme.of(context).extension<KbSurface>()!;
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: s.scrim,
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(child: _SecretSheetModal(secret: secret));
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class _SecretSheetModal extends ConsumerStatefulWidget {
  const _SecretSheetModal({this.secret});
  final Secret? secret;

  @override
  ConsumerState<_SecretSheetModal> createState() => _SecretSheetModalState();
}

class _SecretSheetModalState extends ConsumerState<_SecretSheetModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late final TextEditingController _serviceController;
  late final TextEditingController _notesController;
  late final FocusNode _escFocusNode;
  late String _secretType;
  late String? _environment;
  bool _showAdvanced = false;
  bool _saving = false;

  /// The folder the user explicitly picked in the create-mode selector. Null
  /// means "follow the default" — the currently viewed folder, else General.
  /// Only meaningful in create mode (edit mode never shows the selector).
  int? _userPickedFolderId;

  /// Value masking toggle. Masked = single-line obscured field; revealed =
  /// multiline mono (obscureText cannot span lines — paste multi-line values
  /// while revealed).
  bool _valueRevealed = true;

  String? _nameError;
  String? _valueError;

  /// The decrypted value at edit-entry, kept so Save can diff against it — an
  /// unchanged value must not rotate (bump recordVersion). Null until the
  /// post-frame decrypt lands (and always null in create mode).
  String? _originalValue;

  bool get _isEdit => widget.secret != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.secret?.name ?? '');
    _valueController = TextEditingController();
    _serviceController = TextEditingController(
      text: widget.secret?.serviceName ?? '',
    );
    _notesController = TextEditingController(text: widget.secret?.notes ?? '');
    _escFocusNode = FocusNode();
    _secretType = widget.secret?.secretType ?? 'api_key';
    _environment = widget.secret?.environment;
    for (final c in [
      _nameController,
      _valueController,
      _serviceController,
      _notesController,
    ]) {
      c.addListener(_onFormChanged);
    }
    if (_isEdit) {
      // Edit shows the current value (partial edit). Masked by default —
      // reveal parity with the detail panel. Decrypt after the first frame
      // (initState can't await); Save diffs against [_originalValue].
      _valueRevealed = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadValue());
    }
  }

  Future<void> _loadValue() async {
    final plain = await ref.read(secretOpsProvider).decrypt(widget.secret!);
    if (!mounted || plain == null) return;
    _originalValue = plain;
    // Setting .text fires the controller listener → setState, reflecting the
    // pre-filled (still not-dirty) value.
    _valueController.text = plain;
  }

  void _onFormChanged() {
    // Re-evaluate dirty state (Save enablement) and clear stale field errors.
    setState(() {
      if (_nameController.text.trim().isNotEmpty) _nameError = null;
      if (_valueController.text.isNotEmpty) _valueError = null;
    });
  }

  /// Save is enabled only when the form differs from its initial state
  /// (DESIGN.md: dirty 아니면 disabled).
  bool get _isDirty {
    final sec = widget.secret;
    if (sec == null) {
      return _nameController.text.isNotEmpty ||
          _valueController.text.isNotEmpty ||
          _serviceController.text.isNotEmpty ||
          _notesController.text.isNotEmpty ||
          _secretType != 'api_key' ||
          _environment != null ||
          _userPickedFolderId != null;
    }
    return _nameController.text != sec.name ||
        _valueController.text != (_originalValue ?? '') ||
        _serviceController.text != (sec.serviceName ?? '') ||
        _notesController.text != (sec.notes ?? '') ||
        _secretType != sec.secretType ||
        _environment != sec.environment;
  }

  /// The folder a create-mode Save should land in, given the [folders] the
  /// vault currently has. Priority: the user's explicit pick (if still valid)
  /// → the folder the dashboard is viewing (selectedFolderIdProvider) → General
  /// by name → the first folder. Null only when the vault has no folders yet
  /// (Save then mints a Default home — see [_save]).
  int? _effectiveFolderId(List<Folder> folders) {
    if (folders.isEmpty) return null;
    if (_userPickedFolderId != null &&
        folders.any((f) => f.id == _userPickedFolderId)) {
      return _userPickedFolderId;
    }
    final selected = ref.read(selectedFolderIdProvider);
    if (selected != null && folders.any((f) => f.id == selected)) {
      return selected;
    }
    final general = folders.where((f) => f.name == 'General');
    return general.isNotEmpty ? general.first.id : folders.first.id;
  }

  @override
  void dispose() {
    // Drop the change listeners BEFORE scrubbing, so blanking the controller
    // doesn't fire _onFormChanged → setState during teardown.
    for (final c in [
      _nameController,
      _valueController,
      _serviceController,
      _notesController,
    ]) {
      c.removeListener(_onFormChanged);
    }
    // Best-effort scrub of the decrypted plaintext (Dart String can't be truly
    // zeroed, but drop our reference and blank the controller buffer).
    _valueController.clear();
    _originalValue = null;
    _nameController.dispose();
    _valueController.dispose();
    _serviceController.dispose();
    _notesController.dispose();
    _escFocusNode.dispose();
    super.dispose();
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    } else if (event.logicalKey == LogicalKeyboardKey.enter &&
        HardwareKeyboard.instance.isMetaPressed) {
      // ⌘↩ — the shortcut the Save button badge advertises.
      if (!_saving && _isDirty) _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    // Folder selector (create mode only). Empty/absent list ⇒ graceful degrade
    // (selector not rendered — e.g. a locked/loading vault).
    final folders = ref.watch(foldersProvider).valueOrNull ?? const <Folder>[];

    return KeyboardListener(
      focusNode: _escFocusNode,
      onKeyEvent: _onKeyEvent,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 520,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            // Lamp card on the scrim — hairline + tonal jump carry the edge;
            // only a faint shadow (lamp faces may carry one, DESIGN.md).
            color: s.lamp,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: s.hairline),
            boxShadow: [
              BoxShadow(
                // Surface-aware shadow: the scrim's warm-dark base at shadow
                // strength — no untokenized black (silence on Terminal).
                color: s.scrim.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModalHeader(
                title: _isEdit ? 'Edit Secret' : 'Save New Key',
                onClose: () => Navigator.pop(context),
              ),

              // Form body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    28,
                    AppSpacing.lg - 4,
                    28,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ModalInput(
                        label: 'Title',
                        controller: _nameController,
                        hint: 'e.g. GitHub API Key',
                        autofocus: true,
                        errorText: _nameError,
                      ),
                      const SizedBox(height: AppSpacing.lg - 4),
                      _ModalInput(
                        label: 'Key Value',
                        controller: _valueController,
                        hint: 'Paste your secret here...',
                        maxLines: _valueRevealed ? 4 : 1,
                        obscureText: !_valueRevealed,
                        isMono: true,
                        errorText: _valueError,
                        suffixIcon: IconButton(
                          tooltip: _valueRevealed
                              ? 'Mask value'
                              : 'Reveal value',
                          // Icon mirrors STATE (revealed = open eye, masked =
                          // eyeOff), matching the auth screens; the tooltip
                          // carries the action.
                          icon: Icon(
                            _valueRevealed
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                            size: 14,
                            color: s.muted,
                          ),
                          onPressed: () =>
                              setState(() => _valueRevealed = !_valueRevealed),
                        ),
                      ),
                      // Folder selector — create mode only, always visible
                      // (never behind Advanced) so a category-view save can't
                      // silently file to General. Absent when the vault has no
                      // folders yet (graceful degrade).
                      if (!_isEdit && folders.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg - 4),
                        _ModalDropdown(
                          label: 'Folder',
                          value: _effectiveFolderId(folders)?.toString(),
                          items: <String?, String>{
                            for (final f in folders) f.id.toString(): f.name,
                          },
                          onChanged: (v) => setState(
                            () => _userPickedFolderId = int.tryParse(v ?? ''),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _AdvancedToggle(
                        expanded: _showAdvanced,
                        onTap: () =>
                            setState(() => _showAdvanced = !_showAdvanced),
                      ),
                      if (_showAdvanced) ...[
                        const SizedBox(height: AppSpacing.md),
                        _ModalInput(
                          label: 'Service',
                          controller: _serviceController,
                          hint: 'e.g. GitHub, AWS, Stripe',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ModalDropdown(
                          label: 'Type',
                          value: _secretType,
                          items: const {
                            'api_key': 'API Key',
                            'token': 'Token',
                            'password': 'Password',
                            'credential': 'Credential',
                            'certificate': 'Certificate',
                            'ssh_key': 'SSH Key',
                            'other': 'Other',
                          },
                          onChanged: (v) =>
                              setState(() => _secretType = v ?? _secretType),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ModalDropdown(
                          label: 'Environment',
                          value: _environment,
                          items: const {
                            null: 'None',
                            'development': 'Development',
                            'staging': 'Staging',
                            'production': 'Production',
                          },
                          onChanged: (v) => setState(() => _environment = v),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ModalInput(
                          label: 'Notes',
                          controller: _notesController,
                          hint: 'Optional notes...',
                          maxLines: 2,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm + 4),
                    ],
                  ),
                ),
              ),

              _ModalFooter(
                isSaving: _saving,
                canSave: _isDirty,
                onCancel: () => Navigator.pop(context),
                onSave: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    // Validation: Name (and Value in create mode) are required — failures
    // show an error border + one mono reason line (DESIGN.md).
    final name = _nameController.text.trim();
    var valid = true;
    setState(() {
      _nameError = null;
      _valueError = null;
      if (name.isEmpty) {
        _nameError = 'name is required';
        valid = false;
      }
      // Value is required in both modes now (edit pre-fills it) — an empty
      // secret is never valid.
      if (_valueController.text.isEmpty) {
        _valueError = 'value is required';
        valid = false;
      }
    });
    if (!valid) return;

    setState(() => _saving = true);

    final ops = ref.read(secretOpsProvider);

    if (_isEdit) {
      // Rotate only when the value actually changed from the decrypted
      // original — an untouched pre-filled value passes null (no re-encrypt,
      // recordVersion held).
      final newValue = _valueController.text == _originalValue
          ? null
          : _valueController.text;
      await ops.update(
        widget.secret!.id,
        name: name,
        value: newValue,
        secretType: _secretType,
        serviceName: _serviceController.text.trim().isNotEmpty
            ? _serviceController.text.trim()
            : null,
        environment: _environment,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      // Refresh the detail panel: it caches a one-shot getById, so without this
      // it would keep showing (and decrypting) the pre-edit row.
      ref.invalidate(secretDetailProvider(widget.secret!.id));
    } else {
      // Resolve the target folder via the same rule the selector renders:
      // the user's explicit pick → the viewed folder → General → first folder.
      // Only when the vault has no folders at all do we mint a Default home.
      final auth = ref.read(authProvider);
      if (auth is! AuthUnlocked) return;
      final db = ref.read(databaseProvider);
      final folders = await db.folderDao.getByVaultId(auth.vaultId);
      final effectiveFolderId = _effectiveFolderId(folders);
      final int folderId;
      if (effectiveFolderId != null) {
        folderId = effectiveFolderId;
      } else {
        final folder = await db.folderDao.create(
          vaultId: auth.vaultId,
          name: 'Default',
        );
        folderId = folder.id;
      }

      await ops.create(
        name: name,
        value: _valueController.text,
        folderId: folderId,
        secretType: _secretType,
        serviceName: _serviceController.text.trim().isNotEmpty
            ? _serviceController.text.trim()
            : null,
        environment: _environment,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}

// ─── Modal Header ───

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({required this.title, required this.onClose});
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: s.hairline)),
      ),
      child: Row(
        children: [
          Text(title, style: AppTypography.titleSmall.copyWith(color: s.ink)),
          const Spacer(),
          SizedBox(
            width: kMinHitTarget,
            height: kMinHitTarget,
            child: IconButton(
              onPressed: onClose,
              tooltip: 'Close',
              icon: Icon(LucideIcons.x, size: 16, color: s.muted),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Advanced toggle (ghost) ───

class _AdvancedToggle extends StatelessWidget {
  const _AdvancedToggle({required this.expanded, required this.onTap});
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          // Same 8pt header rhythm as the detail panel's collapsible sections.
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              AnimatedRotation(
                turns: expanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: s.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.xsm),
              Text(
                'Advanced Options',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  color: s.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Modal Footer ───

class _ModalFooter extends StatelessWidget {
  const _ModalFooter({
    required this.isSaving,
    required this.canSave,
    required this.onCancel,
    required this.onSave,
  });
  final bool isSaving;
  final bool canSave;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: s.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Secondary: transparent + hairline outline (components matrix).
          OutlinedButton(
            onPressed: isSaving ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: s.ink,
              side: BorderSide(color: s.hairline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              minimumSize: const Size(kMinHitTarget, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            child: const Text('Cancel', style: AppTypography.bodySmall),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              // Primary is disabled until dirty (40% weight, DESIGN.md).
              onPressed: (isSaving || !canSave) ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: s.accent,
                foregroundColor: s.onAccent,
                disabledBackgroundColor: s.accent.withValues(alpha: 0.4),
                disabledForegroundColor: s.onAccent.withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: isSaving
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: s.onAccent,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Save',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                            color: s.onAccent,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // ⌘↩ hint — Plex Mono has no U+2318 glyph (tofu), so
                        // the symbols are Lucide icons.
                        Icon(
                          LucideIcons.command,
                          size: 11,
                          color: s.onAccent.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          LucideIcons.cornerDownLeft,
                          size: 11,
                          color: s.onAccent.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modal Input ───

class _ModalInput extends StatelessWidget {
  const _ModalInput({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.isMono = false,
    this.autofocus = false,
    this.obscureText = false,
    this.errorText,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool isMono;
  final bool autofocus;
  final bool obscureText;
  final String? errorText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final hasError = errorText != null;

    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: c),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above the field — mono caption, never placeholder-as-label.
        Text(
          label.toUpperCase(),
          style: AppTypography.tableHeader.copyWith(color: s.muted),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus: autofocus,
          maxLines: maxLines,
          obscureText: obscureText,
          cursorColor: s.accent,
          style: (isMono ? AppTypography.mono : AppTypography.bodySmall)
              .copyWith(color: s.ink),
          decoration: InputDecoration(
            filled: true,
            // One tonal step down from the lamp card.
            fillColor: s.canvas,
            hintText: hint,
            hintStyle: (isMono ? AppTypography.mono : AppTypography.bodySmall)
                .copyWith(color: s.muted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 4,
              vertical: AppSpacing.sm + 2,
            ),
            border: border(hasError ? s.error : s.hairline),
            enabledBorder: border(hasError ? s.error : s.hairline),
            focusedBorder: border(hasError ? s.error : s.accent),
            suffixIcon: suffixIcon,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: AppTypography.tableHeader.copyWith(color: s.error),
          ),
        ],
      ],
    );
  }
}

// ─── Modal Dropdown ───

class _ModalDropdown extends StatelessWidget {
  const _ModalDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Map<String?, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;

    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: c),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.tableHeader.copyWith(color: s.muted),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          initialValue: value,
          // Chevron is a functional icon (matrix exception).
          icon: Icon(LucideIcons.chevronDown, size: 14, color: s.muted),
          borderRadius: BorderRadius.circular(AppRadii.md),
          // Open popover renders on the lamp face.
          dropdownColor: s.lamp,
          decoration: InputDecoration(
            filled: true,
            fillColor: s.canvas,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 4,
              vertical: AppSpacing.sm + 2,
            ),
            border: border(s.hairline),
            enabledBorder: border(s.hairline),
            focusedBorder: border(s.accent),
          ),
          items: items.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: AppTypography.bodySmall.copyWith(
                      // Currently-selected item reads in accent.
                      color: e.key == value ? s.accent : s.ink,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
