import 'dart:convert';

class CreateVerificationRequest {
  final List<String> providerIds;
  final String? applicationSecret;

  CreateVerificationRequest({
    required this.providerIds,
    this.applicationSecret,
  });
}

class StartSessionParams {
  final OnSuccessCallback onSuccessCallback;
  final OnFailureCallback onFailureCallback;

  StartSessionParams({
    required this.onSuccessCallback,
    required this.onFailureCallback,
  });
}

typedef OnSuccessCallback = void Function(Proof proofs);
typedef OnFailureCallback = void Function(Error error);

enum SessionStatus {
  SESSION_INIT,
  SESSION_STARTED,
  USER_INIT_VERIFICATION,
  USER_STARTED_VERIFICATION,
  PROOF_GENERATION_STARTED,
  PROOF_GENERATION_SUCCESS,
  PROOF_GENERATION_FAILED,
  PROOF_SUBMITTED,
  PROOF_MANUAL_VERIFICATION_SUBMITED,
}

class ProofRequestOptions {
  final bool? log;
  final String? sessionId;

  ProofRequestOptions({
    this.log,
    this.sessionId,
  });
}

class ParsedURL {
  final String? scheme;
  final String? hostname;
  final String? path;
  final Map<String, dynamic>? queryParams;

  ParsedURL({
    required this.scheme,
    required this.hostname,
    required this.path,
    required this.queryParams,
  });
}

class ProviderV2 {
  final String id;
  final String httpProviderId;
  final String name;
  final String logoUrl;
  final String url;
  final String? method;
  final String loginUrl;
  final List<ResponseSelection> responseSelections;
  final String? customInjection;
  final String urlType;
  final String proofCardTitle;
  final String proofCardText;
  final BodySniff? bodySniff;
  final Map<String, String?>? userAgent;
  final String? geoLocation;
  final String? matchType;
  final String injectionType;
  final String verificationType;
  final bool disableRequestReplay;
  final Map<String, String?>? parameters;

  ProviderV2(
      {required this.id,
      required this.httpProviderId,
      required this.name,
      required this.logoUrl,
      required this.url,
      this.method,
      required this.loginUrl,
      required this.responseSelections,
      this.customInjection,
      required this.urlType,
      required this.proofCardTitle,
      required this.proofCardText,
      this.bodySniff,
      this.userAgent,
      this.geoLocation,
      this.matchType,
      required this.verificationType,
      required this.injectionType,
      required this.disableRequestReplay,
      this.parameters});

  factory ProviderV2.fromJson(Map<String, dynamic> map) {
    return ProviderV2(
      id: map['id'],
      httpProviderId: map['httpProviderId'],
      name: map['name'],
      logoUrl: map['logoUrl'],
      url: map['url'],
      method: map['method'],
      loginUrl: map['loginUrl'],
      responseSelections: List<ResponseSelection>.from(
          map['responseSelections'].map((x) => ResponseSelection.fromJson(x))),
      customInjection: map['customInjection'],
      urlType: map['urlType'],
      proofCardTitle: map['proofCardTitle'],
      proofCardText: map['proofCardText'],
      bodySniff: map['bodySniff'] != null
          ? BodySniff.fromJson(map['bodySniff'])
          : null,
      userAgent: map['userAgent'] != null
          ? Map<String, String?>.from(map['userAgent'])
          : null,
      geoLocation: map['geoLocation'],
      matchType: map['matchType'],
      injectionType: map['injectionType'],
      verificationType: map['verificationType'],
      disableRequestReplay: map['disableRequestReplay'],
      parameters: map['parameters'] != null
          ? Map<String, String?>.from(map['parameters'])
          : null,
    );
  }
}

class ResponseSelection {
  final String jsonPath;
  final String xPath;
  final String responseMatch;
  final String matchType;
  final bool invert;

  ResponseSelection({
    required this.jsonPath,
    required this.xPath,
    required this.responseMatch,
    required this.invert,
    required this.matchType,
  });

  Map<String, dynamic> toJson() {
    return {
      'jsonPath': jsonPath,
      'xPath': xPath,
      'responseMatch': responseMatch,
      'invert': invert,
      'matchType': matchType,
    };
  }

  factory ResponseSelection.fromJson(Map<String, dynamic> json) {
    return ResponseSelection(
      jsonPath: json['jsonPath'],
      xPath: json['xPath'],
      responseMatch: json['responseMatch'],
      invert: json['invert'],
      matchType: json['matchType'],
    );
  }
}

class BodySniff {
  final bool enabled;
  final String? regex;

  BodySniff({
    required this.enabled,
    this.regex,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'regex': regex,
    };
  }

  factory BodySniff.fromJson(Map<String, dynamic> json) {
    return BodySniff(
      enabled: json['enabled'],
      regex: json['regex'],
    );
  }
}

class Proof {
  String identifier;
  final ProviderClaimData claimData;
  final List<String> signatures;
  final List<WitnessData> witnesses;
  Proof({
    required this.identifier,
    required this.claimData,
    required this.signatures,
    required this.witnesses,
  });

  factory Proof.fromJson(Map<String, String> json) {
    return Proof(
        identifier: json['identifier']!,
        claimData: ProviderClaimData.fromJson(jsonDecode(json['claimData']!)),
        signatures: List<String>.from(jsonDecode(json['signatures']!)),
        witnesses: (jsonDecode(json['witnesses']!) as List<dynamic>)
            .map((witness) => WitnessData.fromJson(witness))
            .toList());
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'claimData': jsonEncode(claimData.toJson()),
      'signatures': jsonEncode(signatures),
      'witnesses':
          jsonEncode(witnesses.map((witness) => witness.toJson()).toList())
    };
  }
}

class WitnessData {
  final String id;
  final String url;

  WitnessData({
    required this.id,
    required this.url,
  });

  factory WitnessData.fromJson(Map<String, dynamic> json) {
    return WitnessData(
      id: json['id'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
    };
  }
}

class ProviderClaimData {
  final String provider;
  final String parameters;
  final String owner;
  final int timestampS;
  final String context;
  final String identifier;
  final int epoch;

  ProviderClaimData({
    required this.provider,
    required this.parameters,
    required this.owner,
    required this.timestampS,
    required this.context,
    required this.identifier,
    required this.epoch,
  });

  factory ProviderClaimData.fromJson(Map<String, dynamic> json) {
    return ProviderClaimData(
      provider: json['provider'],
      parameters: json['parameters'],
      owner: json['owner'],
      timestampS: json['timestampS'],
      context: json['context'],
      identifier: json['identifier'],
      epoch: json['epoch'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'parameters': parameters,
      'owner': owner,
      'timestampS': timestampS,
      'context': context,
      'identifier': identifier,
      'epoch': epoch,
    };
  }
}

class RequestedProofs {
  final String id;
  final String sessionId;
  final String name;
  final String callbackUrl;
  final List<RequestedClaim> claims;

  RequestedProofs({
    required this.id,
    required this.sessionId,
    required this.name,
    required this.callbackUrl,
    required this.claims,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'name': name,
      'callbackUrl': callbackUrl,
      'claims': claims.map((claim) => claim.toJson()).toList(),
    };
  }
}

class RequestedClaim {
  final String provider;
  final String context;
  final String httpProviderId;
  final Payload payload;

  RequestedClaim({
    required this.provider,
    required this.context,
    required this.httpProviderId,
    required this.payload,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'context': context,
      'httpProviderId': httpProviderId,
      'payload': payload.toJson(),
    };
  }
}

class Payload {
  final Metadata metadata;
  final String url;
  final String urlType;
  final String method;
  final Login login;
  final List<ResponseSelection> responseSelections;
  final Map<String, String>? headers;
  final String? customInjection;
  final BodySniff? bodySniff;
  final Map<String, String>? userAgent;
  final String? geoLocation;
  final String? matchType;
  final String verificationType;
  final String injectionType;
  final bool disableRequestReplay;
  late final Map<String, dynamic>? parameters;

  Payload(
      {required this.metadata,
      required this.url,
      required this.urlType,
      required this.method,
      required this.login,
      required this.responseSelections,
      required this.verificationType,
      this.headers,
      this.customInjection,
      this.bodySniff,
      this.userAgent,
      this.geoLocation,
      this.matchType,
      required this.injectionType,
      required this.disableRequestReplay,
      this.parameters});
  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'url': url,
      'urlType': urlType,
      'method': method,
      'login': login.toJson(),
      'responseSelections':
          responseSelections.map((rs) => rs.toJson()).toList(),
      'headers': headers,
      'customInjection': customInjection,
      'bodySniff': bodySniff?.toJson(),
      'userAgent': userAgent,
      'geoLocation': geoLocation,
      'verificationType': verificationType,
      'matchType': matchType,
      'injectionType': injectionType,
      'disableRequestReplay': disableRequestReplay,
      'parameters': {}
    };
  }
}

class Metadata {
  final String name;
  final String logoUrl;
  final String proofCardTitle;
  final String proofCardText;

  Metadata({
    required this.name,
    required this.logoUrl,
    required this.proofCardTitle,
    required this.proofCardText,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'proofCardTitle': proofCardTitle,
      'proofCardText': proofCardText,
    };
  }
}

class Login {
  final String url;

  Login({
    required this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }
}

class Context {
  final String contextAddress;
  final String contextMessage;

  Context({
    required this.contextAddress,
    required this.contextMessage,
  });

  Map<String, dynamic> toJson() {
    return {'contextAddress': contextAddress, 'contextMessage': contextMessage};
  }
}

typedef QueryParams = Map<String, dynamic>;
typedef Signature = String;
typedef AppCallbackUrl = String;
typedef RedirectUrl = String;
typedef SessionId = String;
typedef NoReturn = void;
typedef ApplicationId = String;
