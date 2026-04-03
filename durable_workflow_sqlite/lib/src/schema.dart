/// Current schema version.
const int schemaVersion = 1;

/// DDL statements for schema version 1.
///
/// Creates all tables and indexes for the durable workflow persistence layer.
/// Table names use domain-prefixed naming convention.
const List<String> schemaV1Statements = [
  // Workflow definitions
  '''
  CREATE TABLE workflows (
    workflow_id    TEXT PRIMARY KEY,
    workflow_type  TEXT NOT NULL,
    version        INTEGER NOT NULL DEFAULT 1,
    created_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now'))
  )
  ''',

  // Workflow execution instances
  '''
  CREATE TABLE workflow_executions (
    workflow_execution_id  TEXT PRIMARY KEY,
    workflow_id            TEXT NOT NULL REFERENCES workflows(workflow_id),
    status                 TEXT NOT NULL DEFAULT 'PENDING'
                           CHECK(status IN ('PENDING','RUNNING','SUSPENDED','COMPLETED','FAILED','COMPENSATING','CANCELLED')),
    current_step           INTEGER DEFAULT 0,
    input_data             TEXT,
    output_data            TEXT,
    error_message          TEXT,
    ttl_expires_at         TEXT,
    guarantee              TEXT NOT NULL DEFAULT 'FOREGROUND_ONLY',
    created_at             TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
    updated_at             TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now'))
  )
  ''',

  'CREATE INDEX idx_wf_exec_status ON workflow_executions(status)',
  'CREATE INDEX idx_wf_exec_workflow ON workflow_executions(workflow_id)',

  // Step checkpoints
  '''
  CREATE TABLE step_checkpoints (
    id                      INTEGER PRIMARY KEY AUTOINCREMENT,
    workflow_execution_id   TEXT NOT NULL REFERENCES workflow_executions(workflow_execution_id),
    step_index              INTEGER NOT NULL,
    step_name               TEXT NOT NULL,
    status                  TEXT NOT NULL CHECK(status IN ('INTENT','COMPLETED','FAILED','COMPENSATED')),
    input_data              TEXT,
    output_data             TEXT,
    error_message           TEXT,
    attempt                 INTEGER DEFAULT 1,
    idempotency_key         TEXT,
    compensate_ref          TEXT,
    started_at              TEXT,
    completed_at            TEXT,
    UNIQUE(workflow_execution_id, step_index, attempt)
  )
  ''',

  'CREATE INDEX idx_step_cp_exec ON step_checkpoints(workflow_execution_id, step_index)',

  // Workflow timers (durable timer)
  '''
  CREATE TABLE workflow_timers (
    workflow_timer_id       TEXT PRIMARY KEY,
    workflow_execution_id   TEXT NOT NULL REFERENCES workflow_executions(workflow_execution_id),
    step_name               TEXT NOT NULL,
    fire_at                 TEXT NOT NULL,
    status                  TEXT NOT NULL DEFAULT 'PENDING'
                            CHECK(status IN ('PENDING','FIRED','CANCELLED')),
    created_at              TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now'))
  )
  ''',

  'CREATE INDEX idx_wf_timer_fire ON workflow_timers(status, fire_at)',

  // Workflow signals
  '''
  CREATE TABLE workflow_signals (
    workflow_signal_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    workflow_execution_id   TEXT NOT NULL REFERENCES workflow_executions(workflow_execution_id),
    signal_name             TEXT NOT NULL,
    payload                 TEXT,
    status                  TEXT NOT NULL DEFAULT 'PENDING'
                            CHECK(status IN ('PENDING','DELIVERED','EXPIRED')),
    created_at              TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now'))
  )
  ''',

  'CREATE INDEX idx_wf_signal_pending ON workflow_signals(workflow_execution_id, signal_name, status)',
];

/// PRAGMA statements applied on every database connection open.
const List<String> pragmaStatements = [
  'PRAGMA journal_mode = WAL',
  'PRAGMA foreign_keys = ON',
  'PRAGMA synchronous = NORMAL',
  'PRAGMA busy_timeout = 5000',
  'PRAGMA cache_size = -8000', // 8 MB page cache
  'PRAGMA temp_store = MEMORY',
  'PRAGMA mmap_size = 268435456', // 256 MB memory-mapped I/O
];
