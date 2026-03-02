import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/secrets_providers.dart';

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
  final int _selectedIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = ref.watch(searchResultsProvider);

    return GestureDetector(
      onTap: () {}, // Prevent tap-through
      child: Material(
        elevation: 16,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 560,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search secrets...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    _debouncer.call(() {
                      ref.read(searchQueryProvider.notifier).state = value;
                    });
                  },
                  onSubmitted: (_) => _selectCurrent(results),
                ),
              ),
              const Divider(height: 1),

              // Results
              results.when(
                data: (secrets) {
                  if (secrets.isEmpty) {
                    if (_controller.text.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Type to search...'),
                      );
                    }
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No results found'),
                    );
                  }

                  return Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: secrets.length,
                      itemBuilder: (context, index) {
                        final secret = secrets[index];
                        final isSelected = index == _selectedIndex;

                        return ListTile(
                          selected: isSelected,
                          title: Text(secret.name),
                          subtitle: secret.serviceName != null
                              ? Text(secret.serviceName!)
                              : null,
                          trailing: Text(
                            secret.secretType.replaceAll('_', ' '),
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () {
                            ref.read(selectedSecretIdProvider.notifier).state =
                                secret.id;
                            widget.onClose();
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $err'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectCurrent(AsyncValue<dynamic> results) {
    results.whenData((secrets) {
      if (secrets is List && secrets.isNotEmpty && _selectedIndex < secrets.length) {
        ref.read(selectedSecretIdProvider.notifier).state = secrets[_selectedIndex].id;
        widget.onClose();
      }
    });
  }
}
