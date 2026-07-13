import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/database/database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/secrets_providers.dart';

/// V9 search palette (DESIGN.md components matrix): a lamp card with a mono
/// query field. Keyboard selection reads in accent; a miss echoes the query
/// back in muted mono — `no match for "<query>"`.
class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer(
    duration: const Duration(milliseconds: AppConstants.searchDebounceMs),
  );
  final _keyFocusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    _keyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    final results = ref.watch(searchResultsProvider);

    return GestureDetector(
      onTap: () {}, // Prevent tap-through
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 560,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            // Lamp popover — hairline edge; only a faint lamp-face shadow.
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
          child: KeyboardListener(
            focusNode: _keyFocusNode,
            onKeyEvent: (event) => _handleKeyNav(event, results),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search input — mono query on the lamp face.
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      // Magnifier is a functional icon (matrix exception).
                      Icon(LucideIcons.search, size: 16, color: s.muted),
                      const SizedBox(width: AppSpacing.sm + 4),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          cursorColor: s.accent,
                          style: AppTypography.mono.copyWith(
                            fontSize: 13,
                            color: s.ink,
                          ),
                          decoration: InputDecoration(
                            hintText: 'search…',
                            hintStyle: AppTypography.mono.copyWith(
                              fontSize: 13,
                              color: s.muted,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            filled: false,
                          ),
                          onChanged: (value) {
                            _debouncer.call(() {
                              ref.read(searchQueryProvider.notifier).state =
                                  value;
                            });
                          },
                          onSubmitted: (_) => _selectCurrent(results),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: s.hairline),

                // Results
                results.when(
                  data: (secrets) {
                    if (secrets.isEmpty) {
                      // Echo the query back — DESIGN.md empty-state table.
                      final query = _controller.text;
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          query.isEmpty
                              ? 'type to search…'
                              : 'no match for "$query"',
                          style: AppTypography.mono.copyWith(
                            fontSize: 12.5,
                            color: s.muted,
                          ),
                        ),
                      );
                    }

                    return Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: secrets.length,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        itemBuilder: (context, index) {
                          final secret = secrets[index];
                          final isSelected = index == _selectedIndex;

                          return _ResultRow(
                            secret: secret,
                            isSelected: isSelected,
                            onTap: () {
                              ref
                                      .read(selectedSecretIdProvider.notifier)
                                      .state =
                                  secret.id;
                              widget.onClose();
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Error: $err',
                      style: AppTypography.caption.copyWith(color: s.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleKeyNav(KeyEvent event, AsyncValue<List<Secret>> results) {
    if (event is! KeyDownEvent) return;
    results.whenData((secrets) {
      if (secrets.isEmpty) return;
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1).clamp(0, secrets.length - 1);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1).clamp(0, secrets.length - 1);
        });
      }
    });
  }

  void _selectCurrent(AsyncValue<List<Secret>> results) {
    results.whenData((secrets) {
      if (secrets.isNotEmpty && _selectedIndex < secrets.length) {
        ref.read(selectedSecretIdProvider.notifier).state =
            secrets[_selectedIndex].id;
        widget.onClose();
      }
    });
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.secret,
    required this.isSelected,
    required this.onTap,
  });

  final Secret secret;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).extension<KbSurface>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: s.hover,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  secret.name,
                  // Names are identifiers — mono ink; keyboard selection
                  // reads in accent (matrix: 선택 항목 accent 텍스트).
                  style: AppTypography.mono.copyWith(
                    fontSize: 12.5,
                    color: isSelected ? s.accent : s.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (secret.serviceName != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  secret.serviceName!,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: s.muted,
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  // Type badge: mono 10px on a tonal step down from the lamp.
                  color: s.canvas,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  secret.secretType.replaceAll('_', ' '),
                  style: AppTypography.mono.copyWith(
                    fontSize: 10,
                    color: s.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
