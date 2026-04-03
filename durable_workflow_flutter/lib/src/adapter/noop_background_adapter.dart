import 'background_adapter.dart';

/// A no-op [BackgroundAdapter] that does nothing.
///
/// Used as the default when no platform-specific background adapter
/// is provided. This ensures the foreground-only recovery path works
/// without requiring any background plugin dependency.
class NoopBackgroundAdapter implements BackgroundAdapter {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleRecovery() async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> dispose() async {}
}
