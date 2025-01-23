import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:reclaim_sdk/witness.dart';
import 'package:web3dart/crypto.dart';

import 'utils/interfaces.dart';
import 'utils/types.dart';
import 'utils/constants.dart';
import 'utils/errors.dart';
import 'utils/validation_utils.dart';
import 'utils/session_utils.dart';
import 'utils/proof_utils.dart';
import 'utils/logger.dart';
import 'utils/helper.dart';
import 'dart:io';
import 'utils/sdk_version.dart';

var logger = ReclaimLogger();

Future<bool> verifyProof(dynamic proofInput) async {
  // Handle array of proofs
  if (proofInput is List) {
    try {
      for (var proof in proofInput) {
        bool isValid = await verifyProof(proof);
        if (!isValid) {
          return false;
        }
      }
      return true;
    } catch (e) {
      logger.info('Error verifying array of proofs: ${e.toString()}');
      return false;
    }
  }

  // Handle single proof
  final proof = proofInput as Proof;
  if (proof.signatures.isEmpty) {
    logger.info('No signatures');
    throw signatureNotFoundError('No signatures');
  }

  try {
    List<String> witnesses = [];
    if (proof.witnesses.isNotEmpty &&
        proof.witnesses[0].url == 'manual-verify') {
      witnesses.add(proof.witnesses[0].id);
    } else {
      witnesses = await getWitnessesForClaim(
          proof.claimData.epoch, proof.identifier, proof.claimData.timestampS);
    }

    ClaimInfo claimInfo = ClaimInfo.fromJson(proof.claimData.toJson());
    // then hash the claim info with the encoded ctx to get the identifier
    final calculatedIdentifier = getIdentifierFromClaimInfo(claimInfo);

    proof.identifier = proof.identifier.replaceAll('"', '');
    if (calculatedIdentifier != proof.identifier) {
      logger.info('Identifier Mismatch');
      throw proofNotVerifiedError('Identifier Mismatch');
    }

    final signedClaim = SignedClaim(
      claim: proof.claimData,
      signatures: proof.signatures.map((s) => hexToBytes(s)).toList(),
    );

    assertValidSignedClaim(signedClaim, witnesses);
  } catch (e) {
    logger.info('Error verifying proof: ${e.toString()}');
    return false;
  }

  return true;
}

Map<String, dynamic> transformForOnchain(Proof proof) {
  final claimInfo = {
    'context': proof.claimData.context,
    'parameters': proof.claimData.parameters,
    'provider': proof.claimData.provider,
  };
  final claim = {
    'epoch': proof.claimData.epoch,
    'identifier': proof.claimData.identifier,
    'owner': proof.claimData.owner,
    'timestampS': proof.claimData.timestampS,
  };
  final signedClaim = {'claim': claim, 'signatures': proof.signatures};
  return {'claimInfo': claimInfo, 'signedClaim': signedClaim};
}

class ReclaimProofRequest {
  // Private properties
  final String _applicationId;
  final String _providerId;
  final ProofRequestOptions? _options;
  late String _timeStamp;
  final Map<String, Timer> _intervals = {};

  late String _sessionId;
  late Context _context;

  String? _signature;
  String? _appCallbackUrl;
  String? _redirectUrl;
  RequestedProof? _requestedProof;
  String? _sdkVersion;
  int? _lastFailureTime;
  final int _failureTimeout = 30000; // 30 seconds timeout, can be adjusted

  // Constructor
  ReclaimProofRequest._(this._applicationId, this._providerId, this._options) {
    _context = Context(contextAddress: '0x0', contextMessage: '');
    if (_options?.log == true) {
      ReclaimLogger.setLogLevel(LogLevel.info);
    } else {
      ReclaimLogger.setLogLevel(LogLevel.silent);
    }
    _timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    _sdkVersion = reclaimSdkVersion;
    logger.info('Initializing client with applicationId: $_applicationId');
  }

  // Static initializers
  static Future<ReclaimProofRequest> init(
    String applicationId,
    String appSecret,
    String providerId, [
    ProofRequestOptions? options,
  ]) async {
    try {
      validateFunctionParams([
        ParamValidation(
            paramName: 'applicationId', input: applicationId, isString: true),
        ParamValidation(
            paramName: 'providerId', input: providerId, isString: true),
        ParamValidation(
            paramName: 'appSecret', input: appSecret, isString: true),
      ], 'the constructor');

      if (options != null) {
        if (options.acceptAiProviders != null) {
          validateFunctionParams([
            ParamValidation(
                paramName: 'acceptAiProviders',
                input: options.acceptAiProviders),
          ], 'the constructor');
        }
        if (options.useAppClip != null) {
          validateFunctionParams([
            ParamValidation(paramName: 'useAppClip', input: options.useAppClip),
          ], 'the constructor');
        }
        if (options.log != null) {
          validateFunctionParams([
            ParamValidation(paramName: 'log', input: options.log),
          ], 'the constructor');
        }
      }

      final proofRequestInstance =
          ReclaimProofRequest._(applicationId, providerId, options);

      final signature =
          await proofRequestInstance._generateSignature(appSecret);
      proofRequestInstance._setSignature(signature);

      final data = await initSession(providerId, applicationId,
          proofRequestInstance._timeStamp, signature);
      proofRequestInstance._sessionId = data.sessionId;

      await proofRequestInstance._buildProofRequest(data.provider);

      return proofRequestInstance;
    } catch (error) {
      logger.info('Error initializing ReclaimProofRequest: $error');
      throw initError('Failed to initialize ReclaimProofRequest', error);
    }
  }

  static Future<ReclaimProofRequest> fromJsonString(String jsonString) async {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);

      validateFunctionParams([
        ParamValidation(
            paramName: 'applicationId',
            input: json['applicationId'],
            isString: true),
        ParamValidation(
            paramName: 'providerId', input: json['providerId'], isString: true),
        ParamValidation(
            paramName: 'signature', input: json['signature'], isString: true),
        ParamValidation(
            paramName: 'sessionId', input: json['sessionId'], isString: true),
        ParamValidation(
            paramName: 'sdkVersion', input: json['sdkVersion'], isString: true),
        ParamValidation(
            paramName: 'timeStamp', input: json['timeStamp'], isString: true),
      ], 'fromJsonString');

      // parse the requested proof
      final requestedProof = RequestedProof.fromJson(json['requestedProof']);

      validateRequestedProof(requestedProof);

      if (json['redirectUrl'] != null) {
        validateURL(json['redirectUrl'], 'fromJsonString');
      }

      if (json['appCallbackUrl'] != null) {
        validateURL(json['appCallbackUrl'], 'fromJsonString');
      }

      if (json['context'] != null) {
        final context = Context.fromJson(json['context']);
        validateContext(context);
      }

      final proofRequestInstance = ReclaimProofRequest._(
        json['applicationId'],
        json['providerId'],
        json['options'] != null
            ? ProofRequestOptions.fromJson(json['options'])
            : null,
      );

      proofRequestInstance._sessionId = json['sessionId'];
      proofRequestInstance._context = Context.fromJson(json['context']);
      proofRequestInstance._requestedProof =
          RequestedProof.fromJson(json['requestedProof']);
      proofRequestInstance._appCallbackUrl = json['appCallbackUrl'];
      proofRequestInstance._sdkVersion = json['sdkVersion'];
      proofRequestInstance._redirectUrl = json['redirectUrl'];
      proofRequestInstance._signature = json['signature'];
      proofRequestInstance._timeStamp = json['timeStamp'];

      return proofRequestInstance;
    } catch (error) {
      logger.info('Failed to parse JSON string in fromJsonString: $error');
      throw invalidParamError('Invalid JSON string provided to fromJsonString');
    }
  }

  // Getters
  String getAppCallbackUrl() {
    try {
      validateFunctionParams([
        ParamValidation(
            input: _sessionId, paramName: 'sessionId', isString: true)
      ], 'getAppCallbackUrl');
      return _appCallbackUrl ??
          '${Constants.DEFAULT_RECLAIM_CALLBACK_URL}$_sessionId';
    } catch (error) {
      logger.info("Error getting app callback url", error);
      throw getAppCallbackUrlError("Error getting app callback url", error);
    }
  }

  String getStatusUrl() {
    try {
      validateFunctionParams([
        ParamValidation(
            input: _sessionId, paramName: 'sessionId', isString: true)
      ], 'getStatusUrl');
      return '${Constants.DEFAULT_RECLAIM_STATUS_URL}$_sessionId';
    } catch (error) {
      logger.info("Error fetching Status Url", error);
      throw getStatusUrlError("Error fetching status url", error);
    }
  }

  // Setters
  void setAppCallbackUrl(String url) {
    try {
      validateURL(url, 'setAppCallbackUrl');
      _appCallbackUrl = url;
    } catch (error) {
      logger.info("Error setting app callback url", error);
      throw setAppCallbackUrlError("Error setting app callback url", error);
    }
  }

  void setRedirectUrl(String url) {
    try {
      validateURL(url, 'setRedirectUrl');
      _redirectUrl = url;
    } catch (error) {
      logger.info("Error setting redirect url", error);
      throw setRedirectUrlError("Error setting redirect url", error);
    }
  }

  void addContext(String address, String message) {
    try {
      validateFunctionParams([
        ParamValidation(input: address, paramName: 'address', isString: true),
        ParamValidation(input: message, paramName: 'message', isString: true)
      ], 'addContext');
      _context = Context(contextAddress: address, contextMessage: message);
    } catch (error) {
      logger.info("Error adding context", error);
      throw addContextError("Error adding context", error);
    }
  }

  void setParams(Map<String, String> params) {
    try {
      final requestedProof = _getRequestedProof();
      if (_requestedProof == null) {
        throw buildProofRequestError('Requested proof is not present.');
      }

      final currentParams = availableParams();
      if (currentParams.isEmpty) {
        throw noProviderParamsError(
            'No params present in the provider config.');
      }

      final paramsToSet = params.keys.toList();
      for (final param in paramsToSet) {
        if (!currentParams.contains(param)) {
          throw invalidParamError(
              'Cannot set parameter $param for provider $_providerId. Available parameters: $currentParams');
        }
        // check if value is String
        if (params[param] is! String) {
          throw invalidParamError(
              'Cannot set parameter $param for provider $_providerId. Value must be a string.');
        }
      }
      _requestedProof!.parameters = {...requestedProof.parameters, ...params};
    } catch (error) {
      logger.info('Error Setting Params:', error);
      throw setParamsError("Error setting params", error);
    }
  }

  // Public methods
  Future<String> getRequestUrl() async {
    logger.info('Creating Request Url');
    if (_signature == null) {
      throw signatureNotFoundError('Signature is not set.');
    }

    try {
      final requestedProof = _getRequestedProof();
      validateSignature(_providerId, _signature!, _applicationId, _timeStamp);

      final templateData = TemplateData(
        sessionId: _sessionId,
        providerId: _providerId,
        applicationId: _applicationId,
        signature: _signature!,
        timestamp: _timeStamp,
        callbackUrl: getAppCallbackUrl(),
        context: jsonEncode(_context),
        parameters: getFilledParameters(requestedProof),
        redirectUrl: _redirectUrl ?? '',
        acceptAiProviders: _options?.acceptAiProviders ?? false,
        sdkVersion: _sdkVersion ?? '',
      );

      await updateSession(_sessionId, SessionStatus.SESSION_STARTED);
      if (_options?.useAppClip == true) {
        String template = Uri.encodeComponent(jsonEncode(templateData));
        template = template.replaceAll('(', '%28').replaceAll(')', '%29');

        // check if the device is running on iOS or Android
        final isIos = Platform.isIOS;
        if (!isIos) {
          final instantAppUrl =
              'https://share.reclaimprotocol.org/verify/?template=$template';
          logger.info('Instant App Url created successfully: $instantAppUrl');
          return instantAppUrl;
        } else {
          final appClipUrl =
              'https://appclip.apple.com/id?p=org.reclaimprotocol.app.clip&template=$template';
          logger.info('App Clip Url created successfully: $appClipUrl');
          return appClipUrl;
        }
      } else {
        final link = await createLinkWithTemplateData(templateData);
        logger.info('Request Url created successfully: $link');
        return link;
      }
    } catch (error) {
      logger.info('Error creating Request Url: $error');
      rethrow;
    }
  }

  Future<void> startSession({
    required Function(dynamic) onSuccess,
    required Function(Exception) onError,
  }) async {
    if (_sessionId.isEmpty) {
      const message =
          "Session can't be started due to undefined value of sessionId";
      logger.info(message);
      throw sessionNotStartedError(message);
    }

    logger.info('Starting session');
    final timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final statusResponse = await fetchStatusUrl(_sessionId);

        if (statusResponse.session == null) return;

        // Check for failure status and handle timeout
        if (statusResponse.session!.statusV2 ==
            SessionStatus.PROOF_GENERATION_FAILED.name) {
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          if (_lastFailureTime == null) {
            _lastFailureTime = currentTime;
          } else if (currentTime - _lastFailureTime! >= _failureTimeout) {
            clearInterval(_intervals, _sessionId);
            onError(providerFailedError(
                'Proof generation failed - timeout reached'));
            return;
          }
          return; // Continue monitoring if under timeout
        }

        // Reset failure time if status is not PROOF_GENERATION_FAILED
        _lastFailureTime = null;

        // check if the callback url is default or not
        final isDefaultCallbackUrl = getAppCallbackUrl() ==
            '${Constants.DEFAULT_RECLAIM_CALLBACK_URL}$_sessionId';

        if (isDefaultCallbackUrl) {
          if (statusResponse.session!.proofs != null &&
              statusResponse.session!.proofs!.isNotEmpty) {
            final proofs = statusResponse.session!.proofs;
            final verified = await verifyProof(proofs);
            if (!verified) {
              logger.info('Proof not verified: $proofs');
              throw proofNotVerifiedError('Unable to verify proof');
            }
            if (proofs?.length == 1) {
              onSuccess(proofs![0]);
            } else {
              onSuccess(proofs);
            }
            clearInterval(_intervals, _sessionId);
          }
        } else {
          if (statusResponse.session!.statusV2 ==
              SessionStatus.PROOF_SUBMISSION_FAILED.name) {
            throw proofSubmissionFailedError('Proof submission failed');
          }
          if (statusResponse.session!.statusV2 ==
              SessionStatus.PROOF_SUBMITTED.name) {
            onSuccess(
                'Proof submitted successfully to the custom callback url');
            clearInterval(_intervals, _sessionId);
          }
        }
      } catch (e) {
        logger.info('Error in startSession: $e');
        onError(e is Exception ? e : Exception(e.toString()));
        clearInterval(_intervals, _sessionId);
      }
    });

    _intervals[_sessionId] = timer;
    scheduleIntervalEndingTask(_intervals, _sessionId, onError);
  }

  List<String> availableParams() {
    try {
      final requestedProofs = _getRequestedProof();
      final availableParamsStore =
          Set<String>.from(requestedProofs.parameters.keys);
      availableParamsStore.addAll(RegExp(r'{{(.*?)}}')
          .allMatches(requestedProofs.url)
          .map((m) => m.group(1)!)
          .toList());

      return availableParamsStore.toList();
    } catch (error) {
      logger.info("Error fetching available params", error);
      throw availableParamsError("Error fetching available params", error);
    }
  }

  String toJsonString() {
    return jsonEncode({
      'applicationId': _applicationId,
      'providerId': _providerId,
      'sessionId': _sessionId,
      'context': _context.toJson(),
      'requestedProof': _requestedProof?.toJson(),
      'appCallbackUrl': _appCallbackUrl,
      'signature': _signature,
      'redirectUrl': _redirectUrl,
      'timeStamp': _timeStamp,
      'options': _options?.toJson(),
      'sdkVersion': _sdkVersion,
    });
  }

  // Private methods
  void _setSignature(String signature) {
    try {
      validateFunctionParams([
        ParamValidation(
            input: signature, paramName: 'signature', isString: true)
      ], 'setSignature');
      _signature = signature;
      logger.info(
          'Signature set successfully for application ID: $_applicationId');
    } catch (error) {
      logger.info("Error setting signature", error);
      throw setSignatureError("Error setting signature", error);
    }
  }

  Future<String> _generateSignature(String applicationSecret) async {
    try {
      final canonicalData =
          jsonEncode({'providerId': _providerId, 'timestamp': _timeStamp});

      final messageHash = keccak256(utf8.encode(canonicalData));

      // Prepare the Ethereum signed message
      const prefix = '\x19Ethereum Signed Message:\n32';
      final prefixedMessageHash =
          keccak256(Uint8List.fromList(utf8.encode(prefix) + messageHash));

      // Sign the prefixed message hash
      final signature = EthSigUtil.signMessage(
        privateKey: applicationSecret,
        message: prefixedMessageHash,
      );
      return signature;
    } catch (err) {
      logger.info(
          'Error generating proof request for applicationId: $_applicationId, providerId: $_providerId, signature: $_signature, timeStamp: $_timeStamp',
          err);
      throw signatureGeneratingError(
          'Error generating signature for applicationSecret: $applicationSecret');
    }
  }

  Future<RequestedProof> _buildProofRequest(ProviderData provider) async {
    try {
      _requestedProof = generateRequestedProof(provider);
      return _requestedProof!;
    } catch (err) {
      logger.info(err.toString());
      throw buildProofRequestError(
          'Something went wrong while generating proof request', err);
    }
  }

  RequestedProof _getRequestedProof() {
    try {
      if (_requestedProof == null) {
        throw buildProofRequestError(
            'RequestedProof is not present in the instance.');
      }
      return _requestedProof!;
    } catch (error) {
      logger.info("Error fetching requested proof", error);
      throw getRequestedProofError("Error fetching requested proof", error);
    }
  }
}
