/// Example: Order Processing Workflow
///
/// Demonstrates a 3-step durable workflow using [InMemoryCheckpointStore].
/// Each step is checkpointed, so if the process crashes and restarts,
/// completed steps are replayed from cache (not re-executed).
///
/// Run with:
///   dart run example/order_processing.dart
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';

Future<void> main() async {
  // Create the engine with an in-memory store (no SQLite dependency).
  final engine = DurableEngineImpl(
    store: InMemoryCheckpointStore(),
    timerPollInterval: const Duration(milliseconds: 100),
  );

  try {
    final result = await engine.run<String>(
      'order_processing',
      (ctx) async {
        // Step 1: Validate the order
        final valid = await ctx.step<bool>('validate', () async {
          print('  [validate] Checking order...');
          // Simulate validation logic
          return true;
        });
        print('  [validate] result: $valid');

        // Step 2: Process payment (with compensation for rollback)
        final paymentId = await ctx.step<String>(
          'pay',
          () async {
            print('  [pay] Charging payment...');
            return 'PAY-${DateTime.now().millisecondsSinceEpoch}';
          },
          compensate: (_) async {
            print('  [pay:compensate] Refunding payment...');
          },
        );
        print('  [pay] result: $paymentId');

        // Step 3: Ship the order (with retry)
        final trackingId = await ctx.step<String>(
          'ship',
          () async {
            print('  [ship] Creating shipment...');
            return 'TRACK-${DateTime.now().millisecondsSinceEpoch}';
          },
          retry: RetryPolicy.fixed(
            maxAttempts: 3,
            delay: const Duration(seconds: 1),
          ),
          compensate: (_) async {
            print('  [ship:compensate] Cancelling shipment...');
          },
        );
        print('  [ship] result: $trackingId');

        return trackingId;
      },
    );

    print('\nWorkflow completed with result: $result');
  } catch (e) {
    print('\nWorkflow failed: $e');
  } finally {
    engine.dispose();
  }
}
