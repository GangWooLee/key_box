import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/database/database.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../auth/domain/auth_notifier.dart';
import '../../../auth/domain/auth_state.dart';
import '../../domain/secrets_providers.dart';

/// Show a sheet-style modal for creating or editing a secret.
/// If [secret] is provided, the modal opens in edit mode.
void showSecretSheetModal({
  required BuildContext context,
  required WidgetRef ref,
  Secret? secret,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: _SecretSheetModal(secret: secret),
      );
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

  bool get _isEdit => widget.secret != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.secret?.name ?? '');
    _valueController = TextEditingController();
    _serviceController = TextEditingController(text: widget.secret?.serviceName ?? '');
    _notesController = TextEditingController(text: widget.secret?.notes ?? '');
    _escFocusNode = FocusNode();
    _secretType = widget.secret?.secretType ?? 'api_key';
    _environment = widget.secret?.environment;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _serviceController.dispose();
    _notesController.dispose();
    _escFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return KeyboardListener(
      focusNode: _escFocusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 520,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: isDark ? AppColors.authCardBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.authCardStroke : AppColors.lightBorderPrimary,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _ModalHeader(
                title: _isEdit ? 'Edit Secret' : 'Save New Key',
                isDark: isDark,
                onClose: () => Navigator.pop(context),
              ),

              // Form body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ModalInput(
                        label: 'Title',
                        controller: _nameController,
                        hint: 'e.g. GitHub API Key',
                        isDark: isDark,
                        autofocus: true,
                      ),
                      const SizedBox(height: 20),
                      _ModalInput(
                        label: _isEdit ? 'New Value (leave empty to keep current)' : 'Key Value',
                        controller: _valueController,
                        hint: _isEdit ? 'Enter new value...' : 'Paste your secret here...',
                        isDark: isDark,
                        maxLines: 4,
                        isMono: true,
                      ),
                      const SizedBox(height: 16),

                      // Advanced toggle
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                AnimatedRotation(
                                  turns: _showAdvanced ? 0.25 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    LucideIcons.chevronRight,
                                    size: 14,
                                    color: isDark ? AppColors.brand500 : AppColors.brand600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Advanced Options',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.brand500 : AppColors.brand600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (_showAdvanced) ...[
                        const SizedBox(height: 16),
                        _ModalInput(
                          label: 'Service',
                          controller: _serviceController,
                          hint: 'e.g. GitHub, AWS, Stripe',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _ModalDropdown(
                          label: 'Type',
                          value: _secretType,
                          isDark: isDark,
                          items: const {
                            'api_key': 'API Key',
                            'token': 'Token',
                            'password': 'Password',
                            'credential': 'Credential',
                            'certificate': 'Certificate',
                            'ssh_key': 'SSH Key',
                            'other': 'Other',
                          },
                          onChanged: (v) => setState(() => _secretType = v ?? _secretType),
                        ),
                        const SizedBox(height: 16),
                        _ModalDropdown(
                          label: 'Environment',
                          value: _environment,
                          isDark: isDark,
                          items: const {
                            null: 'None',
                            'development': 'Development',
                            'staging': 'Staging',
                            'production': 'Production',
                          },
                          onChanged: (v) => setState(() => _environment = v),
                        ),
                        const SizedBox(height: 16),
                        _ModalInput(
                          label: 'Notes',
                          controller: _notesController,
                          hint: 'Optional notes...',
                          isDark: isDark,
                          maxLines: 2,
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Footer
              _ModalFooter(
                isDark: isDark,
                isSaving: _saving,
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
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (!_isEdit && _valueController.text.isEmpty) return;

    setState(() => _saving = true);

    final ops = ref.read(secretOpsProvider);

    if (_isEdit) {
      final newValue = _valueController.text.isNotEmpty ? _valueController.text : null;
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
    } else {
      // For create, we need a folderId — use the first available folder or create one
      final auth = ref.read(authProvider);
      if (auth is! AuthUnlocked) return;
      final db = ref.read(databaseProvider);
      final folders = await db.folderDao.getByVaultId(auth.vaultId);
      int folderId;
      if (folders.isEmpty) {
        final folder = await db.folderDao.create(vaultId: auth.vaultId, name: 'Default');
        folderId = folder.id;
      } else {
        folderId = folders.first.id;
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
  const _ModalHeader({
    required this.title,
    required this.isDark,
    required this.onClose,
  });
  final String title;
  final bool isDark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDividerMedium : AppColors.lightBorderSubtle,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              fontSize: 18,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: onClose,
              icon: Icon(
                LucideIcons.x,
                size: 16,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modal Footer ───

class _ModalFooter extends StatelessWidget {
  const _ModalFooter({
    required this.isDark,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });
  final bool isDark;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDividerMedium : AppColors.lightBorderSubtle,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isSaving ? null : onCancel,
            child: Text(
              'Cancel',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.buttonPrimaryText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.buttonPrimaryText,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Save', style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.buttonPrimaryText,
                        )),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: Text(
                            '\u2318\u21A9',
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              color: AppColors.buttonPrimaryText.withValues(alpha: 0.7),
                            ),
                          ),
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
    required this.isDark,
    this.maxLines = 1,
    this.isMono = false,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final int maxLines;
  final bool isMono;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.authInputLabel.copyWith(
            fontFamily: AppTypography.interFamily,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          autofocus: autofocus,
          maxLines: maxLines,
          style: (isMono ? AppTypography.mono : AppTypography.bodySmall).copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.5)
                : null,
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkGlassBorder
                    : AppColors.lightBorderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkGlassBorder
                    : AppColors.lightBorderPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Modal Dropdown ───

class _ModalDropdown extends StatelessWidget {
  const _ModalDropdown({
    required this.label,
    required this.value,
    required this.isDark,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final bool isDark;
  final Map<String?, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.authInputLabel.copyWith(
            fontFamily: AppTypography.interFamily,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String?>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.5)
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkGlassBorder
                    : AppColors.lightBorderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkGlassBorder
                    : AppColors.lightBorderPrimary,
              ),
            ),
          ),
          dropdownColor: isDark ? AppColors.darkSurfaceCard : null,
          items: items.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(
                      e.value,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
