// Provider-related classes

class ProviderData {
  final String httpProviderId;
  final String name;
  final String url;
  final String loginUrl;
  final List<ResponseSelection> responseSelections;
  final BodySniff? bodySniff;

  ProviderData({
    required this.httpProviderId,
    required this.name,
    required this.url,
    required this.loginUrl,
    required this.responseSelections,
    this.bodySniff,
  });

  factory ProviderData.fromJson(Map<String, dynamic> json) {
    return ProviderData(
      httpProviderId: json['httpProviderId'],
      name: json['name'],
      url: json['url'],
      loginUrl: json['loginUrl'],
      responseSelections: (json['responseSelections'] as List)
          .map((e) => ResponseSelection.fromJson(e))
          .toList(),
      bodySniff: json['bodySniff'] != null
          ? BodySniff.fromJson(json['bodySniff'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'httpProviderId': httpProviderId,
      'name': name,
      'url': url,
      'loginUrl': loginUrl,
      'responseSelections': responseSelections.map((e) => e.toJson()).toList(),
      'bodySniff': bodySniff?.toJson(),
    };
  }
}

class ResponseSelection {
  final bool invert;
  final String responseMatch;
  final String? xPath;
  final String? jsonPath;

  ResponseSelection({
    required this.invert,
    required this.responseMatch,
    this.xPath,
    this.jsonPath,
  });

  factory ResponseSelection.fromJson(Map<String, dynamic> json) {
    return ResponseSelection(
      invert: json['invert'],
      responseMatch: json['responseMatch'],
      xPath: json['xPath'],
      jsonPath: json['jsonPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invert': invert,
      'responseMatch': responseMatch,
      'xPath': xPath,
      'jsonPath': jsonPath,
    };
  }
}

class BodySniff {
  final bool enabled;
  final String? regex;
  final String? template;

  BodySniff({
    required this.enabled,
    this.regex,
    this.template,
  });

  factory BodySniff.fromJson(Map<String, dynamic> json) {
    return BodySniff(
      enabled: json['enabled'],
      regex: json['regex'],
      template: json['template'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'regex': regex,
      'template': template,
    };
  }
}

// Proof-related classes
class Proof {
  String identifier;
  final ProviderClaimData claimData;
  final List<String> signatures;
  final List<WitnessData> witnesses;
  final Map<String, String>? publicData;

  Proof({
    required this.identifier,
    required this.claimData,
    required this.signatures,
    required this.witnesses,
    this.publicData,
  });

  factory Proof.fromJson(Map<String, dynamic> json) {
    return Proof(
      identifier: json['identifier'],
      claimData: ProviderClaimData.fromJson(json['claimData']),
      signatures: List<String>.from(json['signatures']),
      witnesses: (json['witnesses'] as List)
          .map((e) => WitnessData.fromJson(e))
          .toList(),
      publicData: json['publicData'] != null
          ? Map<String, String>.from(json['publicData'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'claimData': claimData.toJson(),
      'signatures': signatures,
      'witnesses': witnesses.map((e) => e.toJson()).toList(),
      'publicData': publicData,
    };
  }
}

class WitnessData {
  final String id;
  final String url;

  WitnessData({required this.id, required this.url});

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

// Request-related classes
class RequestedProof {
  final String url;
  late final Map<String, String> parameters;

  RequestedProof({required this.url, required this.parameters});

  factory RequestedProof.fromJson(Map<String, dynamic> json) {
    return RequestedProof(
      url: json['url'],
      parameters: Map<String, String>.from(json['parameters']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'parameters': parameters,
    };
  }
}

// Context class
class Context {
  final String contextAddress;
  final String contextMessage;

  Context({required this.contextAddress, required this.contextMessage});

  factory Context.fromJson(Map<String, dynamic> json) {
    return Context(
      contextAddress: json['contextAddress'],
      contextMessage: json['contextMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contextAddress': contextAddress,
      'contextMessage': contextMessage,
    };
  }
}

// Beacon-related classes
abstract class Beacon {
  Future<BeaconState> getState({int? epoch});
  Future<void> close();
}

class BeaconState {
  final List<WitnessData> witnesses;
  final int epoch;
  final int witnessesRequiredForClaim;
  final int nextEpochTimestampS;

  BeaconState({
    required this.witnesses,
    required this.epoch,
    required this.witnessesRequiredForClaim,
    required this.nextEpochTimestampS,
  });

  factory BeaconState.fromJson(Map<String, dynamic> json) {
    return BeaconState(
      witnesses: (json['witnesses'] as List)
          .map((e) => WitnessData.fromJson(e))
          .toList(),
      epoch: json['epoch'],
      witnessesRequiredForClaim: json['witnessesRequiredForClaim'],
      nextEpochTimestampS: json['nextEpochTimestampS'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'witnesses': witnesses.map((e) => e.toJson()).toList(),
      'epoch': epoch,
      'witnessesRequiredForClaim': witnessesRequiredForClaim,
      'nextEpochTimestampS': nextEpochTimestampS,
    };
  }
}
