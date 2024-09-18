import 'dart:convert';
import 'dart:core';
import 'package:reclaim_sdk/flutter_reclaim.dart';
import 'package:http/http.dart' as http;
import 'package:eth_sig_util/eth_sig_util.dart';

import 'package:reclaim_sdk/constants.dart';
import 'package:reclaim_sdk/types.dart';
import 'package:reclaim_sdk/errors.dart';
import 'package:web3dart/crypto.dart';

void validateNotNullOrUndefined(
    dynamic value, String fieldName, String functionName) {
  if (value == null) {
    throw ArgumentError(
        '$fieldName should not be null or undefined in $functionName');
  }
}

void validateNonEmptyString(
    String value, String fieldName, String functionName) {
  if (value.isEmpty) {
    throw ArgumentError('$fieldName should not be empty in $functionName');
  }
}

void validateURL(String url) {
  if (url.isEmpty) {
    throw Exception('Invalid URL: $url. URL cannot be empty');
  }
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) {
    throw Exception('Invalid URL: $url.');
  }
}

Future<String> getShortenedUrl(String url) async {
  try {
    final response = await http.post(
        Uri.parse('$BACKEND_BASE_URL/api/sdk/shortener'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fullUrl': url}));
    final res = json.decode(response.body);
    final shortenedVerificationUrl = res['result']['shortUrl'];
    return shortenedVerificationUrl;
  } catch (err) {
    return url;
  }
}

Future<void> callProofCallback(String sessionId, Proof proof) async {
  try {
    final response = await http.post(
        Uri.parse('${Constants.DEFAULT_RECLAIM_CALLBACK_URL}$sessionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(proof.toJson()));

    final res = json.decode(response.body);

    if (response.statusCode != 200) {
      throw Exception('Error with sessionId: $sessionId');
    }

    return res;
  } catch (err) {
    logger.e(err);
  }
}

Future<void> createSession(
    String sessionId, ApplicationId appId, String providerId) async {
  try {
    final response =
        await http.post(Uri.parse('$BACKEND_BASE_URL/api/sdk/create-session/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'sessionId': sessionId,
              'appId': appId,
              'providerId': providerId,
            }));
    if (response.statusCode != 201) {
      throw CreateSessionError(
          'Error creating session with sessionId: $sessionId');
    }
    final res = json.decode(response.body);
    return res;
  } catch (err) {
    rethrow;
  }
}

Future<Map<String, dynamic>> getSession(String sessionId) async {
  try {
    final response = await http.get(
        Uri.parse('${Constants.DEFAULT_RECLAIM_STATUS_URL}$sessionId'),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode != 200) {
      throw GetSessionError('Error getting session with sessionId: $sessionId');
    }
    final res = json.decode(response.body);
    return res;
  } catch (err) {
    rethrow;
  }
}

Future<void> updateSession(String sessionId, SessionStatus status) async {
  try {
    final response =
        await http.post(Uri.parse('$BACKEND_BASE_URL/api/sdk/update/session/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'sessionId': sessionId,
              'status': status.name,
            }));
    if (response.statusCode != 200) {
      throw Exception('Error updating session with sessionId: $sessionId');
    }
    final res = json.decode(response.body);
    return res;
  } catch (err) {
    rethrow;
  }
}

Future<List<ProviderV2>> fetchProvidersByAppId(
    String appId, String providerId) async {
  try {
    final response = await http.get(Uri.parse(
        '${Constants.GET_PROVIDERS_BY_ID_API}/$appId/provider/$providerId'));
    final res = json.decode(response.body);
    List<dynamic> rawProviders = res['providers']['httpProvider'];
    final providers = rawProviders.map((p) => ProviderV2.fromJson(p)).toList();
    return providers;
  } catch (err) {
    logger.e(err);
    throw Exception('Error fetching provider with AppId: $appId');
  }
}

ProviderV2 validateProviderIdsAndReturnProviders(
    String providerId, List<ProviderV2> providers) {
  final providerExists =
      providers.any((provider) => providerId == provider.httpProviderId);
  if (!providerExists) {
    throw Exception(
        'The following provider Id is not included in your application => $providerId');
  }
  return providers
      .firstWhere((provider) => providerId == provider.httpProviderId);
}

RequestedProofs generateRequestedProofs(ProviderV2 provider, Context context,
    String callbackUrl, String sessionId, bool redirectUser) {
  Map<String, String?> providerParams = {};
  for (var rs in provider.responseSelections) {
    final keyParamMatches = RegExp(r'{{(.*?)}}').allMatches(rs.responseMatch);
    for (var match in keyParamMatches) {
      providerParams[match.group(1)!] = null;
    }
  }

  Metadata metadata = Metadata(
    name: Uri.encodeComponent(provider.name),
    logoUrl: provider.logoUrl,
    proofCardTitle: provider.proofCardTitle,
    proofCardText: provider.proofCardText,
  );

  Payload payload = Payload(
      metadata: metadata,
      url: provider.url,
      urlType: provider.urlType,
      method: provider.method ?? '',
      login: Login(url: provider.loginUrl),
      responseSelections: provider.responseSelections,
      injectionType: provider.injectionType,
      customInjection: provider.customInjection ?? '',
      disableRequestReplay: provider.disableRequestReplay,
      bodySniff: provider.bodySniff,
      geoLocation: provider.geoLocation,
      matchType: provider.matchType,
      verificationType: provider.verificationType,
      parameters: providerParams);

  List<RequestedClaim> claims = [
    RequestedClaim(
      provider: Uri.encodeComponent(provider.name),
      context: json.encode(context.toJson()),
      httpProviderId: provider.httpProviderId,
      payload: payload,
    ),
  ];

  RequestedProofs requestedProofs = RequestedProofs(
    id: sessionId,
    sessionId: sessionId,
    name: redirectUser ? "web-r-SDK" : 'web-SDK',
    callbackUrl: callbackUrl,
    claims: claims,
  );

  return requestedProofs;
}

void validateSignature(RequestedProofs requestedProofs, String signature,
    ApplicationId applicationId, String linkingVersion, String timeStamp) {
  try {
    var address = '';
    if (requestedProofs.claims.isNotEmpty &&
        (linkingVersion == 'V2Linking' ||
            requestedProofs.claims[0].payload.verificationType == 'MANUAL')) {
      final messageHash = keccak256(utf8.encode(jsonEncode({
        'providerId': requestedProofs.claims[0].httpProviderId,
        'timestamp': timeStamp,
      })));

      address = EthSigUtil.recoverSignature(
          signature: signature, message: messageHash);
    } else {
      final messageHash =
          keccak256(utf8.encode(jsonEncode(requestedProofs.toJson())));

      address = EthSigUtil.recoverSignature(
          signature: signature, message: messageHash);
    }

    if (applicationId.toLowerCase() != address.toLowerCase()) {
      throw InvalidSignatureError();
    }
  } catch (err) {
    rethrow;
  }
}

String escapeRegExp(String string) {
  return string.replaceAll(RegExp(r'[.*+?^${}()|[\]\\]'), '\\\$&');
}

String replaceAll(String str, String find, String replace) {
  return str.replaceAll(RegExp(escapeRegExp(find)), replace);
}

Future<String> getBranchLink(String template) async {
  try {
    final response = await http.post(
      Uri.parse(Constants.RECLAIM_GET_BRANCH_URL),
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'template': template,
      }),
    );
    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);
      final link = decodedResponse['branchUrl'];
      if (link == null) {
        throw Exception('Failed to generate deep link');
      }
      return link;
    } else {
      throw Exception('Failed to generate deep link: ${response.statusCode}');
    }
  } catch (error) {
    rethrow;
  }
}
