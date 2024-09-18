<div>
    <div>
        <img src="https://raw.githubusercontent.com/reclaimprotocol/.github/main/assets/banners/Flutter-SDK.png"  />
    </div>
</div>

## Pre-requisites

- An application ID from Reclaim Protocol. You can get one from the [Reclaim Developer Protocol](https://dev.reclaimprotocol.org/)

## Create a new Flutter application

```bash
flutter create reclaim_app
cd reclaim_app
```

## Install the Reclaim Protocol Flutter SDK

```bash
flutter pub add reclaim_sdk
```

## Import dependencies

In your `lib/main.dart` file, import the Reclaim SDK

```dart
import 'package:reclaim_sdk/flutter_reclaim.dart';
import 'package:reclaim_sdk/types.dart';
```

## Initialize the Reclaim SDK

Declare your `application ID` and initialize the Reclaim Protocol client. Replace `YOUR_APPLICATION_ID_HERE` with the actual application ID provided by Reclaim Protocol.

File: `lib/main.dart`

```dart copy
import 'package:reclaim_sdk/flutter_reclaim.dart';
import 'package:reclaim_sdk/types.dart';

class _MyHomePageState extends State<MyHomePage> {
    String data = "";

    ProofRequest proofRequest = ProofRequest(applicationId: 'YOUR_APPLICATION_ID_HERE');
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text(widget.title),
            ),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                        const Text(
                            'Prove that you have Steam ID By clicking on Verify button:',),
                        Text(data,
                            style: Theme.of(context).textTheme.headlineMedium,
                        ),
                    ],
                ),
            ),

        );
    }
}
```

### Add your app deep link

You'll need to add a deep link to your app. This will be used to redirect the user back to your app after they have completed the verification process.

- Guide to setup deep link on react-native can be found [here](https://reactnavigation.org/docs/deep-linking/).

```dart copy
import 'package:reclaim_sdk/flutter_reclaim.dart';
import 'package:reclaim_sdk/types.dart';

class _MyHomePageState extends State<MyHomePage> {
    String data = "";

    ProofRequest proofRequest = ProofRequest(applicationId: 'YOUR_APPLICATION_ID_HERE');

    void startVerificationFlow() async {
        proofRequest.setAppCallbackUrl('YOUR_DEEP_LINK'); // here is deep link
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text(widget.title),
            ),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                        const Text(
                            'Prove that you have Steam ID By clicking on Verify button:',),
                        Text(data,
                            style: Theme.of(context).textTheme.headlineMedium,
                        ),
                    ],
                ),
            ),

        );
    }
}

```

## Implement Verification Request Function

Create functions to handle the verification request. You'll need separate functions for prototype and production modes due to the different handling of the application secret and signature.

### Prototype Mode

For testing purposes, use the prototype mode. Note that in production, you should handle the application secret securely on your server.

File: `lib/main.dart`

```dart
import 'package:reclaim_sdk/flutter_reclaim.dart';
import 'package:reclaim_sdk/types.dart';

class _MyHomePageState extends State<MyHomePage> {
    String data = "";

    ProofRequest proofRequest = ProofRequest(applicationId: 'YOUR_APPLICATION_ID_HERE');

    void startVerificationFlow() async {
        proofRequest.setAppCallbackUrl('YOUR_DEEP_LINK'); // here is deep link

        await proofRequest
            .buildProofRequest("YOUR_PROVIDER_ID");

        proofRequest.setSignature(proofRequest.generateSignature(
            'YOUR_PRIVATE_KEY'));

        await proofRequest.createVerificationRequest();

        final startSessionParam = StartSessionParams(
            onSuccessCallback: (proof) => setState(() {
                data = jsonEncode(proof.extractedParameterValues);
            }),
            onFailureCallback: (error) => {
                setState(() {
                data = 'Error: $error';
                })
            },
        );

        await proofRequest.startSession(startSessionParam);

    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text(widget.title),
            ),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                        const Text(
                            'Prove that you have Steam ID By clicking on Verify button:',),
                        Text(data,
                            style: Theme.of(context).textTheme.headlineMedium,
                        ),
                    ],
                ),
            ),
            floatingActionButton: FloatingActionButton(
                onPressed: startVerificationFlow,
                tooltip: 'Verify ',
                child: const Text('Verify'),
            ),
        );
    }
}

```

### Production Mode

In production mode, securely fetch and set the signature from your backend instead of using the application secret directly in the client.

Similar to the prototype mode but ensure to fetch and set the signature securely

```javascript
void startVerificationFlow() async {
    proofRequest.setAppCallbackUrl('YOUR_DEEP_LINK'); // here is deep link

    await proofRequest
        .buildProofRequest("YOUR_PROVIDER_ID");

    proofRequest.setSignature(
        // TODO: fetch signature from your backend
        // On the backend, generate signature using:
        // await Reclaim.getSignature(requestedProofs, APP_SECRET)
    );

    await proofRequest.createVerificationRequest();

    final startSessionParam = StartSessionParams(
        onSuccessCallback: (proof) => setState(() {
            data = jsonEncode(proof.extractedParameterValues);
        }),
        onFailureCallback: (error) => {
            setState(() {
            data = 'Error: $error';
            })
        },
    );

    await proofRequest.startSession(startSessionParam);

}
```


## Contributing to Our Project

We're excited that you're interested in contributing to our project! Before you get started, please take a moment to review the following guidelines.

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
