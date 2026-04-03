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

  group('SagaCompensator', () {
    test('compensates completed steps in reverse order',
        () async {
      const execId = 'exec-saga-1';
      await store.saveExecution(
        createTestExecution(execId, status: const Failed()),
      );

      for (var i = 0; i < 3; i++) {
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: execId,
          stepIndex: i,
          stepName: 'step_$i',
          compensateRef: 'step_$i',
        ));
      }

      final compensateOrder = <String>[];
      final compensator = SagaCompensator(store: store);
      await compensator.compensate(execId, {
        'step_0': (_) async => compensateOrder.add('step_0'),
        'step_1': (_) async => compensateOrder.add('step_1'),
        'step_2': (_) async => compensateOrder.add('step_2'),
      });

      expect(compensateOrder, ['step_2', 'step_1', 'step_0']);
    });

    test('only compensates COMPLETED steps (skips FAILED)',
        () async {
      const execId = 'exec-saga-2';
      await store.saveExecution(
        createTestExecution(execId, status: const Failed()),
      );

      await store.saveCheckpoint(createTestCheckpoint(
        workflowExecutionId: execId,
        stepIndex: 0,
        stepName: 'step_0',
        compensateRef: 'step_0',
      ));
      await store.saveCheckpoint(createTestCheckpoint(
        workflowExecutionId: execId,
        stepIndex: 1,
        stepName: 'step_1',
        compensateRef: 'step_1',
      ));
      await store.saveCheckpoint(createTestCheckpoint(
        workflowExecutionId: execId,
        stepIndex: 2,
        stepName: 'step_2',
        status: StepStatus.failed,
        errorMessage: 'boom',
      ));

      final compensateOrder = <String>[];
      final compensator = SagaCompensator(store: store);
      await compensator.compensate(execId, {
        'step_0': (_) async => compensateOrder.add('step_0'),
        'step_1': (_) async => compensateOrder.add('step_1'),
      });

      expect(compensateOrder, ['step_1', 'step_0']);
    });

    test('skips steps without compensate function', () async {
      const execId = 'exec-saga-3';
      await store.saveExecution(
        createTestExecution(execId, status: const Failed()),
      );

      for (var i = 0; i < 3; i++) {
        await store.saveCheckpoint(createTestCheckpoint(
          workflowExecutionId: execId,
          stepIndex: i,
          stepName: 'step_$i',
          compensateRef: i.isEven ? 'step_$i' : null,
        ));
      }

      final compensateOrder = <String>[];
      final compensator = SagaCompensator(store: store);
      await compensator.compensate(execId, {
        'step_0': (_) async => compensateOrder.add('step_0'),
        'step_2': (_) async => compensateOrder.add('step_2'),
      });

      expect(compensateOrder, ['step_2', 'step_0']);
    });

    test('records COMPENSATED checkpoints', () async {
      const execId = 'exec-saga-4';
      await store.saveExecution(
        createTestExecution(execId, status: const Failed()),
      );

      await store.saveCheckpoint(createTestCheckpoint(
        workflowExecutionId: execId,
        stepIndex: 0,
        stepName: 'step_0',
        compensateRef: 'step_0',
      ));

      final compensator = SagaCompensator(store: store);
      await compensator.compensate(execId, {
        'step_0': (_) async {},
      });

      final checkpoints = await store.loadCheckpoints(execId);
      final compensated = checkpoints
          .where((cp) => cp.status == StepStatus.compensated);
      expect(compensated, hasLength(1));
      expect(compensated.first.stepName, 'step_0:compensate');
    });

    test('transitions COMPENSATING then FAILED', () async {
      const execId = 'exec-saga-5';
      await store.saveExecution(
        createTestExecution(execId, status: const Failed()),
      );

      await store.saveCheckpoint(createTestCheckpoint(
        workflowExecutionId: execId,
        stepIndex: 0,
        stepName: 'step_0',
        compensateRef: 'step_0',
      ));

      final statusTransitions = <String>[];
      final compensator = SagaCompensator(store: store);
      await compensator.compensate(execId, {
        'step_0': (_) async {
          final exec = await store.loadExecution(execId);
          statusTransitions.add(exec!.status.name);
        },
      });

      final finalExec = await store.loadExecution(execId);
      statusTransitions.add(finalExec!.status.name);

      expect(statusTransitions, ['COMPENSATING', 'FAILED']);
    });

    test('continues if compensate function throws', () async {
      const execId = 'exec-saga-6';
      await store.saveExecution(
        createTestExecution(execId, status: const Failed()),
      );

      await store.saveCheckpoint(createTestCheckpoint(
        workflowExecutionId: execId,
        stepIndex: 0,
        stepName: 'step_0',
        compensateRef: 'step_0',
      ));
      await store.saveCheckpoint(createTestCheckpoint(
        workflowExecutionId: execId,
        stepIndex: 1,
        stepName: 'step_1',
        compensateRef: 'step_1',
      ));

      final compensateOrder = <String>[];
      final errors = <String>[];

      final compensator = SagaCompensator(store: store);
      await compensator.compensate(
        execId,
        {
          'step_0': (_) async =>
              compensateOrder.add('step_0'),
          'step_1': (_) async =>
              throw StateError('compensate failed'),
        },
        onCompensateError: (name, error) =>
            errors.add(name),
      );

      expect(compensateOrder, ['step_0']);
      expect(errors, ['step_1']);

      final finalExec = await store.loadExecution(execId);
      expect(finalExec!.status, isA<Failed>());
    });

    test('handles execution not found gracefully', () async {
      final compensator = SagaCompensator(store: store);
      await compensator.compensate('nonexistent', {});
    });

    test('passes step result to compensation function', () async {
      const execId = 'exec-saga-result';
      await store.saveExecution(
        createTestExecution(execId, status: const Failed()),
      );

      await store.saveCheckpoint(createTestCheckpoint(
        workflowExecutionId: execId,
        stepIndex: 0,
        stepName: 'step_0',
        compensateRef: 'step_0',
      ));

      dynamic receivedResult;
      final compensator = SagaCompensator(store: store);
      await compensator.compensate(
        execId,
        {
          'step_0': (result) async {
            receivedResult = result;
          },
        },
        compensateResults: {'step_0': 'my-result-value'},
      );

      expect(receivedResult, 'my-result-value');
    });
  });

  group('DurableEngineImpl saga integration', () {
    late DurableEngineImpl engine;

    setUp(() {
      engine = createTestEngine(store);
    });

    tearDown(() {
      engine.dispose();
    });

    test('triggers compensation when workflow fails', () async {
      final compensateOrder = <String>[];

      await expectLater(
        engine.run<int>(
          'saga_wf',
          (ctx) async {
            await ctx.step(
              'step_0',
              () async => 1,
              compensate: (_) async =>
                  compensateOrder.add('step_0'),
            );
            await ctx.step(
              'step_1',
              () async => 2,
              compensate: (_) async =>
                  compensateOrder.add('step_1'),
            );
            return await ctx.step(
              'step_2',
              () async => throw StateError('fail'),
            );
          },
        ),
        throwsStateError,
      );

      expect(compensateOrder, ['step_1', 'step_0']);

      final checkpoints =
          await store.loadCheckpoints('exec-0');
      final compensated = checkpoints
          .where((cp) => cp.status == StepStatus.compensated);
      expect(compensated, hasLength(2));
    });

    test('passes step result to compensation function via engine',
        () async {
      int? compensatedValue;

      await expectLater(
        engine.run<int>(
          'result_comp_wf',
          (ctx) async {
            await ctx.step<int>(
              'step_0',
              () async => 42,
              compensate: (result) async {
                compensatedValue = result;
              },
            );
            return await ctx.step(
              'step_1',
              () async => throw StateError('fail'),
            );
          },
        ),
        throwsStateError,
      );

      expect(compensatedValue, 42);
    });

    test('no compensation without compensate functions',
        () async {
      await expectLater(
        engine.run<int>(
          'no_comp_wf',
          (ctx) async {
            await ctx.step('step_0', () async => 1);
            return await ctx.step(
              'step_1',
              () async => throw StateError('fail'),
            );
          },
        ),
        throwsStateError,
      );

      final checkpoints =
          await store.loadCheckpoints('exec-0');
      final compensated = checkpoints
          .where((cp) => cp.status == StepStatus.compensated);
      expect(compensated, isEmpty);
    });

    test('retry + saga: retries then compensates on failure',
        () async {
      final compensateOrder = <String>[];
      var failCount = 0;

      await expectLater(
        engine.run<int>(
          'retry_saga_wf',
          (ctx) async {
            await ctx.step(
              'step_0',
              () async => 1,
              compensate: (_) async =>
                  compensateOrder.add('step_0'),
            );
            return await ctx.step(
              'step_1',
              () async {
                failCount++;
                throw StateError('always fails');
              },
              retry: RetryPolicy.fixed(
                maxAttempts: 3,
                delay: Duration.zero,
              ),
              compensate: (_) async =>
                  compensateOrder.add('step_1'),
            );
          },
        ),
        throwsStateError,
      );

      expect(failCount, 3);
      expect(compensateOrder, ['step_0']);
    });
  });
}
