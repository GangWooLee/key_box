@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:key_box/features/secrets/presentation/widgets/sheet_modal.dart';

import '../helpers/widget_test_helpers.dart';
import 'golden_helpers.dart';

/// Host that opens the create-mode secret sheet modal on tap. The modal is
/// launched via `showGeneralDialog`, so it needs a live `BuildContext` + `ref`
/// rather than direct instantiation (the modal widget is private).
class _ModalHost extends ConsumerWidget {
  const _ModalHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showSecretSheetModal(context: context, ref: ref),
          child: const Text('open-modal'),
        ),
      ),
    );
  }
}

void main() {
  setUp(suppressDriftWarning);

  testWidgets('sheet_modal — V9 create mode (terminal)', (tester) async {
    await pumpGolden(
      tester,
      child: const _ModalHost(),
      size: GoldenSizes.modal,
    );

    await tester.tap(find.text('open-modal'));
    // 200ms fade/scale entrance transition — no infinite animation.
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_modal.png'),
    );
  });
}
