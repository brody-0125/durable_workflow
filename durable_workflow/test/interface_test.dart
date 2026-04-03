@Tags(['unit'])
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:test/test.dart';

/// Mock implementation of [CheckpointStore] to verify the interface compiles.
class MockCheckpointStore implements CheckpointStore {
  @override
  Future<void> saveCheckpoint(StepCheckpoint checkpoint) async {}

  @override
  Future<List<StepCheckpoint>> loadCheckpoints(
    String workflowExecutionId,
  ) async =>
      [];

  @override
  Future<void> saveTimer(WorkflowTimer timer) async {}

  @override
  Future<List<WorkflowTimer>> loadPendingTimers() async => [];

  @override
  Future<void> saveSignal(WorkflowSignal signal) async {}

  @override
  Future<List<WorkflowSignal>> loadPendingSignals(
    String workflowExecutionId, {
    String? signalName,
  }) async =>
      [];

  @override
  Future<void> saveExecution(WorkflowExecution execution) async {}

  @override
  Future<WorkflowExecution?> loadExecution(
    String workflowExecutionId,
  ) async =>
      null;

  @override
  Future<List<WorkflowExecution>> loadExecutionsByStatus(
    List<ExecutionStatus> statuses,
  ) async =>
      [];

  @override
  Future<void> deleteExecution(String workflowExecutionId) async {}

  @override
  Future<int> deleteCompletedBefore(DateTime cutoff) async => 0;
}

/// Mock implementation of [WorkflowContext] to verify the interface compiles.
class MockWorkflowContext implements WorkflowContext {
  @override
  String get executionId => 'mock-exec-id';

  @override
  Future<T> step<T>(
    String name,
    Future<T> Function() action, {
    Future<void> Function(T result)? compensate,
    RetryPolicy retry = RetryPolicy.none,
    String Function(T value)? serialize,
    T Function(String data)? deserialize,
  }) =>
      action();

  @override
  Future<void> sleep(String name, Duration duration) async {}

  @override
  Future<T?> waitSignal<T>(
    String signalName, {
    Duration? timeout,
  }) async =>
      null;
}

/// Mock implementation of [DurableEngine] to verify the interface compiles.
class MockDurableEngine implements DurableEngine {
  @override
  Future<T> run<T>(
    String workflowType,
    Future<T> Function(WorkflowContext ctx) body, {
    String? input,
    Duration? ttl,
    WorkflowGuarantee guarantee = WorkflowGuarantee.foregroundOnly,
  }) =>
      body(MockWorkflowContext());

  @override
  Future<void> cancel(String workflowExecutionId) async {}

  @override
  Stream<WorkflowExecution> observe(String workflowExecutionId) =>
      const Stream.empty();

  @override
  Future<void> sendSignal(
    String workflowExecutionId,
    String signalName, [
    Object? payload,
  ]) async {}

  @override
  void dispose() {}
}

void main() {
  group('CheckpointStore interface', () {
    late MockCheckpointStore store;

    setUp(() => store = MockCheckpointStore());

    test('saveCheckpoint accepts StepCheckpoint', () async {
      final cp = StepCheckpoint(
        workflowExecutionId: 'exec-001',
        stepIndex: 0,
        stepName: 'test',
        status: StepStatus.intent,
      );
      await store.saveCheckpoint(cp);
    });

    test('loadCheckpoints returns list', () async {
      final result = await store.loadCheckpoints('exec-001');
      expect(result, isA<List<StepCheckpoint>>());
    });

    test('saveTimer accepts WorkflowTimer', () async {
      final timer = WorkflowTimer(
        workflowTimerId: 'timer-001',
        workflowExecutionId: 'exec-001',
        stepName: 'wait',
        fireAt: '2026-03-26T10:00:00.000',
        createdAt: '2026-03-25T10:00:00.000',
      );
      await store.saveTimer(timer);
    });

    test('loadPendingTimers returns list', () async {
      final result = await store.loadPendingTimers();
      expect(result, isA<List<WorkflowTimer>>());
    });

    test('saveSignal accepts WorkflowSignal', () async {
      final signal = WorkflowSignal(
        workflowExecutionId: 'exec-001',
        signalName: 'test',
        createdAt: '2026-03-25T10:00:00.000',
      );
      await store.saveSignal(signal);
    });

    test('loadPendingSignals returns list with optional signalName', () async {
      final result = await store.loadPendingSignals('exec-001');
      expect(result, isA<List<WorkflowSignal>>());

      final filtered = await store.loadPendingSignals(
        'exec-001',
        signalName: 'delivery',
      );
      expect(filtered, isA<List<WorkflowSignal>>());
    });

    test('saveExecution accepts WorkflowExecution', () async {
      final exec = WorkflowExecution(
        workflowExecutionId: 'exec-001',
        workflowId: 'wf-001',
        createdAt: '2026-03-25T10:00:00.000',
        updatedAt: '2026-03-25T10:00:00.000',
      );
      await store.saveExecution(exec);
    });

    test('loadExecution returns nullable', () async {
      final result = await store.loadExecution('exec-001');
      expect(result, isNull);
    });
  });

  group('WorkflowContext interface', () {
    late MockWorkflowContext ctx;

    setUp(() => ctx = MockWorkflowContext());

    test('step has compensate and retry params', () async {
      final result = await ctx.step(
        'test_step',
        () async => 42,
        compensate: (_) async {},
        retry: RetryPolicy.exponential(maxAttempts: 3),
      );
      expect(result, 42);
    });

    test('step works with minimal params', () async {
      final result = await ctx.step('basic', () async => 'hello');
      expect(result, 'hello');
    });

    test('step accepts serialize and deserialize params', () async {
      final result = await ctx.step<int>(
        'serde_step',
        () async => 99,
        serialize: (v) => v.toString(),
        deserialize: (d) => int.parse(d),
      );
      expect(result, 99);
    });

    test('sleep accepts name and duration', () async {
      await ctx.sleep('wait_step', const Duration(hours: 1));
    });

    test('waitSignal accepts signalName and optional timeout', () async {
      final result = await ctx.waitSignal<bool>(
        'delivery_confirmed',
        timeout: const Duration(days: 7),
      );
      expect(result, isNull);
    });

    test('waitSignal works without timeout', () async {
      final result = await ctx.waitSignal<String>('my_signal');
      expect(result, isNull);
    });
  });

  group('DurableEngine interface', () {
    late MockDurableEngine engine;

    setUp(() => engine = MockDurableEngine());

    test('run has ttl and guarantee params', () async {
      final result = await engine.run<int>(
        'order_processing',
        (ctx) async => 42,
        input: '{"orderId": 1}',
        ttl: const Duration(days: 30),
        guarantee: WorkflowGuarantee.foregroundOnly,
      );
      expect(result, 42);
    });

    test('run works with minimal params', () async {
      final result = await engine.run<String>(
        'simple',
        (ctx) async => 'done',
      );
      expect(result, 'done');
    });

    test('cancel accepts workflowExecutionId', () async {
      await engine.cancel('exec-001');
    });

    test('observe returns stream', () {
      final stream = engine.observe('exec-001');
      expect(stream, isA<Stream<WorkflowExecution>>());
    });

    test('sendSignal accepts id, name, and optional payload', () async {
      await engine.sendSignal('exec-001', 'delivery_confirmed', true);
      await engine.sendSignal('exec-001', 'simple_signal');
    });

    test('dispose can be called on DurableEngine type', () {
      final DurableEngine abstractRef = engine;
      abstractRef.dispose();
    });
  });
}
