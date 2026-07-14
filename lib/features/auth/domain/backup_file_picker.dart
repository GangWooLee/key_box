import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A backup file the user chose to restore from.
class PickedBackup {
  const PickedBackup({required this.name, required this.contents});

  /// The file's display name (e.g. `key_box.backup-1720000000.kbx`).
  final String name;

  /// The raw archive JSON.
  final String contents;
}

/// Opens the native file panel for a `.kbx` archive and reads it. Returns null
/// if the user cancels. Injected behind a provider so the restore screen stays
/// widget-testable without touching the (untestable) native panel.
typedef BackupFilePicker = Future<PickedBackup?> Function();

final backupFilePickerProvider = Provider<BackupFilePicker>((ref) {
  return () async {
    const group = XTypeGroup(label: 'KeyBox backup', extensions: ['kbx']);
    final file = await openFile(acceptedTypeGroups: [group]);
    if (file == null) return null;
    return PickedBackup(name: file.name, contents: await file.readAsString());
  };
});
