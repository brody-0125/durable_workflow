@Tags(['integration'])
library;

/// RecoveryScanner / SagaCompensator actual behavior demonstration
///
/// Validates the full fault injection -> recovery process through 10 scenarios:
///
///  1. Saga compensation: reverse compensation after fault injection
///  2. Crash recovery: checkpoint-based resumption
///  3. TTL expiry: auto-FAILED for interrupted workflows
///  4. Complex scenario: re-execution failure during crash recovery -> compensation
///  5. Multiple workflow simultaneous recovery
///  6. Compensation failure tolerance: skip-on-failure pattern
///  7. E2E checkout: 5 steps + retry + saga
///  8. SUSPENDED state recovery
///  9. Unregistered workflow in registry -> FAILED
/// 10. observe() stream: state transition verification during compensation
import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  late SqliteCheckpointStore store;

  setUp(() {
    store = createTestStore();
  });

  tearDown(() {
    store.close();
  });

  // =============================================
  // Scenario 1: Saga compensation — reverse compensation after fault injection
  // =============================================
  group('Scenario 1: Saga compensation', () {
    test('payment fails -> reverse compensation', () async {
      final actionLog = <String>[];
      final compensateLog = <String>[];

      final engine = createIntegrationEngine(store);

      Object? caught;
      try {
        await engine.run<String>(
          'checkout',
          (ctx) async {
            await ctx.step<bool>(
              'validate_order',
              () async {
                actionLog.add('validate_order');
                return true;
              },
              compensate: (_) async {
                compensateLog.add('undo_validate_order');
              },
            );

            await ctx.step<int>(
              'reserve_inventory',
              () async {
                actionLog.add('reserve_inventory');
                return 3;
              },
              compensate: (_) async {
                compensateLog.add('release_inventory');
              },
            );

            await ctx.step<String>(
              'process_payment',
              () async {
                actionLog.add('process_payment_FAIL');
                throw Exception('Payment gateway timeout');
              },
              retry: RetryPolicy.fixed(
                maxAttempts: 2,
                delay: Duration.zero,
              ),
              compensate: (_) async {
                compensateLog.add('refund_payment');
              },
            );

            return 'should-not-reach';
          },
        );
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<Exception>());
      expect(
        caught.toString(),
        contains('Payment gateway timeout'),
      );

      expect(actionLog, [
        'validate_order',
        'reserve_inventory',
        'process_payment_FAIL',
        'process_payment_FAIL',
      ]);

      expect(compensateLog, [
        'release_inventory',
        'undo_validate_order',
      ]);

      final exec = await store.loadExecution('exec-0');
      expect(exec!.status, isA<Failed>());

      final checkpoints =
          await store.loadCheckpoints('exec-0');
      final compensated = checkpoints
          .where((cp) => cp.status == StepStatus.compensated)
          .toList();
      expect(compensated, hasLength(2));
      expect(
        compensated.map((c) => c.stepName).toList(),
        containsAll([
          'reserve_inventory:compensate',
          'validate_order:compensate',
        ]),
      );

      engine.dispose();
    });

    test('first step fails -> no compensation needed',
        () async {
      final compensateLog = <String>[];

      final engine = createIntegrationEngine(store);

      Object? caught;
      try {
        await engine.run<void>(
          'early_fail',
          (ctx) async {
            await ctx.step<bool>(
              'step1',
              () async {
                throw Exception('Immediate failure');
              },
              compensate: (_) async {
                compensateLog.add('undo_step1');
              },
            );
          },
        );
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<Exception>());
      expect(compensateLog, isEmpty);

      engine.dispose();
    });
  });

  // =============================================
  // Scenario 2: Crash recovery — checkpoint-based resumption
  // =============================================
  group('Scenario 2: Crash recovery', () {
    test('crash after step 2 -> skip 1,2 -> execute 3',
        () async {
      final executionId = 'exec-0';
      final actionLog = <String>[];

      // Phase 1: Complete steps 1 and 2
      var engine = createIntegrationEngine(
        store,
        generateId: () => executionId,
      );

      await engine.run<String>(
        'order_processing',
        (ctx) async {
          await ctx.step<bool>('validate', () async {
            actionLog.add('validate');
            return true;
          });
          await ctx.step<String>('pay', () async {
            actionLog.add('pay');
            return 'PAY-001';
          });
          return 'incomplete';
        },
      );

      await simulateCrash(store, executionId);
      engine.dispose();
      actionLog.clear();

      // Phase 2: Recovery
      engine = createIntegrationEngine(
        store,
        generateId: () => 'should-not-be-called',
      );

      Future<String> fullWorkflow(
        WorkflowContext ctx,
      ) async {
        await ctx.step<bool>('validate', () async {
          actionLog.add('validate');
          return true;
        });
        await ctx.step<String>('pay', () async {
          actionLog.add('pay');
          return 'PAY-001';
        });
        final tracking =
            await ctx.step<String>('ship', () async {
          actionLog.add('ship');
          return 'TRACK-001';
        });
        return tracking;
      }

      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );
      final scanResult = await scanner.scan(
        workflowRegistry: {
          'order_processing': fullWorkflow,
        },
      );

      expect(scanResult.resumed, [executionId]);
      expect(scanResult.expired, isEmpty);
      expect(actionLog, ['ship']);

      final finalExec =
          await store.loadExecution(executionId);
      expect(finalExec!.status, isA<Completed>());

      final checkpoints =
          await store.loadCheckpoints(executionId);
      final completed = checkpoints
          .where((cp) => cp.status == StepStatus.completed)
          .toList();
      expect(completed, hasLength(3));

      engine.dispose();
    });
  });

  // =============================================
  // Scenario 3: TTL expiry
  // =============================================
  group('Scenario 3: TTL expiry', () {
    test('expired TTL -> FAILED without resuming', () async {
      final executionId = 'exec-0';

      var engine = createIntegrationEngine(
        store,
        generateId: () => executionId,
      );

      await engine.run<void>(
        'ttl_workflow',
        (ctx) async {
          await ctx.step<bool>(
            'step1',
            () async => true,
          );
        },
        ttl: Duration.zero,
      );

      await simulateCrash(store, executionId);
      engine.dispose();
      await Future<void>.delayed(
        const Duration(milliseconds: 10),
      );

      engine = createIntegrationEngine(store);

      final actionLog = <String>[];
      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );
      final result = await scanner.scan(
        workflowRegistry: {
          'ttl_workflow': (ctx) async {
            actionLog.add('should_not_run');
            await ctx.step<bool>(
              'step1',
              () async => true,
            );
          },
        },
      );

      expect(result.expired, contains(executionId));
      expect(result.resumed, isEmpty);
      expect(actionLog, isEmpty);

      final finalExec =
          await store.loadExecution(executionId);
      expect(finalExec!.status, isA<Failed>());
      expect(
        finalExec.errorMessage,
        contains('TTL expired'),
      );

      engine.dispose();
    });
  });

  // =============================================
  // Scenario 4: Crash recovery + re-execution failure -> Saga compensation
  // =============================================
  group('Scenario 4: Crash recovery + failure -> saga', () {
    test('recover then step 3 fails -> compensate 2,1',
        () async {
      final executionId = 'exec-0';
      final actionLog = <String>[];
      final compensateLog = <String>[];

      // Phase 1: Steps 1, 2 completed
      var engine = createIntegrationEngine(
        store,
        generateId: () => executionId,
      );

      await engine.run<String>(
        'complex_order',
        (ctx) async {
          await ctx.step<bool>('validate', () async {
            actionLog.add('validate');
            return true;
          });
          await ctx.step<String>('reserve', () async {
            actionLog.add('reserve');
            return 'RES-001';
          });
          return 'partial';
        },
      );

      await simulateCrash(store, executionId);
      engine.dispose();
      actionLog.clear();

      // Phase 2: Recovery — step 3 fails
      engine = createIntegrationEngine(
        store,
        generateId: () => 'unused',
      );

      Future<String> workflowWithFailure(
        WorkflowContext ctx,
      ) async {
        await ctx.step<bool>(
          'validate',
          () async {
            actionLog.add('validate');
            return true;
          },
          compensate: (_) async =>
              compensateLog.add('undo_validate'),
        );

        await ctx.step<String>(
          'reserve',
          () async {
            actionLog.add('reserve');
            return 'RES-001';
          },
          compensate: (_) async =>
              compensateLog.add('undo_reserve'),
        );

        await ctx.step<String>(
          'charge',
          () async {
            actionLog.add('charge_FAIL');
            throw Exception('Card declined');
          },
          compensate: (_) async =>
              compensateLog.add('refund'),
        );

        return 'never';
      }

      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );

      final result = await scanner.scan(
        workflowRegistry: {
          'complex_order': workflowWithFailure,
        },
      );

      expect(result.expired, contains(executionId));
      expect(actionLog, ['charge_FAIL']);
      expect(
        compensateLog,
        ['undo_reserve', 'undo_validate'],
      );

      final finalExec =
          await store.loadExecution(executionId);
      expect(finalExec!.status, isA<Failed>());

      final checkpoints =
          await store.loadCheckpoints(executionId);
      final compensatedCps = checkpoints
          .where((cp) => cp.status == StepStatus.compensated)
          .toList();
      expect(compensatedCps, hasLength(2));

      engine.dispose();
    });
  });

  // =============================================
  // Scenario 5: Multiple workflow simultaneous recovery
  // =============================================
  group('Scenario 5: Multiple interrupted workflows', () {
    test('2 resumed, 1 TTL-expired', () async {
      var counter = 0;

      var engine = createIntegrationEngine(
        store,
        generateId: () => 'exec-${counter++}',
      );

      // Workflow A & B: normal recovery
      await engine.run<void>('order', (ctx) async {
        await ctx.step<bool>(
          'validate',
          () async => true,
        );
      });
      await engine.run<void>('order', (ctx) async {
        await ctx.step<bool>(
          'validate',
          () async => true,
        );
      });

      // Workflow C: TTL expired
      await engine.run<void>(
        'order',
        (ctx) async {
          await ctx.step<bool>(
            'validate',
            () async => true,
          );
        },
        ttl: Duration.zero,
      );

      for (final id in ['exec-0', 'exec-1', 'exec-2']) {
        await simulateCrash(store, id);
      }

      engine.dispose();
      await Future<void>.delayed(
        const Duration(milliseconds: 10),
      );

      engine = createIntegrationEngine(
        store,
        generateId: () => 'unused',
      );

      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );
      final result = await scanner.scan(
        workflowRegistry: {
          'order': (ctx) async {
            await ctx.step<bool>(
              'validate',
              () async => true,
            );
          },
        },
      );

      expect(result.resumed, hasLength(2));
      expect(result.expired, contains('exec-2'));

      final expiredExec =
          await store.loadExecution('exec-2');
      expect(expiredExec!.status, isA<Failed>());
      expect(
        expiredExec.errorMessage,
        contains('TTL expired'),
      );

      for (final id in result.resumed) {
        final e = await store.loadExecution(id);
        expect(e!.status, isA<Completed>());
      }

      engine.dispose();
    });
  });

  // =============================================
  // Scenario 6: Compensation failure tolerance (skip-on-failure)
  // =============================================
  group('Scenario 6: Compensation failure tolerance', () {
    test('compensation failure does not block remaining',
        () async {
      final compensateLog = <String>[];

      final engine = createIntegrationEngine(store);

      Object? caught;
      try {
        await engine.run<void>(
          'fragile_saga',
          (ctx) async {
            await ctx.step<bool>(
              'step1',
              () async => true,
              compensate: (_) async {
                compensateLog.add('undo_step1');
              },
            );

            await ctx.step<bool>(
              'step2',
              () async => true,
              compensate: (_) async {
                compensateLog.add('undo_step2_FAIL');
                throw Exception('Compensation service down');
              },
            );

            await ctx.step<void>(
              'step3',
              () async {
                throw Exception('Step 3 failed');
              },
            );
          },
        );
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<Exception>());
      expect(compensateLog, contains('undo_step2_FAIL'));
      expect(compensateLog, contains('undo_step1'));

      engine.dispose();
    });
  });

  // =============================================
  // Scenario 7: E2E checkout workflow
  // =============================================
  group('Scenario 7: E2E checkout workflow', () {
    test('5-step: shipment fails -> compensation chain',
        () async {
      final log = <String>[];
      final compensateLog = <String>[];
      var shipAttempts = 0;

      final engine = createIntegrationEngine(store);

      Object? caught;
      try {
        await engine.run<String>(
          'full_checkout',
          (ctx) async {
            await ctx.step<bool>('validate', () async {
              log.add('validate');
              return true;
            });

            await ctx.step<int>(
              'reserve_inventory',
              () async {
                log.add('reserve_inventory');
                return 5;
              },
              compensate: (_) async {
                compensateLog.add('release_inventory(5)');
              },
            );

            await ctx.step<String>(
              'process_payment',
              () async {
                final txId = 'TXN-9999';
                log.add('process_payment($txId)');
                return txId;
              },
              compensate: (result) async {
                compensateLog.add('refund($result)');
              },
            );

            await ctx.step<String>(
              'create_order',
              () async {
                log.add('create_order');
                return 'ORD-001';
              },
              compensate: (_) async {
                compensateLog
                    .add('cancel_order(ORD-001)');
              },
            );

            await ctx.step<String>(
              'request_shipment',
              () async {
                shipAttempts++;
                log.add('ship_attempt_$shipAttempts');
                throw Exception(
                  'Warehouse system offline',
                );
              },
              retry: RetryPolicy.fixed(
                maxAttempts: 3,
                delay: Duration.zero,
              ),
              compensate: (_) async {
                compensateLog.add('cancel_shipment');
              },
            );

            return 'never';
          },
        );
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<Exception>());
      expect(
        caught.toString(),
        contains('Warehouse system offline'),
      );

      expect(log, [
        'validate',
        'reserve_inventory',
        'process_payment(TXN-9999)',
        'create_order',
        'ship_attempt_1',
        'ship_attempt_2',
        'ship_attempt_3',
      ]);

      expect(compensateLog, [
        'cancel_order(ORD-001)',
        'refund(TXN-9999)',
        'release_inventory(5)',
      ]);

      final exec = await store.loadExecution('exec-0');
      expect(exec!.status, isA<Failed>());

      final checkpoints =
          await store.loadCheckpoints('exec-0');

      final completed = checkpoints
          .where((cp) => cp.status == StepStatus.completed)
          .toList();
      expect(completed, hasLength(4));

      final compensated = checkpoints
          .where((cp) => cp.status == StepStatus.compensated)
          .toList();
      expect(compensated, hasLength(3));

      final failed = checkpoints
          .where(
            (cp) =>
                cp.status == StepStatus.failed &&
                cp.stepName == 'request_shipment',
          )
          .toList();
      expect(failed, hasLength(3));

      engine.dispose();
    });
  });

  // =============================================
  // Scenario 8: SUSPENDED state recovery
  // =============================================
  group('Scenario 8: Recovery of SUSPENDED execution', () {
    test('suspended -> recovered on scan', () async {
      final executionId = 'exec-0';
      final actionLog = <String>[];

      var engine = createIntegrationEngine(
        store,
        generateId: () => executionId,
      );

      await engine.run<void>('approval', (ctx) async {
        await ctx.step<bool>('submit', () async {
          actionLog.add('submit');
          return true;
        });
      });

      // Simulate being suspended during waitSignal
      final exec =
          await store.loadExecution(executionId);
      await store.saveExecution(exec!.copyWith(
        status: const Suspended(),
        updatedAt:
            DateTime.now().toUtc().toIso8601String(),
      ));
      engine.dispose();
      actionLog.clear();

      engine = createIntegrationEngine(
        store,
        generateId: () => 'unused',
      );

      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );
      final result = await scanner.scan(
        workflowRegistry: {
          'approval': (ctx) async {
            await ctx.step<bool>('submit', () async {
              actionLog.add('submit');
              return true;
            });
            await ctx.step<bool>('finalize', () async {
              actionLog.add('finalize');
              return true;
            });
          },
        },
      );

      expect(result.resumed, contains(executionId));
      expect(result.expired, isEmpty);
      expect(actionLog, ['finalize']);

      final finalExec =
          await store.loadExecution(executionId);
      expect(finalExec!.status, isA<Completed>());

      engine.dispose();
    });
  });

  // =============================================
  // Scenario 9: Unregistered workflow in registry
  // =============================================
  group('Scenario 9: Unregistered workflow type', () {
    test('recovery fails with descriptive error', () async {
      final executionId = 'exec-0';

      var engine = createIntegrationEngine(
        store,
        generateId: () => executionId,
      );

      await engine.run<void>('rare_workflow', (ctx) async {
        await ctx.step<bool>(
          'step1',
          () async => true,
        );
      });

      await simulateCrash(store, executionId);
      engine.dispose();

      engine = createIntegrationEngine(store);

      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );
      final result = await scanner.scan(
        workflowRegistry: {
          'other_workflow': (ctx) async {},
        },
      );

      expect(result.resumed, isEmpty);
      expect(result.expired, contains(executionId));

      final finalExec =
          await store.loadExecution(executionId);
      expect(finalExec!.status, isA<Failed>());
      expect(
        finalExec.errorMessage,
        contains('rare_workflow'),
      );
      expect(
        finalExec.errorMessage,
        contains('No registered workflow body'),
      );

      engine.dispose();
    });
  });

  // =============================================
  // Scenario 10: observe() stream state transitions
  // =============================================
  group('Scenario 10: Observe stream', () {
    test('captures compensation lifecycle', () async {
      final engine = createIntegrationEngine(store);

      final states = <String>[];
      final stream = engine.observe('exec-0');
      final sub = stream.listen((exec) {
        states.add(exec.status.name);
      });

      Object? caught;
      try {
        await engine.run<void>(
          'observed_saga',
          (ctx) async {
            await ctx.step<bool>(
              'step1',
              () async => true,
              compensate: (_) async {},
            );

            await ctx.step<void>(
              'step2',
              () async {
                throw Exception('Observed failure');
              },
            );
          },
        );
      } catch (e) {
        caught = e;
      }

      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      );
      await sub.cancel();

      expect(caught, isA<Exception>());
      expect(states, contains('RUNNING'));
      expect(states, contains('FAILED'));

      engine.dispose();
    });
  });

  // =============================================
  // Scenario 11: onRecoveryError callback
  // =============================================
  group('Scenario 11: onRecoveryError callback', () {
    test('invokes callback when resume fails', () async {
      final executionId = 'exec-0';

      var engine = createIntegrationEngine(
        store,
        generateId: () => executionId,
      );

      await engine.run<void>('failing_recovery', (ctx) async {
        await ctx.step<bool>('step1', () async => true);
      });

      await simulateCrash(store, executionId);
      engine.dispose();

      engine = createIntegrationEngine(store);

      final errors = <(String, Object)>[];
      final scanner = RecoveryScanner(
        store: store,
        engine: engine,
      );
      final result = await scanner.scan(
        workflowRegistry: {
          'failing_recovery': (ctx) async {
            await ctx.step<bool>('step1', () async => true);
            await ctx.step<bool>(
              'step2',
              () async => throw Exception('recovery boom'),
            );
          },
        },
        onRecoveryError: (id, error) => errors.add((id, error)),
      );

      expect(result.expired, contains(executionId));
      expect(errors, hasLength(1));
      expect(errors.first.$1, executionId);

      engine.dispose();
    });
  });
}
