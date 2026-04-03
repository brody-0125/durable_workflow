// ignore_for_file: avoid_print
import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';
import 'package:durable_workflow_flutter/durable_workflow_flutter.dart';
import 'package:flutter/material.dart';

/// Example: Order processing workflow.
Future<String> orderWorkflow(WorkflowContext ctx) async {
  final validated = await ctx.step(
    'validate_order',
    () async => 'order-123-valid',
  );

  await ctx.step(
    'charge_payment',
    () async => 'payment-txn-456',
    compensate: (_) async => print('Refunding payment...'),
    retry: const RetryPolicyExponential(maxAttempts: 3),
  );

  await ctx.sleep('await_shipping', const Duration(hours: 24));

  final confirmed = await ctx.waitSignal<bool>(
    'delivery_confirmed',
    timeout: const Duration(days: 7),
  );

  return 'Order $validated delivered: $confirmed';
}

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final _store = InMemoryCheckpointStore();

  @override
  Widget build(BuildContext context) {
    return DurableWorkflowProvider(
      store: _store,
      workflowRegistry: const {
        'order_processing': orderWorkflow,
      },
      // backgroundAdapter: WorkManagerAdapter(),  // Android
      // backgroundAdapter: BgTaskAdapter(),       // iOS
      onResumed: () => print('App resumed — recovery scan triggered'),
      onPaused: () => print('App paused — background recovery scheduled'),
      child: const MaterialApp(
        title: 'Durable Workflow Demo',
        home: OrderDashboard(),
      ),
    );
  }
}

class OrderDashboard extends StatefulWidget {
  const OrderDashboard({super.key});

  @override
  State<OrderDashboard> createState() => _OrderDashboardState();
}

class _OrderDashboardState extends State<OrderDashboard> {
  String? _activeExecutionId;

  @override
  Widget build(BuildContext context) {
    final engine = DurableWorkflowProvider.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Workflow')),
      body: Column(
        children: [
          // Recovery status
          StreamBuilder<RecoveryScanResult>(
            stream: DurableWorkflowProvider.recoveryResults(context),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final result = snapshot.data!;
              if (result.resumed.isEmpty && result.expired.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Recovery: ${result.resumed.length} resumed, '
                  '${result.expired.length} expired',
                ),
              );
            },
          ),

          // Active execution monitor
          if (_activeExecutionId != null)
            ExecutionMonitor(
              workflowExecutionId: _activeExecutionId!,
              loading: const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
              builder: (context, execution) {
                return ExecutionListTile(
                  execution: execution,
                  onCancel: () => engine.cancel(execution.workflowExecutionId),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Note: engine.run() returns the workflow result, not the execution ID.
          // In a real app, you would use engine.observe() or a separate API
          // to track execution IDs. This is a simplified demo.
          engine.run<String>(
            'order_processing',
            orderWorkflow,
            ttl: const Duration(days: 30),
          ).then((result) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Workflow completed: $result')),
            );
          }).catchError((Object error) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Workflow failed: $error')),
            );
          });
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
