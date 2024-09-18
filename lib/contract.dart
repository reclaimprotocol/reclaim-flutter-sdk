import 'package:reclaim_sdk/types.dart';
import 'package:reclaim_sdk/witness.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:reclaim_sdk/contract_data/abi.dart';

const int defaultChainId = 11155420;
final existingContractsMap = <String, DeployedContract>{};
final contractConfig = {
  "0x1a4": {
    "chainName": "opt-goerli",
    "address": "0xF93F605142Fb1Efad7Aa58253dDffF67775b4520",
    "rpcUrl":
        "https://opt-goerli.g.alchemy.com/v2/rksDkSUXd2dyk2ANy_zzODknx_AAokui"
  },
  "0xaa37dc": {
    "chainName": "opt-sepolia",
    "address": "0x6D0f81BDA11995f25921aAd5B43359630E65Ca96",
    "rpcUrl":
        "https://opt-sepolia.g.alchemy.com/v2/aO1-SfG4oFRLyAiLREqzyAUu0HTCwHgs"
  }
};

Future<BeaconState> makeBeacon() async {
  final String chainKey = '0x${defaultChainId.toRadixString(16)}';
  final contract = getContract(defaultChainId);
  final contractData = contractConfig[chainKey]!;
  final client = Web3Client(contractData['rpcUrl']!, Client());
  final epochData = await fetchEpochData(contract!, client);
  return epochData;
}

DeployedContract? getContract(int chainId) {
  final String chainKey = '0x${chainId.toRadixString(16)}';
  if (!existingContractsMap.containsKey(chainKey)) {
    final contractData = contractConfig[chainKey];
    if (contractData == null) {
      throw Exception('Unsupported chain: "$chainKey"');
    }

    final contract = DeployedContract(
      ContractAbi.fromJson(abi, 'Reclaim'),
      EthereumAddress.fromHex(contractData['address']!),
    );
    existingContractsMap[chainKey] = contract;
  }

  return existingContractsMap[chainKey];
}

Future<BeaconState> fetchEpochData(DeployedContract contract, Web3Client client,
    [int epochId = 0]) async {
  // Define the function you want to call
  final function = contract.function('fetchEpoch');
  // Call the contract function
  final response = await client.call(
    contract: contract,
    function: function,
    params: [BigInt.from(epochId)],
  );

  if (response[0] == null) {
    throw Exception('Invalid epoch ID: $epochId');
  }

  final data = response[0];

  final epoch = data[0];
  final witnessesData = data[3];
  final witnessesRequiredForClaim = data[4];
  final nextEpochTimestampS = data[2];

  List<WitnessData> witnesses = witnessesData.map<WitnessData>((w) {
    return WitnessData(
      id: w[0]!.toString(),
      url: w[1]!,
    );
  }).toList();

  return BeaconState(
    epoch: epoch.toInt(),
    witnesses: witnesses,
    witnessesRequiredForClaim: witnessesRequiredForClaim.toInt(),
    nextEpochTimestampS: nextEpochTimestampS.toInt(),
  );
}
