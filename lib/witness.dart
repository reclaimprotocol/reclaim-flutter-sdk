import 'dart:convert'; // For utf8 encoding
import 'dart:typed_data'; // For Uint8List
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:reclaim_sdk/contract.dart';
import 'package:reclaim_sdk/errors.dart';
import 'package:reclaim_sdk/types.dart';
import 'package:web3dart/crypto.dart';

class ClaimInfo {
  String context;
  String provider;
  String parameters;

  ClaimInfo(
      {this.context = '', required this.provider, required this.parameters});

  Map<String, dynamic> toJson() => {
        'context': context,
        'provider': provider,
        'parameters': parameters,
      };

  factory ClaimInfo.fromJson(Map<String, dynamic> json) => ClaimInfo(
        context: json['context'] ?? '',
        provider: json['provider'],
        parameters: json['parameters'],
      );
}

class AnyClaimInfo {
  ClaimInfo? claimInfo;
  String? identifier;

  AnyClaimInfo.fromClaimInfo(this.claimInfo);
  AnyClaimInfo.fromIdentifier(this.identifier);

  Map<String, dynamic> toJson() {
    if (claimInfo != null) {
      return claimInfo!.toJson();
    } else {
      return {'identifier': identifier};
    }
  }

  static AnyClaimInfo fromJson(Map<String, dynamic> json) {
    if (json.containsKey('identifier')) {
      return AnyClaimInfo.fromIdentifier(json['identifier']);
    } else {
      return AnyClaimInfo.fromClaimInfo(ClaimInfo.fromJson(json));
    }
  }
}

class CompleteClaimData {
  String owner;
  int timestampS;
  int epoch;
  AnyClaimInfo anyClaimInfo;

  CompleteClaimData({
    required this.owner,
    required this.timestampS,
    required this.epoch,
    required this.anyClaimInfo,
  });

  Map<String, dynamic> toJson() => {
        'owner': owner,
        'timestampS': timestampS,
        'epoch': epoch,
        ...anyClaimInfo.toJson(),
      };

  factory CompleteClaimData.fromJson(Map<String, dynamic> json) {
    return CompleteClaimData(
      owner: json['owner'],
      timestampS: json['timestampS'],
      epoch: json['epoch'],
      anyClaimInfo: AnyClaimInfo.fromJson(json),
    );
  }
}

class SignedClaim {
  CompleteClaimData claim;
  List<Uint8List> signatures;

  SignedClaim({required this.claim, required this.signatures});

  Map<String, dynamic> toJson() => {
        'claim': claim.toJson(),
        'signatures': signatures.map(base64Encode).toList(),
      };

  factory SignedClaim.fromJson(Map<String, dynamic> json) {
    return SignedClaim(
      claim: CompleteClaimData.fromJson(json['claim']),
      signatures:
          (json['signatures'] as List).map((e) => base64Decode(e)).toList(),
    );
  }
}

abstract class Beacon {
  Future<BeaconState> getState({int? epoch});

  Future<void> close();
}

class BeaconState {
  List<WitnessData> witnesses;
  int epoch;
  int witnessesRequiredForClaim;
  int nextEpochTimestampS;

  BeaconState({
    required this.witnesses,
    required this.epoch,
    required this.witnessesRequiredForClaim,
    required this.nextEpochTimestampS,
  });
}

String getIdentifierFromClaimInfo(ClaimInfo info) {
  String str = '${info.provider}\n${info.parameters}\n${info.context}';
  Uint8List bytes = Uint8List.fromList(utf8.encode(str));

  var hash = keccak256(bytes);

  // Convert hash to lowercase hexadecimal string
  return '0x${bytesToHex(hash).toLowerCase()}';
}

List<WitnessData> fetchWitnessListForClaim(
  BeaconState beaconState,
  String identifier,
  int timestampS,
) {
  final completeInput = [
    identifier,
    beaconState.epoch.toString(),
    beaconState.witnessesRequiredForClaim.toString(),
    timestampS.toString(),
  ].join('\n');

  final Uint8List completeInputBytes =
      Uint8List.fromList(utf8.encode(completeInput));
  final Uint8List completeHash = keccak256(completeInputBytes);
  final ByteData completeHashView = completeHash.buffer.asByteData();

  List<WitnessData> witnessesLeft = List.from(beaconState.witnesses);
  List<WitnessData> selectedWitnesses = [];
  int byteOffset = 0;

  for (int i = 0; i < beaconState.witnessesRequiredForClaim; i++) {
    final randomSeed = completeHashView.getUint32(byteOffset, Endian.big);
    final witnessIndex = randomSeed % witnessesLeft.length;
    final WitnessData witness = witnessesLeft[witnessIndex];
    selectedWitnesses.add(witness);

    // Remove the selected witness from the list of witnesses left
    witnessesLeft.removeAt(witnessIndex);
    byteOffset = (byteOffset + 4) % completeHash.length;
  }

  return selectedWitnesses;
}

Future<List<String>> getWitnessesForClaim(
    int epoch, String identifier, int timestampS) async {
  final BeaconState state = await makeBeacon();
  final List<WitnessData> witnessList =
      fetchWitnessListForClaim(state, identifier, timestampS);
  return witnessList.map((witness) => witness.id.toLowerCase()).toList();
}

String createSignDataForClaim(CompleteClaimData data) {
  final lines = [
    data.anyClaimInfo.identifier,
    data.owner.toLowerCase(),
    data.timestampS.toString(),
    data.epoch.toString(),
  ];

  return lines.join('\n');
}

List<String> recoverSignersOfSignedClaim(SignedClaim signedClaim) {
  final dataStr = createSignDataForClaim(signedClaim.claim);
  final credentials = signedClaim.signatures.map((signature) {
    final message = utf8.encode(dataStr);
    final address = EthSigUtil.recoverPersonalSignature(
      signature: utf8.decode(signature),
      message: message,
    );
    return address.toLowerCase();
  }).toList();

  return credentials;
}

void assertValidSignedClaim(
    SignedClaim claim, List<String> expectedWitnessAddresses) {
  List<String> witnessAddresses = recoverSignersOfSignedClaim(claim);
  // Set of witnesses whose signatures we've not seen
  final Set<String> witnessesNotSeen = Set.from(expectedWitnessAddresses);

  for (final witness in witnessAddresses) {
    if (witnessesNotSeen.contains(witness)) {
      witnessesNotSeen.remove(witness);
    }
  }

  // Check if all witnesses have signed
  if (witnessesNotSeen.isNotEmpty) {
    throw ProofNotVerifiedError(
        'Missing signatures from ${witnessesNotSeen.join(', ')}');
  }
}
