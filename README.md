<div>
    <div>
        <img src="https://raw.githubusercontent.com/reclaimprotocol/.github/main/assets/banners/Flutter-SDK.png"  />
    </div>
</div>

# Reclaim Protocol Flutter SDK Integration Guide

This guide will walk you through integrating the Reclaim Protocol Flutter SDK into your application. We'll create a simple Flutter application that demonstrates how to use the SDK to generate proofs and verify claims.

## Prerequisites

Before we begin, make sure you have:

1. An application ID from Reclaim Protocol.
2. An application secret from Reclaim Protocol.
3. A provider ID for the specific service you want to verify.

You can obtain these details from the [Reclaim Developer Portal](https://dev.reclaimprotocol.org/).

## Step 1: Create a new Flutter application

Let's start by creating a new Flutter application:

```bash
flutter create reclaim_app
cd reclaim_app
```

## Step 2: Install necessary dependencies

Add the Reclaim Protocol SDK to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  reclaim_sdk: ^latest_version
  url_launcher: ^6.0.20
```

Then run:

```bash
flutter pub get
```

## Step 3: Set up your Flutter widget

Replace the contents of `lib/main.dart` with the following code:

```dart
import 'package:flutter/material.dart';
import 'package:reclaim_sdk/reclaim.dart';
import 'package:reclaim_sdk/utils/interfaces.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ReclaimDemo(),
    );
  }
}

class ReclaimDemo extends StatefulWidget {
  @override
  _ReclaimDemoState createState() => _ReclaimDemoState();
}

class _ReclaimDemoState extends State<ReclaimDemo> {
  String _status = '';
  String _proofData = '';

  Future<ReclaimProofRequest> _initializeProofRequest() async {
    final reclaimProofRequest =
        await ReclaimProofRequest.init("APP_ID", "APP_SECRET", "PROVIDER_ID");
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

  void startVerificationFlow() async {
    final reclaimProofRequest = await _initializeProofRequest();

    reclaimProofRequest.setAppCallbackUrl('YOUR_DEEP_LINK');

    final requestUrl = await _generateRequestUrl(reclaimProofRequest);
    await _launchUrl(requestUrl);
    await _startVerificationSession(reclaimProofRequest);
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
              onPressed: startVerificationFlow,
              child: const Text('Start Reclaim Session!'),
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

```

## Step 4: Understanding the code

Let's break down what's happening in this code:

1. We create a `ReclaimDemo` widget that manages the state of our Reclaim integration.

2. The `_initializeProofRequest()` method initializes the Reclaim SDK with your application ID, secret, and provider ID. This happens when we start the verification flow.

3. When the user taps the "Start Reclaim Session!" button, the `startVerificationFlow()` method is called, which:
   - Initializes the proof request.
   - Sets the app callback URL using `setAppCallbackUrl()`. This should be your app's deep link.
   - Generates a request URL using `_generateRequestUrl()`.
   - Launches the URL with `_launchUrl()`, which opens the Reclaim verification process in the user's browser.
   - Starts a session with `_startVerificationSession()`, which sets up callbacks for successful and failed verifications.

4. The `_launchUrl()` method uses the `url_launcher` package to open the verification URL in the user's default browser.

5. The `_startVerificationSession()` method sets up success and error callbacks:
   - `_handleProofSuccess()` is called when verification is successful, updating the UI with the proof data.
   - `_handleProofError()` is called if verification fails, updating the UI with the error message.

6. The UI is updated throughout the process to show the current status and any received proof data.

7. The proof data, when received, is displayed in a scrollable text area, showing both the extracted data and the full proof.

This implementation provides a more robust and user-friendly flow, handling the entire process from initialization to displaying the results, while also managing potential errors.

## Step 5: Run your application

Start your Flutter application:

```bash
flutter run
```

Your Reclaim SDK demo should now be running. Tap the "Create Claim" button to start the verification process.

## Understanding the Claim Process

1. **Creating a Claim**: When you tap "Create Claim", the SDK generates a unique request for verification.

2. **Verification**: The SDK handles the verification process, opening a web view for the user to complete the necessary steps.

3. **Handling Results**: The `onSuccessCallback` is called when verification is successful, providing the proof data. The `onFailureCallback` is called if verification fails.

## Advanced Configuration

The Reclaim SDK offers several advanced options to customize your integration:

1. **Adding Context**:
   You can add context to your proof request, which can be useful for providing additional information:
   ```dart
   reclaimProofRequest.addContext('0x00000000000', 'Example context message');
   ```

2. **Setting Parameters**:
   If your provider requires specific parameters, you can set them like this:
   ```dart
   reclaimProofRequest.setParams({'email': 'test@example.com', 'userName': 'testUser'});
   ```

3. **Custom Redirect URL**:
   Set a custom URL to redirect users after the verification process:
   ```dart
   reclaimProofRequest.setRedirectUrl('https://example.com/redirect');
   ```

4. **Exporting and Importing SDK Configuration**:
   You can export the entire Reclaim SDK configuration as a JSON string and use it to initialize the SDK with the same configuration on a different service or backend:
   ```dart
   // On the client-side or initial service
   String configJson = reclaimProofRequest.toJsonString();
   print('Exportable config: $configJson');
   
   // Send this configJson to your backend or another service
   
   // On the backend or different service
   ReclaimProofRequest importedRequest = await ReclaimProofRequest.fromJsonString(configJson);
   String requestUrl = await importedRequest.getRequestUrl();
   ```
   This allows you to generate request URLs and other details from your backend or a different service while maintaining the same configuration.

These advanced configurations provide more flexibility in customizing the Reclaim SDK integration to fit your specific use case and application architecture.

## Handling Proofs on Your Backend

For production applications, it's recommended to handle proofs on your backend:

1. Set a callback URL:
   ```dart
   reclaimProofRequest.setCallbackUrl('https://your-backend.com/receive-proofs');
   ```

This option allows you to securely process proofs on your server. When a proof is generated, it will be sent to the specified callback URL, where your backend can validate and process it.

Remember to implement proper security measures on your backend to verify the authenticity of the received proofs.

## Next Steps

Explore the [Reclaim Protocol documentation](https://docs.reclaimprotocol.org/) for more advanced features and best practices for integrating the SDK into your production applications.

Happy coding with Reclaim Protocol!

## Contributing to Our Project

We welcome contributions to our project! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## Security Note

Always keep your Application Secret secure. Never expose it in client-side code or public repositories.

## Code of Conduct

Please read and follow our [Code of Conduct](https://github.com/reclaimprotocol/.github/blob/main/Code-of-Conduct.md) to ensure a positive and inclusive environment for all contributors.

## Security

If you discover any security-related issues, please refer to our [Security Policy](https://github.com/reclaimprotocol/.github/blob/main/SECURITY.md) for information on how to responsibly disclose vulnerabilities.

## Contributor License Agreement

Before contributing to this project, please read and sign our [Contributor License Agreement (CLA)](https://github.com/reclaimprotocol/.github/blob/main/CLA.md).

## Indie Hackers

For Indie Hackers: [Check out our guidelines and potential grant opportunities](https://github.com/reclaimprotocol/.github/blob/main/Indie-Hackers.md)

## License

This project is licensed under a [custom license](https://github.com/reclaimprotocol/.github/blob/main/LICENSE). By contributing to this project, you agree that your contributions will be licensed under its terms.

Thank you for your contributions!