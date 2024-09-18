import 'package:reclaim_sdk/types.dart';
import 'package:reclaim_sdk/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reclaim_sdk/flutter_reclaim.dart';

void main() {
  group('ProofRequest', () {
    test('auto assigns session id if not provided', () {
      final proofRequest = ProofRequest(applicationId: '123');
      expect(proofRequest.sessionId, isNotEmpty);
    });

    test('uses provided session id', () {
      const sessionId = 'abc123';
      final proofRequest =
          ProofRequest(applicationId: '123', sessionId: sessionId);
      expect(proofRequest.sessionId, sessionId);
    });

    test('throws error if invalid url passed to setAppCallbackUrl', () {
      final proofRequest = ProofRequest(applicationId: '123');
      expect(() => proofRequest.setAppCallbackUrl('invalid'), throwsException);
    });

    test('app callback url defaults if not set', () {
      final proofRequest = ProofRequest(applicationId: '123', sessionId: '123');
      expect(proofRequest.getAppCallbackUrl(), contains('123'));
    });

    test('throws error if buildProofRequest called before provider set', () {
      final proofRequest = ProofRequest(applicationId: '123');
      expect(() => proofRequest.getRequestedProofs(), throwsException);
    });
  });

  group('Reclaim', () {
    test('verifySignedProof returns true for valid proof', () async {
      // Mock or prepare the proof based on provided dummy data
      final claimData = ProviderClaimData(
        identifier:
            "0xafb5c7415e79bbf42b122d3c0d02d7b8da9deb04df933b95318b57483d587ae3",
        provider: "uidai-uid",
        parameters: "{\"uid\":\"673906874713\"}",
        owner: "0xdFb1dCADeeEC3273Fb2C50563312D1d5f7347615",
        timestampS: 1697188555,
        context: "",
        epoch: 2,
      );

      final witnesses = [
        WitnessData(
            id: "0x244897572368eadf65bfbc5aec98d8e5443a9072",
            url: "https://reclaim-node.questbook.app"),
      ];

      final proof = Proof(
          claimData: claimData,
          signatures: [
            "0x17a4133c87ebe482a33607486b5014b9cc92890cdd862db405dbcaf1b96112f829a87d411d8fd25fcd408c021e87e345457d251f8b8afdb13476ca89b8aa80c31b"
          ],
          witnesses: witnesses,
          identifier:
              "0xafb5c7415e79bbf42b122d3c0d02d7b8da9deb04df933b95318b57483d587ae3");

      final result = await Reclaim.verifySignedProof(proof);
      expect(result, isTrue);
    });

    test('verifySignedProof returns false for invalid proof', () async {
      // Mock or prepare the proof based on provided dummy data
      final claimData = ProviderClaimData(
        identifier:
            "\"0xfdf4c79ab94a518ef051db3fe2cedac29c04a6fe98192a63eb9a16af05e7e800\"",
        provider: "http",
        parameters:
            "{\\\"body\\\":\\\"\\\",\\\"geoLocation\\\":null,\\\"method\\\":\\\"GET\\\",\\\"responseMatches\\\":[{\\\"type\\\":\\\"contains\\\",\\\"value\\\":\\\"\\\\\\\"text\\\\\\\":\\\\\\\"Abu H.\\\\\\\"\\\"}],\\\"responseRedactions\\\":[{\\\"jsonPath\\\":\\\"\$.included[20].topComponents[1].components.fixedListComponent.components[1].components.entityComponent.titleV2.text.text\\\",\\\"regex\\\":\\\"\\\\\\\"text\\\\\\\":\\\\\\\"(.*)\\\\\\\"\\\"}],\\\"url\\\":\\\"https://www.linkedin.com/voyager/api/graphql?includeWebMetadata=true&variables=(profileUrn:urn%3Ali%3Afsd_profile%3AACoAADHGiQcBmBLII4fcXfBRYBSvMNWgc8Di2uQ)&queryId=voyagerIdentityDashProfileCards.59ebe340d59d00fa3113f8de4dc6da66\\\"}\"",
        owner: "0x70748d6aab7f45047363c1c254cb3bcd7be68216",
        timestampS: 1709646959,
        context: "{\"contextAddress\":\"\",\"contextMessage\":\"\"}",
        epoch: 2,
      );
      final witnesses = [
        WitnessData(
            id: "0x244897572368eadf65bfbc5aec98d8e5443a9072",
            url: "https://reclaim-node.questbook.app"),
      ];
      final proof = Proof(
          claimData: claimData,
          signatures: [
            "0x312db6100cdee666b49ca6d5a6845dee25609b03989699545b10f617c9f2b7fd03c949667d957e8fd67e0a49b555639e6baad4f667ff8be96261a5880adb5d5c1c"
          ],
          witnesses: witnesses,
          identifier:
              "0xfdf4c79ab94a518ef051db3fe2cedac29c04a6fe98192a63eb9a16af05e7e800");

      final result = await Reclaim.verifySignedProof(proof);
      expect(result, isFalse);
    });
  });

  group('util', () {
    test('validateSignature should pass', () async {
      const String privateKey =
          '0x9bed3cc80d767e6f245fb5e744f9363f7cff0a7f016a749eb9292ebefeeea745';
      const publicKey = '0x9ad9aD9EB39DED02F3e904014888Ecbc44a5383F';
      final proofRequest = ProofRequest(applicationId: publicKey);
      await proofRequest
          .buildProofRequest('5e96617c-351c-4f76-a6af-556ee7fcb522');
      final signature = proofRequest.generateSignature(privateKey);

      validateSignature(proofRequest.requestedProofs!, signature, publicKey);
    });

    test('validateSignature should fail', () async {
      const String privateKey =
          '0x9bed3cc80d767e6f245fb5e744f9363f7cff0a7f016a749eb9292ebefeeea745';
      const publicKey = '0x9ad9aD9EB39DED02F3e904014888Ecbc44a5383F';
      final proofRequest = ProofRequest(applicationId: publicKey);
      await proofRequest
          .buildProofRequest('5e96617c-351c-4f76-a6af-556ee7fcb522');
      var signature = proofRequest.generateSignature(privateKey);
      signature = signature.substring(0, signature.length - 1) + '1';
      expect(
          () => validateSignature(
              proofRequest.requestedProofs!, signature, publicKey),
          throwsArgumentError);
    });

    test('validateSignature should fail', () async {
      const String privateKey =
          '0x9bed3cc80d767e6f245fb5e744f9363f7cff0a7f016a749eb9292ebefeeea745';
      const wrongPublicKey = '0x9ad9aD9E129DED02F3e904014888Ecbc44a5383F';
      const publicKey = '0x9ad9aD9EB39DED02F3e904014888Ecbc44a5383F';
      final proofRequest = ProofRequest(applicationId: publicKey);
      await proofRequest
          .buildProofRequest('5e96617c-351c-4f76-a6af-556ee7fcb522');
      var signature = proofRequest.generateSignature(privateKey);

      expect(
          () => validateSignature(
              proofRequest.requestedProofs!, signature, wrongPublicKey),
          throwsException);
    });
  });
}
