import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:key_box/core/router/app_router.dart';
import 'package:key_box/core/router/route_names.dart';
import 'package:key_box/features/auth/domain/auth_notifier.dart';
import 'package:key_box/features/auth/domain/auth_state.dart';

import '../../helpers/widget_test_helpers.dart';

/// Test the REAL redirect (extracted top-level [authRedirect]) — no mirror.
/// Previously this file duplicated the production switch, so the test could
/// pass while production drifted. It now calls production directly.
String? simulateRedirect(AuthState authState, String path) =>
    authRedirect(authState, path);

void main() {
  setUp(() {
    suppressDriftWarning();
    SharedPreferences.setMockInitialValues({});
  });

  GoRouter buildRouter(AuthState authState) {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier(authState)),
      ],
    );
    addTearDown(container.dispose);
    return container.read(routerProvider);
  }

  group('AppRouter', () {
    group('route definitions', () {
      test('has 9 routes', () {
        final router = buildRouter(const AuthInitial());
        final goRoutes = router.configuration.routes
            .whereType<GoRoute>()
            .toList();
        expect(goRoutes.length, 9);
      });

      test('all route paths are unique', () {
        final router = buildRouter(const AuthInitial());
        final goRoutes = router.configuration.routes
            .whereType<GoRoute>()
            .toList();
        final paths = goRoutes.map((r) => r.path).toSet();
        expect(paths.length, goRoutes.length);
      });

      test('AuthInitial redirects all to /loading via redirect function', () {
        // This confirms the redirect logic sends everything to /loading
        expect(simulateRedirect(const AuthInitial(), '/'), RoutePaths.loading);
        expect(
          simulateRedirect(const AuthInitial(), '/setup'),
          RoutePaths.loading,
        );
        expect(
          simulateRedirect(const AuthInitial(), '/unlock'),
          RoutePaths.loading,
        );
      });

      test('contains all expected paths', () {
        final router = buildRouter(const AuthInitial());
        final goRoutes = router.configuration.routes
            .whereType<GoRoute>()
            .toList();
        final paths = goRoutes.map((r) => r.path).toSet();
        expect(
          paths,
          containsAll([
            RoutePaths.loading,
            RoutePaths.setup,
            RoutePaths.unlock,
            RoutePaths.onboarding,
            RoutePaths.vaultError,
            RoutePaths.dashboard,
            RoutePaths.auditLog,
          ]),
        );
      });
    });

    group('redirect logic', () {
      group('AuthInitial', () {
        test('non-loading path redirects to /loading', () {
          expect(
            simulateRedirect(const AuthInitial(), '/setup'),
            RoutePaths.loading,
          );
          expect(
            simulateRedirect(const AuthInitial(), '/'),
            RoutePaths.loading,
          );
        });

        test('/loading stays (no redirect)', () {
          expect(
            simulateRedirect(const AuthInitial(), RoutePaths.loading),
            isNull,
          );
        });
      });

      group('AuthFirstRun', () {
        test('non-setup path redirects to /setup', () {
          expect(simulateRedirect(const AuthFirstRun(), '/'), RoutePaths.setup);
          expect(
            simulateRedirect(const AuthFirstRun(), '/loading'),
            RoutePaths.setup,
          );
        });

        test('/setup stays', () {
          expect(
            simulateRedirect(const AuthFirstRun(), RoutePaths.setup),
            isNull,
          );
        });
      });

      group('AuthLocked', () {
        test('non-unlock path redirects to /unlock', () {
          expect(simulateRedirect(const AuthLocked(), '/'), RoutePaths.unlock);
          expect(
            simulateRedirect(const AuthLocked(), '/setup'),
            RoutePaths.unlock,
          );
        });

        test('/unlock stays', () {
          expect(
            simulateRedirect(const AuthLocked(), RoutePaths.unlock),
            isNull,
          );
        });
      });

      group('AuthVaultError', () {
        const state = AuthVaultError(reason: VaultErrorReason.vaultFileMissing);

        test('non-vault-error path redirects to /vault-error', () {
          expect(simulateRedirect(state, '/'), RoutePaths.vaultError);
          expect(simulateRedirect(state, '/unlock'), RoutePaths.vaultError);
          expect(simulateRedirect(state, '/loading'), RoutePaths.vaultError);
        });

        test('/vault-error stays', () {
          expect(simulateRedirect(state, RoutePaths.vaultError), isNull);
        });

        test('all reasons redirect identically', () {
          for (final reason in VaultErrorReason.values) {
            expect(
              simulateRedirect(AuthVaultError(reason: reason), '/'),
              RoutePaths.vaultError,
              reason: '$reason should redirect to /vault-error',
            );
          }
        });
      });

      group('AuthUnlocked(isFirstSetup=true)', () {
        final state = AuthUnlocked(
          masterEncryptionKey: Uint8List(32),
          vaultId: 1,
          isFirstSetup: true,
        );

        test('non-onboarding path redirects to /onboarding', () {
          expect(simulateRedirect(state, '/'), RoutePaths.onboarding);
          expect(simulateRedirect(state, '/loading'), RoutePaths.onboarding);
        });

        test('/onboarding stays', () {
          expect(simulateRedirect(state, RoutePaths.onboarding), isNull);
        });
      });

      group('AuthUnlocked(isFirstSetup=false)', () {
        final state = AuthUnlocked(
          masterEncryptionKey: Uint8List(32),
          vaultId: 1,
        );

        test(
          'auth routes (/loading, /setup, /unlock, /onboarding) redirect to /',
          () {
            for (final authRoute in RoutePaths.authRoutes) {
              expect(
                simulateRedirect(state, authRoute),
                RoutePaths.dashboard,
                reason: '$authRoute should redirect to /',
              );
            }
          },
        );

        test('/ stays (no redirect)', () {
          expect(simulateRedirect(state, RoutePaths.dashboard), isNull);
        });

        test('/audit-log stays (no redirect)', () {
          expect(simulateRedirect(state, RoutePaths.auditLog), isNull);
        });
      });
    });
  });

  // ── Restore reachability (confirmed defect: /restore was unreachable
  // from the states where a user actually needs it) ──
  group('restore reachability', () {
    test('AuthFirstRun permits /restore (new-machine backup restore)', () {
      // A new Mac has no vault → AuthFirstRun. The user with a .kbx must be
      // able to reach /restore instead of being forced to /setup.
      expect(
        simulateRedirect(const AuthFirstRun(), RoutePaths.restore),
        isNull,
      );
    });

    test(
      'AuthVaultError permits /restore (recovery path actually renders)',
      () {
        // vault_error_screen pushes /restore; the redirect must not bounce it.
        expect(
          simulateRedirect(
            const AuthVaultError(reason: VaultErrorReason.sidecarMissing),
            RoutePaths.restore,
          ),
          isNull,
        );
      },
    );

    test('AuthFirstRun still forces non-restore/non-setup paths to /setup', () {
      expect(simulateRedirect(const AuthFirstRun(), '/'), RoutePaths.setup);
      expect(
        simulateRedirect(const AuthFirstRun(), RoutePaths.unlock),
        RoutePaths.setup,
      );
    });

    test('AuthLocked still bounces /restore to /unlock (vault intact)', () {
      // Restoring over an intact locked vault is out of scope (would need a
      // reset-first flow) — deliberately still bounced.
      expect(
        simulateRedirect(const AuthLocked(), RoutePaths.restore),
        RoutePaths.unlock,
      );
    });

    test('AuthUnlocked still bounces /restore to dashboard', () {
      final state = AuthUnlocked(
        masterEncryptionKey: Uint8List(32),
        vaultId: 1,
      );
      expect(simulateRedirect(state, RoutePaths.restore), RoutePaths.dashboard);
    });
  });

  group('RoutePaths constants', () {
    test('authRoutes contains exactly the pre-unlock paths', () {
      expect(RoutePaths.authRoutes, {
        RoutePaths.loading,
        RoutePaths.setup,
        RoutePaths.unlock,
        RoutePaths.onboarding,
        RoutePaths.vaultError,
        RoutePaths.restore,
      });
    });

    test('dashboard path is /', () {
      expect(RoutePaths.dashboard, '/');
    });

    test('auditLog path is /audit-log', () {
      expect(RoutePaths.auditLog, '/audit-log');
    });

    test('authRoutes does not contain dashboard or auditLog', () {
      expect(RoutePaths.authRoutes.contains(RoutePaths.dashboard), isFalse);
      expect(RoutePaths.authRoutes.contains(RoutePaths.auditLog), isFalse);
    });
  });
}
