import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/auth_notifier.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock() async {
    if (_passwordController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final error = await ref.read(authProvider.notifier).unlock(
          password: _passwordController.text,
        );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _error = error;
      });
      if (error != null) {
        _passwordController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.brand600,
                ),
                const SizedBox(height: 24),
                Text(
                  'KeyBox is Locked',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your master password to unlock.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Master Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onSubmitted: (_) => _handleUnlock(),
                ),
                const SizedBox(height: 24),

                // Error
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                // Unlock button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleUnlock,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
