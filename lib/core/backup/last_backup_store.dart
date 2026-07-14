import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the instant of the last successful backup export, so the detail
/// panel can quietly show "backed up 2h ago" / "never backed up" (보안 UX #3).
/// Stored as epoch millis in [SharedPreferences].
class LastBackupStore {
  LastBackupStore(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'last_backup_at';

  /// The last backup instant, or null if the vault has never been exported.
  DateTime? read() {
    final ms = _prefs.getInt(_key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> record(DateTime at) =>
      _prefs.setInt(_key, at.millisecondsSinceEpoch);
}

/// Reactive last-backup instant. Loads once from disk, then reflects [record].
final lastBackupProvider = StateNotifierProvider<LastBackupNotifier, DateTime?>(
  (ref) {
    return LastBackupNotifier();
  },
);

class LastBackupNotifier extends StateNotifier<DateTime?> {
  LastBackupNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = LastBackupStore(prefs).read();
  }

  /// Records [at] (defaults to now) as the last backup instant.
  Future<void> record(DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await LastBackupStore(prefs).record(at);
    state = at;
  }
}
