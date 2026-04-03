@Tags(['unit'])
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';
import 'package:test/test.dart';

import '../test_helpers.dart';

void main() {
  late InMemoryCheckpointStore store;

  setUp(() {
    store = InMemoryCheckpointStore();
  });

  group('RecoveryScanner', () {
    test('resumes RUNNING execution from last checkpoint',
        () async {
      await store.saveExecution(createTestExecution(
        'exec-crashed',
        workflowId: 'wf-order_flow-0',
        currentStep: 1,
      ));

      await store.saveCheckpoint(createTestCheckpoint(
        workflowExecutionId: 'exec-crashed',
        stepIndex: 0,
        stepName: 'step_a',
        outputData: '10',
      ));
      await store.saveCheckpoint(createTestCheckpoint(
        workflowExecutionId: 'exec-crashed',
        stepIndex: 1,
        stepName: 'step_b',
        outputData: '20',
      ));

      final engine = DurableEngineImpl(store: store);
      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );

      final callLog = <String>[];
      final result = await scanner.scan(
        workflowRegistry: {
          'order_flow': (ctx) async {
            final a = await ctx.step<int>('step_a', () async {
              callLog.add('step_a');
              return 10;
            });
            final b = await ctx.step<int>('step_b', () async {
              callLog.add('step_b');
              return 20;
            });
            final c = await ctx.step<int>('step_c', () async {
              callLog.add('step_c');
              return a + b;
            });
            return c;
          },
        },
      );

      expect(result.resumed, ['exec-crashed']);
      expect(result.expired, isEmpty);
      expect(callLog, ['step_c']);

      final updated =
          await store.loadExecution('exec-crashed');
      expect(updated!.status, isA<Completed>());

      engine.dispose();
    });

    test('marks TTL-expired execution as FAILED', () async {
      await store.saveExecution(createTestExecution(
        'exec-expired',
        workflowId: 'wf-old-0',
        ttlExpiresAt: pastTimestamp(),
      ));

      final engine = DurableEngineImpl(store: store);
      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );

      final result =
          await scanner.scan(workflowRegistry: {});

      expect(result.expired, ['exec-expired']);
      expect(result.resumed, isEmpty);

      final updated =
          await store.loadExecution('exec-expired');
      expect(updated!.status, isA<Failed>());
      expect(updated.errorMessage, contains('TTL expired'));

      engine.dispose();
    });

    test('handles SUSPENDED executions', () async {
      await store.saveExecution(createTestExecution(
        'exec-suspended',
        workflowId: 'wf-paused-0',
        status: const Suspended(),
      ));

      final engine = DurableEngineImpl(store: store);
      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );

      final result = await scanner.scan(
        workflowRegistry: {
          'paused': (ctx) async {
            return await ctx.step<int>(
              's',
              () async => 42,
            );
          },
        },
      );

      expect(result.resumed, ['exec-suspended']);

      final updated =
          await store.loadExecution('exec-suspended');
      expect(updated!.status, isA<Completed>());

      engine.dispose();
    });

    test('marks FAILED when workflow type not in registry',
        () async {
      await store.saveExecution(createTestExecution(
        'exec-unknown',
        workflowId: 'wf-unknown_type-0',
      ));

      final engine = DurableEngineImpl(store: store);
      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );

      final result =
          await scanner.scan(workflowRegistry: {});

      expect(result.expired, ['exec-unknown']);

      final updated =
          await store.loadExecution('exec-unknown');
      expect(updated!.status, isA<Failed>());
      expect(
        updated.errorMessage,
        contains('No registered workflow body'),
      );

      engine.dispose();
    });

    test('ignores COMPLETED and FAILED executions', () async {
      await store.saveExecution(createTestExecution(
        'exec-done',
        status: const Completed(),
      ));
      await store.saveExecution(createTestExecution(
        'exec-failed',
        workflowId: 'wf-test-1',
        status: const Failed(),
      ));

      final engine = DurableEngineImpl(store: store);
      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );

      final result =
          await scanner.scan(workflowRegistry: {});

      expect(result.resumed, isEmpty);
      expect(result.expired, isEmpty);

      engine.dispose();
    });

    test('handles multiple interrupted executions', () async {
      await store.saveExecution(createTestExecution(
        'exec-a',
        workflowId: 'wf-simple-0',
      ));
      await store.saveExecution(createTestExecution(
        'exec-b',
        workflowId: 'wf-simple-1',
      ));

      final engine = DurableEngineImpl(store: store);
      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );

      final result = await scanner.scan(
        workflowRegistry: {
          'simple': (ctx) async {
            return await ctx.step<int>(
              's',
              () async => 1,
            );
          },
        },
      );

      expect(result.resumed, hasLength(2));

      engine.dispose();
    });

    test('execution without TTL is not expired', () async {
      await store.saveExecution(createTestExecution(
        'exec-no-ttl',
        workflowId: 'wf-simple-0',
      ));

      final engine = DurableEngineImpl(store: store);
      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );

      final result = await scanner.scan(
        workflowRegistry: {
          'simple': (ctx) async {
            return await ctx.step<int>(
              's',
              () async => 99,
            );
          },
        },
      );

      expect(result.resumed, ['exec-no-ttl']);
      expect(result.expired, isEmpty);

      engine.dispose();
    });

    test('RecoveryScanResult toString', () {
      const result = RecoveryScanResult(
        resumed: ['a', 'b'],
        expired: ['c'],
      );
      expect(result.toString(), contains('resumed: 2'));
      expect(result.toString(), contains('expired: 1'));
    });
  });

  group('Crash recovery integration', () {
    test('full crash recovery simulation', () async {
      // Phase 1: Run workflow that "crashes" at step 3
      final engine1 = DurableEngineImpl(
        store: store,
        generateId: () => 'exec-crash-sim',
      );

      final stepsCalled1 = <String>[];
      try {
        await engine1.run<int>(
          'multi_step_wf',
          (ctx) async {
            final a = await ctx.step<int>('step_1', () async {
              stepsCalled1.add('step_1');
              return 100;
            });
            final b = await ctx.step<int>('step_2', () async {
              stepsCalled1.add('step_2');
              return 200;
            });
            final c = await ctx.step<int>('step_3', () async {
              stepsCalled1.add('step_3');
              throw StateError('Simulated crash');
            });
            return a + b + c;
          },
        );
      } catch (e) {
        // Expected crash
      }
      engine1.dispose();

      expect(stepsCalled1, ['step_1', 'step_2', 'step_3']);

      // Phase 2: Reset to RUNNING to simulate mid-step crash
      await simulateCrash(store, 'exec-crash-sim');

      // Phase 3: New engine recovers
      final engine2 = DurableEngineImpl(store: store);
      final scanner = RecoveryScanner(
        store: store,
        engine: engine2,
      );

      final stepsCalled2 = <String>[];
      final result = await scanner.scan(
        workflowRegistry: {
          'multi_step_wf': (ctx) async {
            final a = await ctx.step<int>('step_1', () async {
              stepsCalled2.add('step_1');
              return 100;
            });
            final b = await ctx.step<int>('step_2', () async {
              stepsCalled2.add('step_2');
              return 200;
            });
            final c = await ctx.step<int>('step_3', () async {
              stepsCalled2.add('step_3');
              return 300;
            });
            return a + b + c;
          },
        },
      );

      expect(stepsCalled2, ['step_3']);
      expect(result.resumed, ['exec-crash-sim']);

      final recovered =
          await store.loadExecution('exec-crash-sim');
      expect(recovered!.status, isA<Completed>());

      engine2.dispose();
    });
  });
}
