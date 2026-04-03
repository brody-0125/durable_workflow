import 'dart:async';

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';
import 'package:durable_workflow_flutter/durable_workflow_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryCheckpointStore store;
  late DurableEngineImpl engine;
  late ForegroundRecovery recovery;
  late Map<String, Future<dynamic> Function(WorkflowContext)> registry;

  setUp(() {
    store = InMemoryCheckpointStore();
    engine = DurableEngineImpl(store: store);
    registry = {
      'test_workflow': (ctx) async {
        await ctx.step('step1', () => 'result');
        return 'done';
      },
    };
    recovery = ForegroundRecovery(
      engine: engine,
      registry: registry,
      debounce: const Duration(milliseconds: 100),
    );
  });

  tearDown(() {
    recovery.dispose();
    engine.dispose();
  });

  group('ForegroundRecovery', () {
    test('initialScan returns result with no interrupted workflows', () async {
      final result = await recovery.initialScan();
      expect(result.resumed, isEmpty);
      expect(result.expired, isEmpty);
    });

    test('initialScan emits result on stream', () async {
      final results = <RecoveryScanResult>[];
      final sub = recovery.results.listen(results.add);

      await recovery.initialScan();

      // Allow stream to propagate
      await Future<void>.delayed(Duration.zero);

      expect(results, hasLength(1));
      expect(results.first.resumed, isEmpty);
      await sub.cancel();
    });

    test('scan is debounced within the debounce window', () async {
      // First scan should execute
      await recovery.initialScan();

      // Immediate second scan should be debounced
      final result = await recovery.scan();
      expect(result.resumed, isEmpty);
      expect(result.expired, isEmpty);
    });

    test('scan executes after debounce window', () async {
      final shortDebounce = ForegroundRecovery(
        engine: engine,
        registry: registry,
        debounce: const Duration(milliseconds: 10),
      );

      await shortDebounce.initialScan();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final result = await shortDebounce.scan();
      expect(result.resumed, isEmpty);
      shortDebounce.dispose();
    });

    test('scan resumes interrupted RUNNING workflows', () async {
      // Create a "stuck" RUNNING execution directly in the store
      final execution = WorkflowExecution(
        workflowExecutionId: 'exec-1',
        workflowId: 'wf-test_workflow-0',
        status: const Running(),
        createdAt: DateTime.now().toUtc().toIso8601String(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      await store.saveExecution(execution);

      final result = await recovery.initialScan();
      expect(result.resumed, contains('exec-1'));
    });

    test('scan expires TTL-expired workflows', () async {
      final execution = WorkflowExecution(
        workflowExecutionId: 'exec-expired',
        workflowId: 'wf-test_workflow-0',
        status: const Running(),
        ttlExpiresAt:
            DateTime.now().toUtc().subtract(const Duration(hours: 1)).toIso8601String(),
        createdAt: DateTime.now().toUtc().toIso8601String(),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      await store.saveExecution(execution);

      final result = await recovery.initialScan();
      expect(result.expired, contains('exec-expired'));
    });

    test('dispose closes result stream', () async {
      recovery.dispose();

      // Stream should be done after dispose
      expect(recovery.results.isEmpty, completion(isTrue));
    });
  });
}
