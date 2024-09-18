class ProofNotVerifiedError implements Exception {
  final String message;

  ProofNotVerifiedError([this.message = '']);

  @override
  String toString() => 'ProofNotVerifiedError: $message';
}

class SessionNotStartedError implements Exception {
  final String message;

  SessionNotStartedError([this.message = '']);

  @override
  String toString() => 'SessionNotStartedError: $message';
}

class ProviderAPIError implements Exception {
  final String message;

  ProviderAPIError([this.message = '']);

  @override
  String toString() => 'ProviderAPIError: $message';
}

class BuildProofRequestError implements Exception {
  final String message;

  BuildProofRequestError([this.message = '']);

  @override
  String toString() => 'BuildProofRequestError: $message';
}

class SignatureGeneratingError implements Exception {
  final String message;

  SignatureGeneratingError([this.message = '']);

  @override
  String toString() => 'SignatureGeneratingError: $message';
}

class SignatureNotFoundError implements Exception {
  final String message;

  SignatureNotFoundError([this.message = '']);

  @override
  String toString() => 'SignatureNotFoundError: $message';
}

class InvalidSignatureError implements Exception {
  final String message;

  InvalidSignatureError([this.message = '']);

  @override
  String toString() => 'InvalidSignatureError: $message';
}

class UpdateSessionError implements Exception {
  final String message;

  UpdateSessionError([this.message = '']);

  @override
  String toString() => 'UpdateSessionError: $message';
}

class CreateSessionError implements Exception {
  final String message;

  CreateSessionError([this.message = '']);

  @override
  String toString() => 'CreateSessionError: $message';
}

class ProviderFailedError implements Exception {
  final String message;

  ProviderFailedError([this.message = '']);

  @override
  String toString() => 'ProviderFailedError: $message';
}

class ProofNotReceivedError implements Exception {
  final String message;

  ProofNotReceivedError([this.message = '']);

  @override
  String toString() => 'ProofNotReceivedError: $message';
}

class GetSessionError implements Exception {
  final String message;

  GetSessionError([this.message = '']);

  @override
  String toString() => 'GetSessionError: $message';
}

class ProofCallbackError implements Exception {
  final String message;

  ProofCallbackError([this.message = '']);

  @override
  String toString() => 'ProofCallbackError: $message';
}
