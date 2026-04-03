@Tags(['unit'])
library;

import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  late SqliteCheckpointStore store;

  setUp(() {
    store = SqliteCheckpointStore.inMemory();
  });

  tearDown(() {
    store.close();
  });

  group('schema', () {
    test('creates all 5 tables', () {
      final result = store.database.select(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      );
      final tables =
          result.map((r) => r['name'] as String).toList();

      expect(tables, containsAll([
        'step_checkpoints',
        'workflow_executions',
        'workflow_signals',
        'workflow_timers',
        'workflows',
      ]));
    });

    test('creates all 5 indexes', () {
      final result = store.database.select(
        "SELECT name FROM sqlite_master WHERE type='index' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      );
      final indexes =
          result.map((r) => r['name'] as String).toList();

      expect(indexes, containsAll([
        'idx_step_cp_exec',
        'idx_wf_exec_status',
        'idx_wf_exec_workflow',
        'idx_wf_signal_pending',
        'idx_wf_timer_fire',
      ]));
    });

    test('user_version is set to $schemaVersion', () {
      final result =
          store.database.select('PRAGMA user_version');
      expect(
        result.first['user_version'],
        equals(schemaVersion),
      );
    });

    test('workflows table has correct columns', () {
      final result = store.database.select(
        "PRAGMA table_info('workflows')",
      );
      final columns =
          result.map((r) => r['name'] as String).toList();
      expect(columns, equals([
        'workflow_id',
        'workflow_type',
        'version',
        'created_at',
      ]));
    });

    test('workflow_executions table has correct columns',
        () {
      final result = store.database.select(
        "PRAGMA table_info('workflow_executions')",
      );
      final columns =
          result.map((r) => r['name'] as String).toList();
      expect(columns, equals([
        'workflow_execution_id',
        'workflow_id',
        'status',
        'current_step',
        'input_data',
        'output_data',
        'error_message',
        'ttl_expires_at',
        'guarantee',
        'created_at',
        'updated_at',
      ]));
    });

    test('step_checkpoints table has correct columns', () {
      final result = store.database.select(
        "PRAGMA table_info('step_checkpoints')",
      );
      final columns =
          result.map((r) => r['name'] as String).toList();
      expect(columns, equals([
        'id',
        'workflow_execution_id',
        'step_index',
        'step_name',
        'status',
        'input_data',
        'output_data',
        'error_message',
        'attempt',
        'idempotency_key',
        'compensate_ref',
        'started_at',
        'completed_at',
      ]));
    });
  });

  group('PRAGMAs', () {
    test('journal_mode is WAL or memory', () {
      final result =
          store.database.select('PRAGMA journal_mode');
      final mode = result.first['journal_mode'] as String;
      expect(mode, anyOf(equals('wal'), equals('memory')));
    });

    test('foreign_keys is ON', () {
      final result =
          store.database.select('PRAGMA foreign_keys');
      expect(result.first['foreign_keys'], equals(1));
    });

    test('synchronous is NORMAL (1)', () {
      final result =
          store.database.select('PRAGMA synchronous');
      expect(result.first['synchronous'], equals(1));
    });

    test('busy_timeout is 5000', () {
      final result =
          store.database.select('PRAGMA busy_timeout');
      expect(result.first['timeout'], equals(5000));
    });

    test('cache_size is -8000', () {
      final result =
          store.database.select('PRAGMA cache_size');
      expect(result.first['cache_size'], equals(-8000));
    });

    test('temp_store is MEMORY (2)', () {
      final result =
          store.database.select('PRAGMA temp_store');
      expect(result.first['temp_store'], equals(2));
    });

    test('mmap_size PRAGMA accepted', () {
      final result =
          store.database.select('PRAGMA mmap_size');
      // In-memory databases may return empty result for mmap_size.
      // Just verify the PRAGMA doesn't throw.
      expect(result, isA<List>());
    });
  });

  group('migrations', () {
    test('migrate is idempotent', () {
      migrate(store.database);
      final result =
          store.database.select('PRAGMA user_version');
      expect(result.first['user_version'], equals(1));
    });

    test('throws StateError if DB version is newer', () {
      final db = sqlite3.openInMemory();
      db.execute('PRAGMA user_version = 999');
      expect(() => migrate(db), throwsStateError);
      db.dispose();
    });
  });

  group('validateSchema', () {
    test('returns valid for correct schema', () {
      final result = store.validateSchema();
      expect(result.isValid, isTrue);
      expect(result.missingTables, isEmpty);
      expect(result.missingIndexes, isEmpty);
      expect(result.pragmaIssues, isEmpty);
    });

    test('detects missing table', () {
      store.database.execute('DROP TABLE workflow_signals');
      final result = store.validateSchema();
      expect(result.isValid, isFalse);
      expect(
        result.missingTables,
        contains('workflow_signals'),
      );
    });

    test('detects missing index', () {
      store.database.execute(
        'DROP INDEX idx_wf_timer_fire',
      );
      final result = store.validateSchema();
      expect(result.isValid, isFalse);
      expect(
        result.missingIndexes,
        contains('idx_wf_timer_fire'),
      );
    });
  });

  group('constructors', () {
    test('raw Database constructor applies schema', () {
      final db = sqlite3.openInMemory();
      final s = SqliteCheckpointStore(db);
      final ver = db.select('PRAGMA user_version');
      expect(ver.first['user_version'], equals(1));
      s.close();
    });

    test('inMemory factory works', () {
      final s = SqliteCheckpointStore.inMemory();
      final ver = s.database.select('PRAGMA user_version');
      expect(ver.first['user_version'], equals(1));
      s.close();
    });
  });
}
