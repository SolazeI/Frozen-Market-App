/// Domain-level error with a message that is safe to show to users.
class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The user backed out of a flow (e.g. closed the Google account picker).
/// UI should ignore this silently.
class CancelledException extends AppException {
  const CancelledException() : super('Cancelled');
}
