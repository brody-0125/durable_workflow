/// Example: E-commerce checkout workflow.
///
/// Demonstrates a multi-step order processing workflow with
/// saga compensation for automatic rollback on failure.
///
/// Run with:
///   dart run example/checkout_example.dart
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';

Future<void> main() async {
  final engine = DurableEngineImpl(
    store: InMemoryCheckpointStore(),
    timerPollInterval: const Duration(milliseconds: 100),
  );

  try {
    final result = await engine.run<String>(
      'checkout',
      (ctx) async {
        // Step 1: Reserve inventory
        await ctx.step<bool>(
          'reserve_inventory',
          () async {
            print('  [inventory] Reserving items...');
            return true;
          },
          compensate: (result) async {
            print('  [inventory:compensate] Releasing reservation...');
          },
        );

        // Step 2: Charge payment
        final paymentId = await ctx.step<String>(
          'charge_payment',
          () async {
            print('  [payment] Charging card...');
            return 'PAY-12345';
          },
          compensate: (result) async {
            print('  [payment:compensate] Issuing refund for $result...');
          },
          retry: RetryPolicy.exponential(maxAttempts: 3),
        );

        // Step 3: Create shipment
        final trackingId = await ctx.step<String>(
          'create_shipment',
          () async {
            print('  [shipping] Creating shipment...');
            return 'TRACK-67890';
          },
        );

        return 'Order confirmed: $paymentId / $trackingId';
      },
    );

    print('\nResult: $result');
  } finally {
    engine.dispose();
  }
}
