import 'dart:convert'; // For utf8 encoding
import 'dart:typed_data'; // For Uint8List
import 'package:web3dart/crypto.dart';
import 'package:eth_sig_util/eth_sig_util.dart';

import 'utils/interfaces.dart';
import 'utils/logger.dart';
import 'utils/types.dart';

var logger = ReclaimLogger();

ClaimID getIdentifierFromClaimInfo(ClaimInfo info) {
  String str = '${info.provider}\n${info.parameters}\n${info.context}';
  Uint8List bytes = Uint8List.fromList(utf8.encode(str));

  var hash = keccak256(bytes);

  // Convert hash to lowercase hexadecimal string
  return '0x${bytesToHex(hash).toLowerCase()}';
}

List<WitnessData> fetchWitnessListForClaim(
  BeaconState beaconState,
  dynamic params,
  int timestampS,
) {
  final String identifier = params is String
      ? params
      : getIdentifierFromClaimInfo(params as ClaimInfo);
  final completeInput = [
    identifier,
    beaconState.epoch.toString(),
    beaconState.witnessesRequiredForClaim.toString(),
    timestampS.toString(),
  ].join('\n');

  final completeHash =
      keccak256(Uint8List.fromList(utf8.encode(completeInput)));
  final completeHashView = ByteData.view(completeHash.buffer);
  final witnessesLeft = List<WitnessData>.from(beaconState.witnesses);
  final selectedWitnesses = <WitnessData>[];
  var byteOffset = 0;

  for (var i = 0; i < beaconState.witnessesRequiredForClaim; i++) {
    final randomSeed = completeHashView.getUint32(byteOffset, Endian.big);
    final witnessIndex = randomSeed % witnessesLeft.length;
    final witness = witnessesLeft[witnessIndex];
    selectedWitnesses.add(witness);

    witnessesLeft[witnessIndex] = witnessesLeft.last;
    witnessesLeft.removeLast();
    byteOffset = (byteOffset + 4) % completeHash.length;
  }

  return selectedWitnesses;
}

Uint8List strToUint8Array(String str) {
  return Uint8List.fromList(utf8.encode(str));
}

ByteData uint8ArrayToDataView(Uint8List arr) {
  return ByteData.view(arr.buffer, arr.offsetInBytes, arr.lengthInBytes);
}

String createSignDataForClaim(ProviderClaimData data) {
  final identifier = data.identifier;
  final lines = [
    identifier,
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
      signature: bytesToHex(signature, include0x: true),
      message: message,
    );
    return address.toLowerCase();
  }).toList();

  return credentials;
}
