import 'dart:convert';
import 'package:http/http.dart' as http;

import 'errors.dart';
import 'interfaces.dart';
import 'types.dart';
import 'validation_utils.dart';
import 'constants.dart';
import 'logger.dart';

/// Initializes a session with the provided parameters
/// @param providerId - The ID of the provider
/// @param appId - The ID of the application
/// @param timestamp - The timestamp of the request
/// @param signature - The signature for authentication
/// @returns A Future that resolves to an InitSessionResponse
/// @throws InitSessionError if the session initialization fails
Future<InitSessionResponse> initSession(
  String providerId,
  String appId,
  String timestamp,
  String signature,
) async {
  logger
      .info('Initializing session for providerId: $providerId, appId: $appId');
  try {
    final response = await http.post(
      Uri.parse('${Constants.BACKEND_BASE_URL}/api/sdk/init-session/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'providerId': providerId,
        'appId': appId,
        'timestamp': timestamp,
        'signature': signature,
      }),
    );

    final res = jsonDecode(response.body);

    if (response.statusCode != 201) {
      logger.info(
          'Session initialization failed: ${res['message'] ?? 'Unknown error'}');
      throw initSessionError(res['message'] ??
          'Error initializing session with providerId: $providerId');
    }

    return InitSessionResponse(
      sessionId: res['sessionId'],
      provider: ProviderData.fromJson(res['provider']),
    );
  } catch (err) {
    logger.info({
      'message': 'Failed to initialize session',
      'providerId': providerId,
      'appId': appId,
      'timestamp': timestamp,
      'error': err.toString(),
    });
    rethrow;
  }
}

/// Updates the status of an existing session
///
/// @param sessionId - The ID of the session to update
/// @param status - The new status of the session
/// @returns A Future that resolves to the update response
/// @throws UpdateSessionError if the session update fails
Future<UpdateSessionResponse> updateSession(
    String sessionId, SessionStatus status) async {
  logger.info(
      'Updating session status for sessionId: $sessionId, new status: ${status.toString()}');
  validateFunctionParams([
    ParamValidation(input: sessionId, paramName: 'sessionId', isString: true)
  ], 'updateSession');

  try {
    final response = await http.post(
      Uri.parse('${Constants.BACKEND_BASE_URL}/api/sdk/update/session/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sessionId': sessionId, 'status': status.name}),
    );

    final res = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final errorMessage =
          'Error updating session with sessionId: $sessionId. Status Code: ${response.statusCode}';
      logger.info('$errorMessage\n$res');
      throw updateSessionError(errorMessage);
    }

    logger
        .info('Session status updated successfully for sessionId: $sessionId');
    return UpdateSessionResponse(message: res['message']);
  } catch (err) {
    final errorMessage = 'Failed to update session with sessionId: $sessionId';
    logger.info('$errorMessage\n${err.toString()}');
    throw updateSessionError(
        'Error updating session with sessionId: $sessionId');
  }
}

/// Fetches the status URL for a given session ID
///
/// @param sessionId - The ID of the session to fetch the status URL for
/// @returns A Future that resolves to a StatusUrlResponse
/// @throws StatusUrlError if the status URL fetch fails
Future<StatusUrlResponse> fetchStatusUrl(String sessionId) async {
  try {
    validateFunctionParams([
      ParamValidation(input: sessionId, paramName: 'sessionId', isString: true)
    ], 'fetchStatusUrl');

    final response = await http.get(
      Uri.parse('${Constants.DEFAULT_RECLAIM_STATUS_URL}$sessionId'),
      headers: {'Content-Type': 'application/json'},
    );

    final res = jsonDecode(response.body);

    if (response.statusCode != 200) {
      logger.info(
          'Error fetching status URL for sessionId: $sessionId. Status Code: ${response.statusCode}');
      throw statusUrlError(
          'Error fetching status URL for sessionId: $sessionId');
    }

    return StatusUrlResponse.fromJson(res);
  } catch (err) {
    logger.info('Failed to fetch status URL for sessionId: $sessionId');
    throw statusUrlError('Error fetching status URL for sessionId: $sessionId');
  }
}
