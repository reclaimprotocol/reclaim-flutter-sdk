import 'interfaces.dart';

typedef ClaimID = String;

class ClaimInfo {
  final String context;
  final String provider;
  final String parameters;

  ClaimInfo(
      {required this.context,
      required this.provider,
      required this.parameters});

  factory ClaimInfo.fromJson(Map<String, dynamic> json) => ClaimInfo(
        context: json['context'] ?? '',
        provider: json['provider'],
        parameters: json['parameters'],
      );

  Map<String, dynamic> toJson() => {
        'context': context,
        'provider': provider,
        'parameters': parameters,
      };
}

class AnyClaimInfo {
  final ClaimInfo? claimInfo;
  final ClaimID? identifier;

  AnyClaimInfo.fromClaimInfo(this.claimInfo) : identifier = null;
  AnyClaimInfo.fromIdentifier(this.identifier) : claimInfo = null;

  factory AnyClaimInfo.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('identifier')) {
      return AnyClaimInfo.fromIdentifier(json['identifier']);
    } else {
      return AnyClaimInfo.fromClaimInfo(ClaimInfo.fromJson(json));
    }
  }

  Map<String, dynamic> toJson() {
    if (claimInfo != null) {
      return claimInfo!.toJson();
    } else {
      return {'identifier': identifier};
    }
  }
}

class CompleteClaimData {
  final String owner;
  final int timestampS;
  final int epoch;
  final AnyClaimInfo anyClaimInfo;

  CompleteClaimData({
    required this.owner,
    required this.timestampS,
    required this.epoch,
    required this.anyClaimInfo,
  });

  factory CompleteClaimData.fromJson(Map<String, dynamic> json) =>
      CompleteClaimData(
        owner: json['owner'],
        timestampS: json['timestampS'],
        epoch: json['epoch'],
        anyClaimInfo: AnyClaimInfo.fromJson(json),
      );

  Map<String, dynamic> toJson() => {
        'owner': owner,
        'timestampS': timestampS,
        'epoch': epoch,
        ...anyClaimInfo.toJson(),
      };
}

class SignedClaim {
  final ProviderClaimData claim;
  final List<List<int>> signatures;

  SignedClaim({required this.claim, required this.signatures});

  factory SignedClaim.fromJson(Map<String, dynamic> json) => SignedClaim(
        claim: ProviderClaimData.fromJson(json['claim']),
        signatures:
            (json['signatures'] as List).map((e) => List<int>.from(e)).toList(),
      );

  Map<String, dynamic> toJson() => {
        'claim': claim.toJson(),
        'signatures': signatures,
      };
}

typedef QueryParams = Map<String, dynamic>;

class CreateVerificationRequest {
  final List<String> providerIds;
  final String? applicationSecret;

  CreateVerificationRequest(
      {required this.providerIds, this.applicationSecret});
}

typedef OnSuccess = void Function(dynamic proof);
typedef OnError = void Function(Exception error);

class StartSessionParams {
  final OnSuccess onSuccess;
  final OnError onError;

  StartSessionParams({required this.onSuccess, required this.onError});
}

class ProofRequestOptions {
  final bool? log;
  final bool? acceptAiProviders;
  final bool? useAppClip;

  ProofRequestOptions({this.log, this.acceptAiProviders, this.useAppClip});

  factory ProofRequestOptions.fromJson(Map<String, dynamic> json) =>
      ProofRequestOptions(
        log: json['log'],
        acceptAiProviders: json['acceptAiProviders'],
        useAppClip: json['useAppClip'],
      );

  Map<String, dynamic> toJson() => {
        'log': log,
        'acceptAiProviders': acceptAiProviders,
        'useAppClip': useAppClip,
      };
}

class InitSessionResponse {
  final String sessionId;
  final ProviderData provider;

  InitSessionResponse({required this.sessionId, required this.provider});
}

class UpdateSessionResponse {
  final String? message;

  UpdateSessionResponse({this.message});
}

class StatusUrlResponse {
  final String message;
  final Session? session;
  final String? providerId;

  StatusUrlResponse({
    required this.message,
    this.session,
    this.providerId,
  });

  factory StatusUrlResponse.fromJson(Map<String, dynamic> json) =>
      StatusUrlResponse(
        message: json['message'],
        session:
            json['session'] != null ? Session.fromJson(json['session']) : null,
        providerId: json['providerId'],
      );
}

enum SessionStatus {
  SESSION_INIT,
  SESSION_STARTED,
  USER_INIT_VERIFICATION,
  USER_STARTED_VERIFICATION,
  PROOF_GENERATION_STARTED,
  PROOF_GENERATION_SUCCESS,
  PROOF_GENERATION_FAILED,
  PROOF_SUBMITTED,
  PROOF_SUBMISSION_FAILED,
  PROOF_MANUAL_VERIFICATION_SUBMITED;
}

class TemplateData {
  final String sessionId;
  final String providerId;
  final String applicationId;
  final String signature;
  final String timestamp;
  final String callbackUrl;
  final String context;
  final Map<String, String> parameters;
  final String redirectUrl;
  final bool acceptAiProviders;
  final String sdkVersion;

  TemplateData({
    required this.sessionId,
    required this.providerId,
    required this.applicationId,
    required this.signature,
    required this.timestamp,
    required this.callbackUrl,
    required this.context,
    required this.parameters,
    required this.redirectUrl,
    required this.acceptAiProviders,
    required this.sdkVersion,
  });

  factory TemplateData.fromJson(Map<String, dynamic> json) => TemplateData(
        sessionId: json['sessionId'],
        providerId: json['providerId'],
        applicationId: json['applicationId'],
        signature: json['signature'],
        timestamp: json['timestamp'],
        callbackUrl: json['callbackUrl'],
        context: json['context'],
        parameters: json['parameters'],
        redirectUrl: json['redirectUrl'],
        acceptAiProviders: json['acceptAiProviders'],
        sdkVersion: json['sdkVersion'],
      );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'providerId': providerId,
        'applicationId': applicationId,
        'signature': signature,
        'timestamp': timestamp,
        'callbackUrl': callbackUrl,
        'context': context,
        'parameters': parameters,
        'redirectUrl': redirectUrl,
        'acceptAiProviders': acceptAiProviders,
        'sdkVersion': sdkVersion,
      };
}

class Session {
  final String id;
  final String appId;
  final List<String> httpProviderId;
  final String sessionId;
  final List<Proof>? proofs;
  final String statusV2;

  Session({
    required this.id,
    required this.appId,
    required this.httpProviderId,
    required this.sessionId,
    this.proofs,
    required this.statusV2,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'],
        appId: json['appId'],
        httpProviderId: List<String>.from(json['httpProviderId']),
        sessionId: json['sessionId'],
        proofs: json['proofs'] != null
            ? (json['proofs'] as List).map((p) => Proof.fromJson(p)).toList()
            : null,
        statusV2: json['statusV2'],
      );
}
