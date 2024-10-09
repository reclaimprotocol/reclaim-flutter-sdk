// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:reclaim_sdk/smart_contract.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:web3dart/crypto.dart';

import 'interfaces.dart';
import 'types.dart';
import 'constants.dart';
import 'errors.dart';
import 'validation_utils.dart';
import '../witness.dart';
import 'logger.dart';

var logger = ReclaimLogger();

RequestedProof generateRequestedProof(ProviderData provider) {
  final Map<String, String> providerParams = {};
  for (var rs in provider.responseSelections) {
    final matches = RegExp(r'{{(.*?)}}').allMatches(rs.responseMatch);
    for (var match in matches) {
      providerParams[match.group(1)!] = '';
    }
  }

  return RequestedProof(
    url: provider.url,
    parameters: providerParams,
  );
}

Map<String, String> getFilledParameters(RequestedProof requestedProof) {
  return Map.fromEntries(requestedProof.parameters.entries
      .where((entry) => entry.value.isNotEmpty));
}

Future<String> getShortenedUrl(String url) async {
  logger.info('Attempting to shorten URL: $url');
  try {
    validateURL(url, 'getShortenedUrl');
    final response = await http.post(
      Uri.parse('${Constants.BACKEND_BASE_URL}/api/sdk/shortener'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fullUrl': url}),
    );
    final res = jsonDecode(response.body);
    if (response.statusCode != 200) {
      logger.info('Failed to shorten URL: $url, Response: ${jsonEncode(res)}');
      return url;
    }
    final shortenedVerificationUrl = res['result']['shortUrl'];
    return shortenedVerificationUrl;
  } catch (err) {
    logger.info('Error shortening URL: $url, Error: $err');
    return url;
  }
}

Future<String> createLinkWithTemplateData(TemplateData templateData) async {
  String template = Uri.encodeComponent(jsonEncode(templateData));
  template = template.replaceAll('(', '%28').replaceAll(')', '%29');

  final fullLink = '${Constants.RECLAIM_SHARE_URL}$template';
  try {
    final shortenedLink = await getShortenedUrl(fullLink);
    return shortenedLink;
  } catch (err) {
    logger.info(
        'Error creating link for sessionId: ${templateData.sessionId}, Error: $err');
    return fullLink;
  }
}

Future<List<String>> getWitnessesForClaim(
  int epoch,
  String identifier,
  int timestampS,
) async {
  try {
    final beacon = await makeBeacon();
    if (beacon == null) {
      logger.info('No beacon available for getting witnesses');
      throw Exception('No beacon available');
    }
    final state = await beacon.getState(epoch: epoch);
    final witnessList = fetchWitnessListForClaim(state, identifier, timestampS);
    final witnesses = witnessList.map((w) => w.id.toLowerCase()).toList();
    return witnesses;
  } catch (err) {
    logger.info('Error getting witnesses for claim: $err');
    throw Exception('Error getting witnesses for claim: $err');
  }
}

List<String> recoverSignersOfSignedClaim(SignedClaim signedClaim) {
  final dataStr = createSignDataForClaim(signedClaim.claim);
  final credentials = signedClaim.signatures.map((signature) {
    final message = utf8.encode(dataStr);

    // Convert the signature from Uint8List to hex string
    final signatureHex = bytesToHex(signature, include0x: true);

    final address = EthSigUtil.recoverPersonalSignature(
      signature: signatureHex,
      message: message,
    );
    return address.toLowerCase();
  }).toList();

  return credentials;
}

void assertValidSignedClaim(
  SignedClaim claim,
  List<String> expectedWitnessAddresses,
) {
  final witnessAddresses = recoverSignersOfSignedClaim(claim);
  final witnessesNotSeen = Set<String>.from(expectedWitnessAddresses);
  for (final witness in witnessAddresses) {
    if (witnessesNotSeen.contains(witness)) {
      witnessesNotSeen.remove(witness);
    }
  }

  if (witnessesNotSeen.isNotEmpty) {
    final missingWitnesses = witnessesNotSeen.join(', ');
    logger.info(
        'Claim validation failed. Missing signatures from: $missingWitnesses');
    throw proofNotVerifiedError('Missing signatures from $missingWitnesses');
  }
}
