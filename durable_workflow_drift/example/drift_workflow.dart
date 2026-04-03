/// Example: Durable workflow with Drift ORM persistence.
///
/// Demonstrates running a checkpoint/resume workflow backed by
/// Drift's type-safe query builder with an in-memory database.
///
/// Run with:
///   dart run example/drift_workflow.dart
library;

import 'package:drift/native.dart';
import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_drift/durable_workflow_drift.dart';

Future<void> main() async {
  // Create an in-memory Drift database.
  final db = DurableWorkflowDatabase(NativeDatabase.memory());
  final store = DriftCheckpointStore(db);

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
          compensate: () async {
            print('  [pay:compensate] Refunding...');
          },
        );

        return 'Completed with payment: $paymentId';
      },
    );

    print('Workflow result: $result');
  } finally {
    engine.dispose();
    await store.close();
  }
}
