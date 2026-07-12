import 'dart:typed_data';

/// Authentication state machine for the app.
///
/// Flow:
/// 1. App starts → [AuthInitial] (checking if vault exists)
/// 2. No VaultConfig → [AuthFirstRun] (show Setup screen)
/// 3. VaultConfig exists → [AuthLocked] (show Unlock screen)
/// 4. Password correct → [AuthUnlocked] (show Dashboard)
/// 5. Lock/timeout → back to [AuthLocked]
sealed class AuthState {
  const AuthState();
}

/// App is initializing, checking vault config existence.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// No vault config found — first run, show Setup screen.
final class AuthFirstRun extends AuthState {
  const AuthFirstRun();
}

/// Vault exists but MEK is not in memory — show Unlock screen.
final class AuthLocked extends AuthState {
  const AuthLocked();
}

/// Vault files are in an inconsistent/corrupted state — recovery required.
final class AuthVaultError extends AuthState {
  const AuthVaultError({required this.reason});

  final VaultErrorReason reason;
}

/// Why the vault could not be booted.
enum VaultErrorReason {
  /// Sidecar exists but the database file is gone — possible data loss.
  vaultFileMissing,

  /// Sidecar exists but is unreadable or fails validation.
  sidecarCorrupted,

  /// Database exists but holds no vault configuration.
  configMissing,
}

/// MEK is available in memory — full access granted.
final class AuthUnlocked extends AuthState {
  const AuthUnlocked({
    required this.masterEncryptionKey,
    required this.vaultId,
    this.isFirstSetup = false,
  });

  final Uint8List masterEncryptionKey;
  final int vaultId;

  /// True when this unlock came from initial setup (not a returning unlock).
  /// Used by the router to redirect to onboarding before the dashboard.
  final bool isFirstSetup;
}
