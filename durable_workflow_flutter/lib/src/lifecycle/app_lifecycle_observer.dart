import 'package:flutter/widgets.dart';

import '../adapter/background_adapter.dart';
import 'foreground_recovery.dart';

/// Observes Flutter app lifecycle changes and triggers workflow recovery.
///
/// Integrates with [WidgetsBindingObserver] to:
/// - Run a recovery scan when the app returns to the foreground
/// - Schedule background recovery when the app is paused
/// - Clean up resources when the app is detached
class AppLifecycleObserver with WidgetsBindingObserver {
  final ForegroundRecovery _recovery;
  final BackgroundAdapter _backgroundAdapter;

  /// Optional callback invoked when the app resumes to the foreground.
  final VoidCallback? onResumed;

  /// Optional callback invoked when the app enters the background.
  final VoidCallback? onPaused;

  bool _isRegistered = false;

  /// Creates an [AppLifecycleObserver].
  ///
  /// - [recovery]: The foreground recovery manager.
  /// - [backgroundAdapter]: The platform-specific background adapter.
  /// - [onResumed]: Called after the app returns to the foreground.
  /// - [onPaused]: Called after the app enters the background.
  AppLifecycleObserver({
    required ForegroundRecovery recovery,
    required BackgroundAdapter backgroundAdapter,
    this.onResumed,
    this.onPaused,
  })  : _recovery = recovery,
        _backgroundAdapter = backgroundAdapter;

  /// Registers this observer with [WidgetsBinding].
  ///
  /// Must be called after [WidgetsFlutterBinding.ensureInitialized].
  void register() {
    if (_isRegistered) return;
    WidgetsBinding.instance.addObserver(this);
    _isRegistered = true;
  }

  /// Unregisters this observer from [WidgetsBinding].
  void unregister() {
    if (!_isRegistered) return;
    WidgetsBinding.instance.removeObserver(this);
    _isRegistered = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _recovery.scan();
        onResumed?.call();
      case AppLifecycleState.paused:
        _backgroundAdapter.scheduleRecovery();
        onPaused?.call();
      default:
        break;
    }
  }

  /// Cleans up: unregisters from binding and cancels background tasks.
  void dispose() {
    unregister();
    _backgroundAdapter.cancelAll();
  }
}
