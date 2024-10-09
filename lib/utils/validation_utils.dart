// ignore_for_file: unnecessary_type_check

import 'dart:convert';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'errors.dart';
import 'interfaces.dart';
import 'types.dart';
import 'logger.dart';

void validateFunctionParams(List<ParamValidation> params, String functionName) {
  for (var param in params) {
    if (param.input == null) {
      logger.info(
          'Validation failed: ${param.paramName} in $functionName is null or undefined');
      throw invalidParamError(
          '${param.paramName} passed to $functionName must not be null or undefined.');
    }
    if (param.isString && param.input is! String) {
      logger.info(
          'Validation failed: ${param.paramName} in $functionName is not a string');
      throw invalidParamError(
          '${param.paramName} passed to $functionName must be a string.');
    }
    if (param.isString && (param.input as String).trim().isEmpty) {
      logger.info(
          'Validation failed: ${param.paramName} in $functionName is an empty string');
      throw invalidParamError(
          '${param.paramName} passed to $functionName must not be an empty string.');
    }
  }
}

void validateURL(String url, String functionName) {
  try {
    Uri.parse(url);
  } catch (e) {
    logger.info(
        'URL validation failed for $url in $functionName: ${e.toString()}');
    throw invalidParamError(
        'Invalid URL format $url passed to $functionName.', e);
  }
}

void validateSignature(String providerId, String signature,
    String applicationId, String timestamp) {
  try {
    logger.info(
        'Starting signature validation for providerId: $providerId, applicationId: $applicationId, timestamp: $timestamp');

    final message =
        jsonEncode({'providerId': providerId, 'timestamp': timestamp});
    final messageHash = keccak256(utf8.encode(message));
    final appId = EthSigUtil.recoverPersonalSignature(
      signature: signature,
      message: messageHash,
    ).toLowerCase();

    if (EthereumAddress.fromHex(appId) !=
        EthereumAddress.fromHex(applicationId)) {
      logger.info(
          'Signature validation failed: Mismatch between derived appId ($appId) and provided applicationId ($applicationId)');
      throw invalidSignatureError(
          'Signature does not match the application id: $appId');
    }

    logger.info(
        'Signature validated successfully for applicationId: $applicationId');
  } catch (err) {
    logger.info('Signature validation failed: ${err.toString()}');
    throw invalidSignatureError(
        'Failed to validate signature: ${err.toString()}');
  }
}

void validateRequestedProof(RequestedProof requestedProof) {
  logger.info('Validating requested proof: $requestedProof');
  if (requestedProof.url.isEmpty) {
    logger.info(
        'Requested proof validation failed: Provided url in requested proof is not valid');
    throw invalidParamError('The provided url in requested proof is not valid');
  }

  if (requestedProof.parameters is! Map<String, dynamic>) {
    logger.info(
        'Requested proof validation failed: Provided parameters in requested proof is not valid');
    throw invalidParamError(
        'The provided parameters in requested proof is not valid');
  }
}

void validateContext(Context context) {
  if (context.contextAddress.isEmpty) {
    logger.info(
        'Context validation failed: Provided context address in context is not valid');
    throw invalidParamError(
        'The provided context address in context is not valid');
  }

  if (context.contextMessage.isEmpty) {
    logger.info(
        'Context validation failed: Provided context message in context is not valid');
    throw invalidParamError(
        'The provided context message in context is not valid');
  }

  validateFunctionParams([
    ParamValidation(
        input: context.contextAddress,
        paramName: 'contextAddress',
        isString: true),
    ParamValidation(
        input: context.contextMessage,
        paramName: 'contextMessage',
        isString: true)
  ], 'validateContext');
}

void validateOptions(ProofRequestOptions options) {
  if (options.acceptAiProviders != null && options.acceptAiProviders is! bool) {
    logger.info(
        'Options validation failed: Provided acceptAiProviders in options is not valid');
    throw invalidParamError(
        'The provided acceptAiProviders in options is not valid');
  }

  if (options.log != null && options.log is! bool) {
    logger.info(
        'Options validation failed: Provided log in options is not valid');
    throw invalidParamError('The provided log in options is not valid');
  }
}

class ParamValidation {
  final dynamic input;
  final String paramName;
  final bool isString;

  ParamValidation(
      {required this.input, required this.paramName, this.isString = false});
}
