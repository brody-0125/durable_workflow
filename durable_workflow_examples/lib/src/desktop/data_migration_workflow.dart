/// Desktop: Data Migration Workflow
///
/// Use case:
///   Local data migration during app version upgrades.
///   Create backup → schema conversion → batch data migration → index rebuild → validation → cleanup
///
/// Common approaches in existing Flutter apps:
///   - Package manager apps: no step-by-step state tracking during download→install→register
///   - App installer apps: parse→install→permissions. Manual cleanup on failure
///   - Build/deploy tools: build→package→deploy pipeline. Full re-execution on mid-failure
///   - File transfer apps: cannot resume after interruption during transfer
///   - Native backend delegation: delegates durable connection management to Rust etc. (not possible with Flutter alone)
///
/// With durable_workflow:
///   - Batch migration split into steps → progress tracking + partial rollback on failure
///   - Desktop has fewer background restrictions than mobile, making foregroundOnly guarantee stronger
///   - Large datasets are split into batch steps for memory-efficient processing
///
/// Note: Dynamic step names ('migrate_batch_$i')
///   Must re-execute with the same batchSize after crash recovery so that totalBatches matches.
///   Store MigrationPlan parameters as workflow input in checkpoint to guarantee this.
library;

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/testing.dart';

// ---------------------------------------------------------------------------
// Simulated migration services
// ---------------------------------------------------------------------------

class MigrationPlan {
  final String sourceVersion;
  final String targetVersion;
  final int totalRecords;
  final int batchSize;

  MigrationPlan({
    required this.sourceVersion,
    required this.targetVersion,
    required this.totalRecords,
    this.batchSize = 1000,
  });

  int get totalBatches => (totalRecords / batchSize).ceil();

  Map<String, dynamic> toJson() => {
        'sourceVersion': sourceVersion,
        'targetVersion': targetVersion,
        'totalRecords': totalRecords,
        'totalBatches': totalBatches,
      };
}

Future<String> createBackup(String dbPath) async {
  await Future.delayed(const Duration(milliseconds: 300));
  final backupPath = '$dbPath.backup-${DateTime.now().millisecondsSinceEpoch}';
  print('    [step] Backup created: $backupPath');
  return backupPath;
}

Future<void> restoreFromBackup(String backupPath, String dbPath) async {
  await Future.delayed(const Duration(milliseconds: 200));
  print('    [compensate] Restored from backup: $backupPath → $dbPath');
}

Future<bool> applySchemaChanges(String targetVersion) async {
  await Future.delayed(const Duration(milliseconds: 200));
  print('    [step] Schema changes applied: v$targetVersion (ALTER TABLE, ADD COLUMN, etc.)');
  return true;
}

Future<int> migrateBatch(int batchIndex, int batchSize, int totalRecords) async {
  final start = batchIndex * batchSize;
  final end = (start + batchSize).clamp(0, totalRecords);
  final count = end - start;
  await Future.delayed(const Duration(milliseconds: 100));
  print('    [step] Batch $batchIndex migrated: records $start~$end ($count rows)');
  return count;
}

Future<bool> rebuildIndexes() async {
  await Future.delayed(const Duration(milliseconds: 200));
  print('    [step] Index rebuild completed');
  return true;
}

Future<Map<String, int>> validateMigration(int expectedRecords) async {
  await Future.delayed(const Duration(milliseconds: 150));
  final result = {
    'expected': expectedRecords,
    'actual': expectedRecords,
    'errors': 0,
  };
  print('    [step] Validation completed: ${result['actual']}/${result['expected']} rows, ${result['errors']} errors');
  return result;
}

Future<void> cleanupTempFiles(String backupPath) async {
  await Future.delayed(const Duration(milliseconds: 50));
  print('    [step] Temp files cleaned up: $backupPath');
}

// ---------------------------------------------------------------------------
// Workflow definition
// ---------------------------------------------------------------------------

/// Data migration workflow
///
/// Handles long-running tasks that tools like flutter_distributor, AppImagePool, etc.
/// handle via full re-execution, using batch-level checkpoints with durable workflow.
///
/// Crash scenario:
///   1. System restart after migrating batch 5/10 of 10,000 records
///   2. RecoveryScanner resumes execution
///   3. Backup creation, schema changes, batches 1~5 are skipped from cache
///   4. Migration continues from batch 6
///   5. On total failure, auto-restore from backup (saga compensation)
Future<Map<String, int>> dataMigrationWorkflow(
  WorkflowContext ctx, {
  required String dbPath,
  required MigrationPlan plan,
}) async {
  // Step 1: Create backup (compensation: restore from backup)
  final backupPath = await ctx.step<String>(
    'create_backup',
    () => createBackup(dbPath),
    compensate: (result) => restoreFromBackup(result, dbPath),
  );

  // Step 2: Apply schema changes
  await ctx.step<bool>(
    'apply_schema',
    () => applySchemaChanges(plan.targetVersion),
  );

  // Steps 3~N: Batch data migration
  var totalMigrated = 0;
  for (var i = 0; i < plan.totalBatches; i++) {
    final migrated = await ctx.step<int>(
      'migrate_batch_$i',
      () => migrateBatch(i, plan.batchSize, plan.totalRecords),
    );
    totalMigrated += migrated;
  }

  // Step N+1: Rebuild indexes
  await ctx.step<bool>(
    'rebuild_indexes',
    () => rebuildIndexes(),
  );

  // Step N+2: Validation
  final validation = await ctx.step<Map<String, int>>(
    'validate',
    () => validateMigration(plan.totalRecords),
  );

  // Step N+3: Clean up temp files
  await ctx.step<bool>(
    'cleanup',
    () async {
      await cleanupTempFiles(backupPath);
      return true;
    },
  );

  return validation;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  final engine = DurableEngineImpl(
    store: InMemoryCheckpointStore(),
  );

  try {
    print('=== Desktop: Data Migration Workflow ===\n');

    final plan = MigrationPlan(
      sourceVersion: '2.1.0',
      targetVersion: '3.0.0',
      totalRecords: 5000,
      batchSize: 1000,
    );

    print('  Migration plan: v${plan.sourceVersion} → v${plan.targetVersion}');
    print('  Total ${plan.totalRecords} records, ${plan.totalBatches} batches\n');

    final result = await engine.run<Map<String, int>>(
      'data_migration',
      (ctx) => dataMigrationWorkflow(
        ctx,
        dbPath: '/data/app.db',
        plan: plan,
      ),
    );

    print('\n  Migration completed: $result');
  } catch (e) {
    print('\n  Migration failed: $e');
  } finally {
    engine.dispose();
  }
}
