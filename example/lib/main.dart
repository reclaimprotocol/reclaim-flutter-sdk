// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:reclaim_sdk/reclaim.dart';
import 'package:reclaim_sdk/utils/types.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MaterialApp(home: ReclaimExample()));
}

class ReclaimExample extends StatefulWidget {
  const ReclaimExample({super.key});

  @override
  State<ReclaimExample> createState() => _ReclaimExampleState();
}

class _ReclaimExampleState extends State<ReclaimExample> {
  String _status = '';
  String _proofData = '';

  // Reclaim SDK Methods:
  // 1. ReclaimProofRequest.init('appId', 'appSecret', 'providerId') - Initialize a new proof request
  // 2. reclaimProofRequest.addContext('contextId', 'contextMessage') - Add context to the proof request
  // 3. reclaimProofRequest.setRedirectUrl('redirectUrl') - Set the redirect URL
  // 4. reclaimProofRequest.setAppCallbackUrl('appCallbackUrl') - Set the app callback URL
  // 5. reclaimProofRequest.setParams({'paramId1': 'paramValue1', 'paramId2': 'paramValue2'}) - Set the parameters for the proof request
  // 6. reclaimProofRequest.toJsonString() - Convert the request to a JSON string
  // 7. ReclaimProofRequest.fromJsonString('jsonString') - Create a request from a JSON string
  // 8. reclaimProofRequest.getRequestUrl() - Generate the request URL
  // 9. reclaimProofRequest.getSessionStatus() - Get the session status
  // 10. reclaimProofRequest.startSession() - Start the verification session

  Future<void> startReclaimSession() async {
    try {
      print('Starting Reclaim session');
      final reclaimProofRequest = await _initializeProofRequest();
      final requestUrl = await _generateRequestUrl(reclaimProofRequest);
      await _launchUrl(requestUrl);
      await _startVerificationSession(reclaimProofRequest);
    } catch (error) {
      _handleError('Error starting Reclaim session', error);
    }
  }

  Future<ReclaimProofRequest> _initializeProofRequest() async {
    print('Initializing proof request');
    final appId = dotenv.env['APP_ID'];
    final appSecret = dotenv.env['APP_SECRET'];
    final providerId = dotenv.env['PROVIDER_ID'];

    if (appId == null || appSecret == null || providerId == null) {
      throw Exception('Environment variables are not set properly');
    }

    final reclaimProofRequest = await ReclaimProofRequest.init(appId, appSecret,
        providerId, ProofRequestOptions(log: true, useAppClip: false));

    // reclaimProofRequest.addContext('0x00000000000', 'Example context message');
    // reclaimProofRequest.setRedirectUrl('https://dev.reclaimprotocol.org/');

    print('Proof JSON object: ${reclaimProofRequest.toJsonString()}');
    return reclaimProofRequest;
  }

  Future<String> _generateRequestUrl(ReclaimProofRequest request) async {
    final requestUrl = await request.getRequestUrl();
    print('Request URL: $requestUrl');
    return requestUrl;
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        setState(() => _status = 'Session started. Waiting for proof...');
      } else {
        throw 'Could not launch $url';
      }
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _startVerificationSession(ReclaimProofRequest request) async {
    await request.startSession(
      onSuccess: _handleProofSuccess,
      onError: _handleProofError,
    );
  }

  void _handleProofSuccess(dynamic proof) {
    print('Proof received: $proof');
    // check if proof is of type String
    var proofDataValue = '';
    if (proof is String) {
      proofDataValue = proof;
    } else {
      proofDataValue =
          'Extracted data: ${proof.claimData.context}\n\nFull proof: ${proof.toString()}';
    }
    setState(() {
      _status = 'Proof received!';
      _proofData = proofDataValue;
    });
  }

  void _handleProofError(Exception error) {
    _handleError('Error in proof generation', error);
  }

  void _handleError(String message, dynamic error) {
    print('$message: $error');
    setState(() => _status = '$message: ${error.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reclaim SDK Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: startReclaimSession,
              child: const Text('Start Reclaim Session'),
            ),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (_proofData.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_proofData),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
