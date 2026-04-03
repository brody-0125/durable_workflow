/// Abstract interface for platform-specific background execution adapters.
///
/// Implementations integrate with platform mechanisms like Android's
/// WorkManager or iOS's BGTaskScheduler to attempt workflow recovery
/// while the app is in the background.
///
/// Background execution is **best-effort only** — neither Android nor iOS
/// guarantees that scheduled background tasks will actually run.
/// The primary recovery mechanism is [ForegroundRecovery], which runs
/// a recovery scan when the app returns to the foreground.
///
/// To use a background adapter, implement this interface and pass it to
/// [DurableWorkflowProvider]:
///
/// ```dart
/// DurableWorkflowProvider(
///   store: myStore,
///   workflowRegistry: myRegistry,
///   backgroundAdapter: MyWorkManagerAdapter(),
///   child: MyApp(),
/// )
/// ```
abstract class BackgroundAdapter {
  /// Initializes the background adapter.
  ///
  /// Called once during [DurableWorkflowProvider] initialization.
  /// Use this to register background task handlers with the platform.
  Future<void> initialize();

  /// Schedules a background recovery scan.
  ///
  /// Called when the app transitions to the background (paused state).
  /// The implementation should schedule a platform-specific background task
  /// that will invoke [RecoveryScanner.scan] to resume interrupted workflows.
  Future<void> scheduleRecovery();

  /// Cancels all scheduled background tasks.
  ///
  /// Called when the adapter is no longer needed or when the app
  /// is being disposed.
  Future<void> cancelAll();

  /// Releases resources held by the adapter.
  Future<void> dispose();
}
