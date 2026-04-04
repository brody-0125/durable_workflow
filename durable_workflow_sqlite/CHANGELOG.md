## 0.2.0

- Implement new `CheckpointStore` methods: `saveCheckpoints()`, `deleteOldTimers()`, `deleteOldSignals()`.
- `saveCheckpoints()` now has `@override` annotation (was missing).
- Requires `durable_workflow: ^0.2.0`.

## 0.1.2

- Widen sqlite3 constraint to `>=2.9.4 <4.0.0` for sqlite3 3.x compatibility.

## 0.1.1

- Tighten dependency constraints (sqlite3 ^2.9.4, meta ^1.18.2) for pub.dev scoring.
- Rename example file to `example.dart` for pub.dev recognition.

## 0.1.0

- Initial release.
- SQLite implementation of `CheckpointStore` using sqlite3 FFI.
- Schema migration support for forward-compatible upgrades.
- Transaction-safe checkpoint persistence.
- Full contract compliance with `durable_workflow` persistence interface.
