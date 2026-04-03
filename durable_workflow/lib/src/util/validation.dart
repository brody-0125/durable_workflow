/// Maximum allowed length for string identifiers (workflow type, step name, signal name).
const int maxIdentifierLength = 256;

/// Pattern matching control characters (U+0000–U+001F and U+007F).
final RegExp _controlChars = RegExp(r'[\x00-\x1f\x7f]');

/// Validates a string identifier used in the public API.
///
/// Throws [ArgumentError] if [value] is empty, whitespace-only,
/// contains control characters, or exceeds [maxIdentifierLength].
void validateIdentifier(String value, String paramName) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, paramName, 'must not be empty');
  }
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, paramName, 'must not be whitespace-only');
  }
  if (value.length > maxIdentifierLength) {
    throw ArgumentError.value(
      value,
      paramName,
      'must not exceed $maxIdentifierLength characters '
          '(was ${value.length})',
    );
  }
  if (_controlChars.hasMatch(value)) {
    throw ArgumentError.value(
      value,
      paramName,
      'must not contain control characters',
    );
  }
}
