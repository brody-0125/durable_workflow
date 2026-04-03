/// E-Commerce: Checkout Workflow
///
/// Use case:
///   Order validation → inventory reservation → payment processing → wait → order confirmation → shipment request
///
/// Common approaches in existing Flutter apps:
///   - State management libraries handle checkout steps, but all state is lost on app crash
///   - Payment gateway integration handles creation and confirmation in a single function → risk of ghost payments
///   - Order state is saved to cloud DB, but compensation transaction (refund) logic must be implemented manually
///
/// With durable_workflow:
///   - Each step is persisted as a checkpoint → resumes from the last completed step after crash
///   - Saga compensation automatically handles payment refund and inventory restoration
///   - idempotencyKey prevents duplicate payments
///   - ctx.sleep() waits for payment settlement (durable timer → persists across process restarts)
///
/// References:
///   - Open-source commerce apps: state management library-based checkout, in-memory state only
///   - Delivery/order apps: cloud DB dependent, no offline support
///   - Payment integration examples: payment state inconsistency on network disconnection
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';

// ---------------------------------------------------------------------------
// Simulated external services
// ---------------------------------------------------------------------------

Future<bool> validateOrder(String orderId, List<String> items) async {
  await Future.delayed(const Duration(milliseconds: 100));
  print('    [step] Order $orderId validated (${items.length} items)');
  return true;
}

Future<Map<String, int>> reserveInventory(List<String> items) async {
  await Future.delayed(const Duration(milliseconds: 150));
  final reserved = {for (final item in items) item: 1};
  print('    [step] Inventory reserved: $reserved');
  return reserved;
}

Future<void> releaseInventory(Map<String, int> reserved) async {
  await Future.delayed(const Duration(milliseconds: 50));
  print('    [compensate] Inventory released: $reserved');
}

Future<String> processPayment(String orderId, int amount) async {
  await Future.delayed(const Duration(milliseconds: 200));
  final txId = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
  print('    [step] Payment completed: $txId (₩$amount)');
  return txId;
}

Future<void> refundPayment(String txId) async {
  await Future.delayed(const Duration(milliseconds: 100));
  print('    [compensate] Payment refunded: $txId');
}

Future<String> createOrder(String orderId, String txId) async {
  await Future.delayed(const Duration(milliseconds: 100));
  print('    [step] Order confirmed: $orderId (payment: $txId)');
  return orderId;
}

Future<String> requestShipment(String orderId) async {
  await Future.delayed(const Duration(milliseconds: 150));
  final trackingId = 'SHIP-${DateTime.now().millisecondsSinceEpoch}';
  print('    [step] Shipment requested: $trackingId');
  return trackingId;
}

Future<void> cancelShipment(String trackingId) async {
  await Future.delayed(const Duration(milliseconds: 50));
  print('    [compensate] Shipment cancelled: $trackingId');
}

// ---------------------------------------------------------------------------
// Workflow definition
// ---------------------------------------------------------------------------

/// Defines the checkout workflow.
///
/// Each step is checkpointed via [ctx.step].
/// On failure at any step, compensation functions from previous steps are executed in reverse order.
///
/// Example: shipment request failure → payment refund → inventory release (reverse saga compensation)
///
/// ## Compensation Closure Pattern
///
/// The `compensate:` callback receives the step result as a parameter,
/// so you can use it directly without mutable variable workarounds.
///
/// ```dart
/// final txId = await ctx.step<String>(
///   'pay',
///   () => processPayment(...),
///   compensate: (result) => refundPayment(result),
/// );
/// ```
Future<String> checkoutWorkflow(
  WorkflowContext ctx, {
  required String orderId,
  required List<String> items,
  required int totalAmount,
}) async {
  // Step 1: Order validation
  await ctx.step<bool>(
    'validate_order',
    () => validateOrder(orderId, items),
  );

  // Step 2: Reserve inventory (compensation: release inventory)
  await ctx.step<Map<String, int>>(
    'reserve_inventory',
    () => reserveInventory(items),
    compensate: (_) => releaseInventory({for (final item in items) item: 1}),
  );

  // Step 3: Process payment (compensation: refund)
  final txId = await ctx.step<String>(
    'process_payment',
    () => processPayment(orderId, totalAmount),
    compensate: (result) => refundPayment(result),
    retry: RetryPolicy.exponential(
      maxAttempts: 3,
      initialDelay: const Duration(seconds: 1),
    ),
    idempotencyKey: 'pay-$orderId',
  );

  // Step 4: Wait for payment settlement (durable timer — persists across process restarts)
  // Actual payment gateway settlement takes seconds to minutes. Wait safely with durable timer.
  await ctx.sleep('wait_settlement', const Duration(seconds: 3));
  print('    [timer] Payment settlement wait completed');

  // Step 5: Confirm order
  await ctx.step<String>(
    'create_order',
    () => createOrder(orderId, txId),
  );

  // Step 6: Request shipment (compensation: cancel shipment)
  final trackingId = await ctx.step<String>(
    'request_shipment',
    () => requestShipment(orderId),
    compensate: (result) => cancelShipment(result),
    retry: RetryPolicy.fixed(
      maxAttempts: 2,
      delay: const Duration(seconds: 2),
    ),
  );

  return trackingId;
}

// ---------------------------------------------------------------------------
// Main: Normal execution
// ---------------------------------------------------------------------------

Future<void> main() async {
  final engine = DurableEngineImpl(
    store: InMemoryCheckpointStore(),
  );

  try {
    print('=== E-Commerce Checkout Workflow ===\n');

    final result = await engine.run<String>(
      'checkout',
      (ctx) => checkoutWorkflow(
        ctx,
        orderId: 'ORD-001',
        items: ['ITEM-A', 'ITEM-B', 'ITEM-C'],
        totalAmount: 59000,
      ),
    );

    print('\n  Workflow completed: tracking number = $result');
  } catch (e) {
    print('\n  Workflow failed: $e');
  } finally {
    engine.dispose();
  }
}
