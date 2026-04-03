@Tags(['unit'])
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/internals.dart';
import 'package:durable_workflow/testing.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  late InMemoryCheckpointStore store;

  setUp(() {
    store = InMemoryCheckpointStore();
  });

  group('StepExecutor', () {
    group('executeStep', () {
      test('records COMPLETED checkpoint with output', () async {
        final executor =
            await createTestExecutor(store, executionId: 'exec-001');

        final result = await executor.executeStep<int>(
          'add_numbers',
          () async => 42,
        );

        expect(result, 42);

        final checkpoints = await store.loadCheckpoints('exec-001');
        expect(checkpoints, hasLength(1));
        expect(checkpoints[0].status, StepStatus.completed);
        expect(checkpoints[0].stepName, 'add_numbers');
        expect(checkpoints[0].stepIndex, 0);
        expect(checkpoints[0].outputData, '42');
      });

      test('executes multiple steps in order', () async {
        final executor =
            await createTestExecutor(store, executionId: 'exec-002');
        final callOrder = <String>[];

        final r1 = await executor.executeStep<String>(
          'step_a',
          () async {
            callOrder.add('a');
            return 'result_a';
          },
        );
        final r2 = await executor.executeStep<String>(
          'step_b',
          () async {
            callOrder.add('b');
            return 'result_b';
          },
        );
        final r3 = await executor.executeStep<int>(
          'step_c',
          () async {
            callOrder.add('c');
            return 99;
          },
        );

        expect(r1, 'result_a');
        expect(r2, 'result_b');
        expect(r3, 99);
        expect(callOrder, ['a', 'b', 'c']);

        final checkpoints = await store.loadCheckpoints('exec-002');
        expect(checkpoints, hasLength(3));
        expect(checkpoints[0].stepIndex, 0);
        expect(checkpoints[1].stepIndex, 1);
        expect(checkpoints[2].stepIndex, 2);
      });

      test('records FAILED checkpoint on exception', () async {
        final executor =
            await createTestExecutor(store, executionId: 'exec-005');

        await expectLater(
          executor.executeStep<int>(
            'failing_step',
            () async => throw StateError('boom'),
          ),
          throwsStateError,
        );

        final checkpoints = await store.loadCheckpoints('exec-005');
        expect(checkpoints, hasLength(1));
        expect(checkpoints[0].status, StepStatus.failed);
        expect(checkpoints[0].errorMessage, contains('boom'));

        final execution = await store.loadExecution('exec-005');
        expect(execution!.status, isA<Failed>());
        expect(execution.errorMessage, contains('boom'));
      });

      test('handles null return value', () async {
        final executor =
            await createTestExecutor(store, executionId: 'exec-009');

        final result = await executor.executeStep<String?>(
          'nullable_step',
          () async => null,
        );

        expect(result, isNull);
      });

      test('persists string output as JSON-encoded', () async {
        final executor =
            await createTestExecutor(store, executionId: 'exec-010');

        final result = await executor.executeStep<String>(
          'string_step',
          () async => 'hello world',
        );

        expect(result, 'hello world');

        final checkpoints = await store.loadCheckpoints('exec-010');
        expect(checkpoints[0].outputData, '"hello world"');
      });

      test('persists boolean output correctly', () async {
        final executor =
            await createTestExecutor(store, executionId: 'exec-011');

        final result = await executor.executeStep<bool>(
          'bool_step',
          () async => true,
        );

        expect(result, isTrue);
      });

      test('persists map output via JSON serialization', () async {
        final executor =
            await createTestExecutor(store, executionId: 'exec-012');

        final result =
            await executor.executeStep<Map<String, dynamic>>(
          'map_step',
          () async => {'key': 'value', 'num': 42},
        );

        expect(result, {'key': 'value', 'num': 42});
      });
    });

    group('stepIndex', () {
      test('increments after each step', () async {
        final executor =
            await createTestExecutor(store, executionId: 'exec-008');

        expect(executor.stepIndex, 0);
        await executor.executeStep<int>('s1', () async => 1);
        expect(executor.stepIndex, 1);
        await executor.executeStep<int>('s2', () async => 2);
        expect(executor.stepIndex, 2);
      });
    });

    group('cancel', () {
      test('prevents further step execution', () async {
        final executor =
            await createTestExecutor(store, executionId: 'exec-007');

        await executor.executeStep<int>('step_a', () async => 1);

        executor.cancel();
        expect(executor.isCancelled, isTrue);

        await expectLater(
          executor.executeStep<int>('step_b', () async => 2),
          throwsA(isA<WorkflowCancelledException>()),
        );
      });
    });

    group('replay', () {
      test('skips already COMPLETED steps', () async {
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-003',
          stepIndex: 0,
          stepName: 'step_a',
          outputData: '"cached_result"',
        ));

        final executor =
            await createTestExecutor(store, executionId: 'exec-003');

        var actionCalled = false;
        final result = await executor.executeStep<String>(
          'step_a',
          () async {
            actionCalled = true;
            return 'should_not_be_called';
          },
        );

        expect(actionCalled, isFalse,
            reason: 'Step should be skipped on replay');
        expect(result, 'cached_result');
      });

      test('replays completed steps then executes new ones',
          () async {
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-004',
          stepIndex: 0,
          stepName: 'step_a',
          outputData: '10',
        ));
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-004',
          stepIndex: 1,
          stepName: 'step_b',
          outputData: '20',
        ));

        final executor =
            await createTestExecutor(store, executionId: 'exec-004');
        final callLog = <String>[];

        final r1 = await executor.executeStep<int>(
          'step_a',
          () async {
            callLog.add('a');
            return 999;
          },
        );
        final r2 = await executor.executeStep<int>(
          'step_b',
          () async {
            callLog.add('b');
            return 888;
          },
        );
        final r3 = await executor.executeStep<int>(
          'step_c',
          () async {
            callLog.add('c');
            return 30;
          },
        );

        expect(r1, 10, reason: 'Replayed from checkpoint');
        expect(r2, 20, reason: 'Replayed from checkpoint');
        expect(r3, 30, reason: 'Newly executed');
        expect(callLog, ['c'],
            reason: 'Only step_c should actually execute');
      });
    });

    group('custom serialize/deserialize', () {
      test('round-trips through checkpoint', () async {
        final executor1 =
            await createTestExecutor(store, executionId: 'exec-serde');

        final result1 = await executor1.executeStep<_TestObj>(
          'custom_obj',
          () async => _TestObj(id: 'T-1', value: 42),
          serialize: _TestObj.serialize,
          deserialize: _TestObj.deserialize,
        );

        expect(result1.id, 'T-1');
        expect(result1.value, 42);

        final checkpoints =
            await store.loadCheckpoints('exec-serde');
        expect(checkpoints.last.outputData, 'T-1|42');

        // Replay with a new executor (simulates recovery)
        final executor2 = StepExecutor(
          store: store,
          workflowExecutionId: 'exec-serde',
        );
        await executor2.initialize();

        var actionCalled = false;
        final result2 = await executor2.executeStep<_TestObj>(
          'custom_obj',
          () async {
            actionCalled = true;
            return _TestObj(id: 'SHOULD-NOT', value: -1);
          },
          serialize: _TestObj.serialize,
          deserialize: _TestObj.deserialize,
        );

        expect(actionCalled, isFalse,
            reason: 'Step should be replayed from checkpoint');
        expect(result2.id, 'T-1');
        expect(result2.value, 42);
      });

      test('passes through WorkflowContextImpl', () async {
        final executor =
            await createTestExecutor(store, executionId: 'exec-ctx');

        final ctx = WorkflowContextImpl(
          executor: executor,
          timerManager: TimerManager(store: store),
          signalManager: SignalManager(store: store),
          workflowExecutionId: 'exec-ctx',
        );

        final result = await ctx.step<_TestObj>(
          'ctx_custom_obj',
          () async => _TestObj(id: 'CTX-1', value: 100),
          serialize: _TestObj.serialize,
          deserialize: _TestObj.deserialize,
        );

        expect(result.id, 'CTX-1');
        expect(result.value, 100);

        final checkpoints =
            await store.loadCheckpoints('exec-ctx');
        expect(checkpoints.last.outputData, 'CTX-1|100');
      });
    });

    group('step name mismatch warning', () {
      test('emits warning when replayed name differs', () async {
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-mm-1',
          stepIndex: 0,
          stepName: 'process-item-100',
          outputData: '"done"',
        ));

        final warnings = <(String, int, String, String)>[];
        final executor = await createTestExecutor(
          store,
          executionId: 'exec-mm-1',
          onStepNameMismatch: (execId, idx, cp, cur) {
            warnings.add((execId, idx, cp, cur));
          },
        );

        final result = await executor.executeStep<String>(
          'process-item-200',
          () async => 'should_not_run',
        );

        expect(result, 'done');
        expect(warnings, hasLength(1));
        expect(warnings[0].$1, 'exec-mm-1');
        expect(warnings[0].$2, 0);
        expect(warnings[0].$3, 'process-item-100');
        expect(warnings[0].$4, 'process-item-200');
      });

      test('does not emit warning when names match', () async {
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-mm-2',
          stepIndex: 0,
          stepName: 'process-item-100',
          outputData: '42',
        ));

        final warnings = <(String, int, String, String)>[];
        final executor = await createTestExecutor(
          store,
          executionId: 'exec-mm-2',
          onStepNameMismatch: (execId, idx, cp, cur) {
            warnings.add((execId, idx, cp, cur));
          },
        );

        await executor.executeStep<int>(
          'process-item-100',
          () async => 999,
        );

        expect(warnings, isEmpty);
      });

      test('emits warnings for multiple mismatched steps',
          () async {
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-mm-3',
          stepIndex: 0,
          stepName: 'fetch-user-alice',
          outputData: '"alice_data"',
        ));
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-mm-3',
          stepIndex: 1,
          stepName: 'send-email-alice@old.com',
          outputData: '"sent"',
        ));

        final warnings = <(String, int, String, String)>[];
        final executor = await createTestExecutor(
          store,
          executionId: 'exec-mm-3',
          onStepNameMismatch: (execId, idx, cp, cur) {
            warnings.add((execId, idx, cp, cur));
          },
        );

        await executor.executeStep<String>(
          'fetch-user-bob',
          () async => 'should_not_run',
        );
        await executor.executeStep<String>(
          'send-email-bob@new.com',
          () async => 'should_not_run',
        );

        expect(warnings, hasLength(2));
        expect(warnings[0].$3, 'fetch-user-alice');
        expect(warnings[0].$4, 'fetch-user-bob');
        expect(warnings[1].$3, 'send-email-alice@old.com');
        expect(warnings[1].$4, 'send-email-bob@new.com');
      });

      test('replays from checkpoint even with mismatch', () async {
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-mm-4',
          stepIndex: 0,
          stepName: 'old-name',
          outputData: '1',
        ));

        final executor = await createTestExecutor(
          store,
          executionId: 'exec-mm-4',
          onStepNameMismatch: (_, __, ___, ____) {},
        );

        final result = await executor.executeStep<int>(
          'new-name',
          () async => 999,
        );

        expect(result, 1,
            reason: 'Should still replay from checkpoint');
      });

      test('registers compensate under checkpointed name',
          () async {
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: 'exec-mm-5',
          stepIndex: 0,
          stepName: 'charge-user-100',
          outputData: '"charged"',
          compensateRef: 'charge-user-100',
        ));

        final executor = await createTestExecutor(
          store,
          executionId: 'exec-mm-5',
          onStepNameMismatch: (_, __, ___, ____) {},
        );

        var compensateCalled = false;
        await executor.executeStep<String>(
          'charge-user-200',
          () async => 'should_not_run',
          compensate: (_) async {
            compensateCalled = true;
          },
        );

        expect(
          executor.compensateFunctions
              .containsKey('charge-user-100'),
          isTrue,
          reason: 'Keyed by checkpointed name for '
              'SagaCompensator lookup',
        );
        expect(
          executor.compensateFunctions
              .containsKey('charge-user-200'),
          isFalse,
        );

        await executor.compensateFunctions['charge-user-100']!('charged');
        expect(compensateCalled, isTrue);
      });
    });
  });

  group('WorkflowCancelledException', () {
    test('contains execution ID in message', () {
      const ex = WorkflowCancelledException('exec-abc');
      expect(ex.workflowExecutionId, 'exec-abc');
      expect(ex.toString(), contains('exec-abc'));
    });
  });
}

class _TestObj {
  final String id;
  final int value;
  _TestObj({required this.id, required this.value});

  static String serialize(_TestObj obj) =>
      '${obj.id}|${obj.value}';

  static _TestObj deserialize(String data) {
    final parts = data.split('|');
    return _TestObj(
      id: parts[0],
      value: int.parse(parts[1]),
    );
  }
}
