class ReclaimError implements Exception {
  final String message;
  final dynamic innerError;
  final String errorName;

  ReclaimError(this.errorName, this.message, [this.innerError]);

  @override
  String toString() {
    if (innerError != null) {
      return '$errorName: $message\nCaused by: ${innerError.toString()}';
    }
    return '$errorName: $message';
  }
}

typedef ErrorConstructor = ReclaimError Function(String message,
    [dynamic innerError]);

ErrorConstructor _createErrorClass(String name) {
  return (String message, [dynamic innerError]) {
    return ReclaimError(name, message, innerError);
  };
}

final timeoutError = _createErrorClass('TimeoutError');
final proofNotVerifiedError = _createErrorClass('ProofNotVerifiedError');
final sessionNotStartedError = _createErrorClass('SessionNotStartedError');
final providerNotFoundError = _createErrorClass('ProviderNotFoundError');
final buildProofRequestError = _createErrorClass('BuildProofRequestError');
final signatureGeneratingError = _createErrorClass('SignatureGeneratingError');
final signatureNotFoundError = _createErrorClass('SignatureNotFoundError');
final invalidSignatureError = _createErrorClass('InvalidSignatureError');
final updateSessionError = _createErrorClass('UpdateSessionError');
final initSessionError = _createErrorClass('InitSessionError');
final providerFailedError = _createErrorClass('ProviderFailedError');
final invalidParamError = _createErrorClass('InvalidParamError');
final applicationError = _createErrorClass('ApplicationError');
final initError = _createErrorClass('InitError');
final availableParamsError = _createErrorClass('AvailableParamsError');
final backendServerError = _createErrorClass('BackendServerError');
final getStatusUrlError = _createErrorClass('GetStatusUrlError');
final noProviderParamsError = _createErrorClass('NoProviderParamsError');
final setParamsError = _createErrorClass('SetParamsError');
final addContextError = _createErrorClass('AddContextError');
final setSignatureError = _createErrorClass('SetSignatureError');
final getAppCallbackUrlError = _createErrorClass('GetAppCallbackUrlError');
final getRequestUrlError = _createErrorClass('GetRequestUrlError');
final setAppCallbackUrlError = _createErrorClass('SetAppCallbackUrlError');
final setRedirectUrlError = _createErrorClass('SetRedirectUrlError');
final getRequestedProofError = _createErrorClass('GetRequestedProofError');
final sessionTimeoutError = _createErrorClass('SessionTimeoutError');
final statusUrlError = _createErrorClass('StatusUrlError');
