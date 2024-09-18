import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:reclaim_sdk/flutter_reclaim.dart';
import 'package:reclaim_sdk/types.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(const MyApp());
}

var logger = Logger(
  printer: PrettyPrinter(methodCount: 10),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reclaim SDK Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Reclaim SDK Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String data = "";

  ProofRequest proofRequest = ProofRequest(
      applicationId: '0x5Ccd1f72E3347629943e6a4aA9C22803F1064Ebf', log: true);

  void startVerificationFlow() async {
    proofRequest.setAppCallbackUrl('mychat://chat/');

    proofRequest.addContext('YOUR_CONTEXT_ADDRESS', 'YOUR_CONTEXT_MESSAGE');
    await proofRequest
        .buildProofRequest("1bba104c-f7e3-4b58-8b42-f8c0346cdeab");
    // await proofRequest
    //     .buildProofRequest("1bba104c-f7e3-4b58-8b42-f8c0346cdeab", redirectUser: true, linkingVersion: 'V2Linking'); // Redirect user & New linking version

    // proofRequest.setParams({'steamId': '1234567890'}); // Set the claim data params
    // proofRequest.setRedirectUrl('https://my-demo-site.vercel.app/'); // Set the redirect URL
    proofRequest.setSignature(proofRequest.generateSignature(
        '0x2ef3c18823e6e77ed0888a0b4045efc36f22a35f3ed10481d4b3acc2b21e0188'));

    final verificationRequest = await proofRequest.createVerificationRequest();
    final [
      requestUrl,
      statusUrl
    ] = [verificationRequest['requestUrl'], verificationRequest['statusUrl']];

    logger.i(requestUrl);
    logger.i(statusUrl);

    final startSessionParam = StartSessionParams(
      onSuccessCallback: (proof) => setState(() {
        final jsonContext =
            jsonDecode(proof.claimData.context) as Map<String, dynamic>;
        final jsonExtractedParameters = jsonContext["extractedParameters"];
        logger.i(jsonContext);
        data = jsonExtractedParameters["CLAIM_DATA"];
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
              'Prove that you have Steam ID By clicking on Verify button:',
            ),
            Text(
              data,
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
