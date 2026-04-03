/// Returns the current UTC time as an ISO 8601 string.
///
/// Centralizes the `DateTime.now().toUtc().toIso8601String()` pattern
/// used throughout the engine for consistent timestamp generation.
String utcNow() => DateTime.now().toUtc().toIso8601String();
