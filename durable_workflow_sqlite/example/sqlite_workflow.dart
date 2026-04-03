/// Example: Durable workflow with SQLite persistence.
///
/// Demonstrates running a checkpoint/resume workflow backed by
/// an on-disk SQLite database.
///
/// Run with:
///   dart run example/sqlite_workflow.dart
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';

Future<void> main() async {
  // Open an in-memory SQLite database for this demo.
  // In production, pass a file path: SqliteCheckpointStore('workflow.db')
  final store = SqliteCheckpointStore.inMemory();

  final engine = DurableEngineImpl(
    store: store,
    timerPollInterval: const Duration(milliseconds: 100),
  );

  try {
    final result = await engine.run<String>(
      'order_processing',
      (ctx) async {
        await ctx.step<bool>('validate', () async {
          print('  [validate] Checking order...');
          return true;
        });

        final paymentId = await ctx.step<String>(
          'pay',
          () async {
            print('  [pay] Charging payment...');
            return 'PAY-001';
          },
          compensate: (_) async {
            print('  [pay:compensate] Refunding...');
          },
        );

        return 'Completed with payment: $paymentId';
      },
    );

    print('Workflow result: $result');
  } finally {
    engine.dispose();
    store.close();
  }
}
