import 'dart:async';

import 'package:durable_workflow/durable_workflow.dart';

/// Manages automatic recovery scanning when the app returns to the foreground.
///
/// When the app resumes from a paused/inactive state, [scan] is called to
/// detect and resume any interrupted workflow executions. A debounce mechanism
/// prevents redundant scans during rapid lifecycle transitions.
class ForegroundRecovery {
  final DurableEngineImpl _engine;
  final Map<String, Future<dynamic> Function(WorkflowContext)> _registry;
  final Duration _debounce;
  late final RecoveryScanner _scanner;

  DateTime? _lastScanAt;
  Future<RecoveryScanResult>? _pendingScan;
  final StreamController<RecoveryScanResult> _resultController =
      StreamController<RecoveryScanResult>.broadcast();

  /// Creates a [ForegroundRecovery].
  ///
  /// - [engine]: The durable engine instance to use for recovery.
  /// - [registry]: Maps workflow type names to their body functions,
  ///   enabling the recovery scanner to re-execute workflows.
  /// - [debounce]: Minimum interval between scans. Defaults to 5 seconds.
  ForegroundRecovery({
    required DurableEngineImpl engine,
    required Map<String, Future<dynamic> Function(WorkflowContext)> registry,
    Duration debounce = const Duration(seconds: 5),
  })  : _engine = engine,
        _registry = registry,
        _debounce = debounce {
    _scanner = RecoveryScanner(store: _engine.store, engine: _engine);
  }

  /// Stream of recovery scan results.
  ///
  /// Emits a [RecoveryScanResult] each time a scan completes,
  /// including the lists of resumed and expired execution IDs.
  Stream<RecoveryScanResult> get results => _resultController.stream;

  /// Performs an initial recovery scan at app startup.
  ///
  /// Unlike [scan], this ignores the debounce window since it's
  /// the first scan after engine initialization. If a scan is already
  /// in progress, returns the in-flight result.
  Future<RecoveryScanResult> initialScan() =>
      _pendingScan ??= _doScan();

  /// Performs a recovery scan if the debounce window has elapsed.
  ///
  /// Returns the in-flight result if a scan is already running,
  /// an empty result if debounced, or starts a new scan otherwise.
  Future<RecoveryScanResult> scan() {
    if (_pendingScan != null) return _pendingScan!;
    if (_shouldDebounce()) {
      return Future.value(const RecoveryScanResult(resumed: [], expired: []));
    }
    return _pendingScan = _doScan();
  }

  Future<RecoveryScanResult> _doScan() async {
    try {
      final result = await _scanner.scan(workflowRegistry: _registry);
      _lastScanAt = DateTime.now();
      _resultController.add(result);
      return result;
    } finally {
      _pendingScan = null;
    }
  }

  bool _shouldDebounce() {
    if (_lastScanAt == null) return false;
    return DateTime.now().difference(_lastScanAt!) < _debounce;
  }

  /// Releases resources.
  void dispose() {
    _resultController.close();
  }
}
