library reclaim_sdk;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:uuid/uuid.dart';
import 'package:uni_links/uni_links.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/crypto.dart';

import 'package:reclaim_sdk/constants.dart';
import 'package:reclaim_sdk/errors.dart';
import 'package:reclaim_sdk/types.dart';
import 'package:reclaim_sdk/utils.dart';
import 'package:reclaim_sdk/witness.dart';

import 'package:http/http.dart' as http;

var logger = Logger(
  printer: PrettyPrinter(methodCount: 10),
);

class Reclaim {
  static Future<bool> verifySignedProof(Proof proof) async {
    try {
      if (proof.signatures.isEmpty) {
        throw Exception('No signatures');
      }

      ClaimInfo claimInfo = ClaimInfo.fromJson(proof.claimData.toJson());
      // then hash the claim info with the encoded ctx to get the identifier
      final calculatedIdentifier = getIdentifierFromClaimInfo(claimInfo);

      proof.identifier = replaceAll(proof.identifier, '"', '');
      // check if the identifier matches the one in the proof
      if (calculatedIdentifier.toLowerCase() !=
          proof.identifier.toLowerCase()) {
        throw ProofNotVerifiedError('Identifier Mismatch');
      }

      List<Uint8List> signatureBytes =
          proof.signatures.map((e) => utf8.encode(e)).toList();
      CompleteClaimData completeClaimData =
          CompleteClaimData.fromJson(proof.claimData.toJson());
      SignedClaim signedClaim =
          SignedClaim(claim: completeClaimData, signatures: signatureBytes);

      List<String> witnesses = [];
      if (proof.witnesses.isNotEmpty &&
          proof.witnesses[0]?.url == 'manual-verify') {
        witnesses.add(proof.witnesses[0].id);
      } else {
        witnesses = await getWitnessesForClaim(
          proof.claimData.epoch,
          proof.identifier,
          proof.claimData.timestampS,
        );
      }

      // verify the witness signature
      assertValidSignedClaim(signedClaim, witnesses);
    } catch (e) {
      logger.e(e);
      return false;
    }

    return true;
  }

  static Map<String, dynamic> transformForOnchain(Proof proof) {
    Map<String, dynamic> claimInfo = {
      'context': proof.claimData.context,
      'parameters': proof.claimData.parameters,
      'provider': proof.claimData.provider,
    };
    Map<String, dynamic> claim = {
      'epoch': proof.claimData.epoch,
      'identifier': proof.claimData.identifier,
      'owner': proof.claimData.owner,
      'timestampS': proof.claimData.timestampS,
    };
    Map<String, dynamic> signedClaim = {
      'claim': claim,
      'signatures': proof.signatures,
    };
    return {'claimInfo': claimInfo, 'signedClaim': signedClaim};
  }

  bool verifyProvider(Proof proof, String providerHash) {
    try {
      validateNotNullOrUndefined(
          providerHash, 'providerHash', 'verifyProvider function');
      validateNotNullOrUndefined(proof, 'proof', 'verifyProvider function');
      validateNonEmptyString(
          providerHash, 'providerHash', 'verifyProvider function');
      validateNonEmptyString(
          proof.claimData.context, 'context', 'verifyProvider function');

      final jsonContext = jsonDecode(proof.claimData.context);
      if (!jsonContext.containsKey('providerHash')) {
        logger.e('ProviderHash is not included in proof\'s context');
        return false;
      }
      if (providerHash != jsonContext['providerHash']) {
        logger.e(
            'ProviderHash in context: ${jsonContext['providerHash']} does not match the stored providerHash: $providerHash');
        return false;
      }
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }
}

class ProofRequest {
  ApplicationId applicationId;
  SessionId sessionId = const Uuid().v4().toString();
  Context context = Context(contextAddress: '', contextMessage: '');
  Signature? signature;
  AppCallbackUrl? appCallbackUrl;
  RedirectUrl? redirectUrl;
  String? template;
  RequestedProofs? requestedProofs;
  String? providerId;
  String linkingVersion;
  String timeStamp;

  ProofRequest(
      {required this.applicationId, SessionId sessionId = "", bool? log})
      : timeStamp = DateTime.now().millisecondsSinceEpoch.toString(),
        linkingVersion = 'V1' {
    if (sessionId.isNotEmpty) {
      this.sessionId = sessionId;
    }
    if (log == null || !log) {
      Logger.level = Level.off;
    }
    logger.i(
        'Initializing client with applicationId: $applicationId and sessionId: ${this.sessionId}');
  }

  NoReturn addContext(String address, String message) {
    context = Context(contextAddress: address, contextMessage: message);
  }

  NoReturn setAppCallbackUrl(String url) {
    validateURL(url);
    appCallbackUrl = url;
  }

  NoReturn setRedirectUrl(String url) {
    validateURL(url);
    redirectUrl = url;
  }

  NoReturn setSignature(Signature signature) {
    this.signature = signature;
  }

  List<String> availableParams() {
    final requestedProofs = getRequestedProofs();

    if (requestedProofs.claims.isEmpty) {
      throw BuildProofRequestError(
          'Requested proofs are not built yet. Call buildProofRequest(providerId: string) first!');
    }

    List<String> availableParamsStore =
        requestedProofs.claims[0].payload.parameters!.keys.toList();

    final urlParamsMatches = RegExp(r'{{(.*?)}}')
        .allMatches(requestedProofs.claims[0].payload.url)
        .map((match) => match.group(1)!)
        .toList();
    availableParamsStore = [
      ...availableParamsStore,
      ...urlParamsMatches,
    ];

    return availableParamsStore.toSet().toList();
  }

  NoReturn setParams(Map<String, String> params) {
    try {
      getRequestedProofs();
      final availableParamList = availableParams();
      final paramsToSet = params.keys.toList();
      for (var i = 0; i < paramsToSet.length; i++) {
        if (!availableParamList.contains(paramsToSet[i])) {
          throw Exception(
              'Cannot Set parameter ${paramsToSet[i]} for provider $providerId available Prameters inculde : $availableParamList');
        }
      }
      requestedProofs!.claims[0].payload.parameters?.addAll(params);
    } catch (error) {
      logger.e('Error Setting Params: $error');
      rethrow;
    }
  }

  AppCallbackUrl getAppCallbackUrl() {
    return appCallbackUrl ??
        '${Constants.DEFAULT_RECLAIM_CALLBACK_URL}$sessionId';
  }

  RequestedProofs getRequestedProofs() {
    try {
      if (requestedProofs == null) {
        throw BuildProofRequestError(
            'Call buildProofRequest(providerId: String) first!');
      }
      return requestedProofs!;
    } catch (err) {
      rethrow;
    }
  }

  Signature generateSignature(String applicationSecret) {
    try {
      final requestedProofs = getRequestedProofs();
      if (requestedProofs.claims.isNotEmpty &&
          (linkingVersion == 'V2Linking' ||
              requestedProofs.claims[0].payload.verificationType == 'MANUAL')) {
        final messageHash = keccak256(utf8.encode(jsonEncode({
          'providerId': requestedProofs.claims[0].httpProviderId,
          'timestamp': timeStamp,
        })));
        final signature = EthSigUtil.signMessage(
            privateKey: applicationSecret, message: messageHash);
        return signature;
      }

      final messageHash =
          keccak256(utf8.encode(jsonEncode(requestedProofs.toJson())));
      String signature = EthSigUtil.signMessage(
          privateKey: applicationSecret, message: messageHash);

      return signature;
    } catch (err) {
      logger.e(err);
      throw Exception(
          'Error generating signature for applicationSecret: $applicationSecret');
    }
  }

  Future<RequestedProofs?> buildProofRequest(String providerId,
      {bool redirectUser = false, String? linkingVersion}) async {
    try {
      final providers = await fetchProvidersByAppId(applicationId, providerId);
      final provider = validateProviderIdsAndReturnProviders(
        providerId,
        providers,
      );
      this.providerId = providerId;
      requestedProofs = generateRequestedProofs(
        provider,
        context,
        getAppCallbackUrl(),
        sessionId,
        redirectUser,
      );

      // check if linking version is not null
      if (linkingVersion != null) {
        // check if linking version is not empty
        if (linkingVersion.isNotEmpty) {
          // check if linking version is V2Linking
          if (linkingVersion == 'V2Linking') {
            this.linkingVersion = linkingVersion;
          } else {
            throw BuildProofRequestError(
                'Invalid linking version. Supported linking versions are V2Linking');
          }
        }
      }

      await createSession(sessionId, applicationId, providerId);

      return requestedProofs;
    } catch (err) {
      logger.e(err);
      throw BuildProofRequestError(
          'Something went wrong while generating proof request');
    }
  }

  Future<Map<String, String>> createVerificationRequest() async {
    try {
      final requestedProofs = getRequestedProofs();

      if (signature == null) {
        throw SignatureNotFoundError(
            'Signature is not set. Use reclaim.setSignature(signature) to set the signature');
      }

      validateSignature(requestedProofs, signature!, applicationId,
          linkingVersion, timeStamp);

      Map<String, dynamic> templateData = {};
      if (requestedProofs.claims.isNotEmpty &&
          (linkingVersion == 'V2Linking' ||
              requestedProofs.claims[0].payload.verificationType == 'MANUAL')) {
        templateData = {
          'sessionId': sessionId,
          'providerId': providerId!.isNotEmpty ? providerId : '',
          'applicationId': applicationId,
          'signature': signature,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'callbackUrl': getAppCallbackUrl(),
          'context': context.toJson().toString(),
          'verificationType':
              requestedProofs.claims[0].payload.verificationType,
          'parameters': requestedProofs.claims[0].payload.parameters ?? {},
          'redirectUrl': redirectUrl ?? '',
        };
      } else {
        templateData = {...requestedProofs.toJson(), 'signature': signature};
      }

      String template = Uri.encodeComponent(jsonEncode(templateData));

      var link = '';
      if (requestedProofs.claims.isNotEmpty &&
          (linkingVersion == 'V2Linking' ||
              requestedProofs.claims[0].payload.verificationType == 'MANUAL')) {
        link = 'https://share.reclaimprotocol.org/verifier?template=$template';
        link = await getShortenedUrl(link);
      } else {
        link = await getBranchLink(template);
      }
      this.template = link;
      await updateSession(sessionId, SessionStatus.SESSION_STARTED);

      return {
        'requestUrl': link,
        'statusUrl': '${Constants.DEFAULT_RECLAIM_STATUS_URL}$sessionId',
      };
    } catch (error) {
      logger.e('Error creating verification request: $error');
      rethrow;
    }
  }

  Future<void> startSession(StartSessionParams callbacks) async {
    if (template != null) {
      final Uri url = Uri.parse(template!);
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }

      uriLinkStream.listen((Uri? link) async {
        final res = link?.queryParameters;
        if (res == null) {
          throw Exception('No query parameters found');
        }

        final proof = Proof.fromJson(res);
        await callProofCallback(sessionId, proof);
        final verified = await Reclaim.verifySignedProof(proof);
        if (!verified) {
          throw ProofNotVerifiedError();
        }
        logger.i('Proof Successfully Verified!');
        callbacks.onSuccessCallback(proof);
      }, onError: (error) async {
        logger.e(error);
        if (error is Error) {
          callbacks.onFailureCallback(error);
        }
      });
    }
  }
}
