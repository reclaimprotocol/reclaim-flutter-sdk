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
