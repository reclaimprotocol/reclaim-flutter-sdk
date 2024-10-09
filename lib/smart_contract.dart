import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'utils/interfaces.dart';
import 'contract_data/abi.dart';
import 'utils/logger.dart';

var logger = ReclaimLogger();

const int DEFAULT_CHAIN_ID = 11155420;
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

Future<Beacon?> makeBeacon({int? chainId}) async {
  chainId ??= DEFAULT_CHAIN_ID;
  final contract = getContract(chainId);
  if (contract != null) {
    final contractData = contractConfig['0x${chainId.toRadixString(16)}']!;
    final client = Web3Client(contractData['rpcUrl']!, Client());
    final epochData = await fetchEpochData(contract, client);
    return BeaconImpl(contract, epochData);
  } else {
    return null;
  }
}

class BeaconImpl implements Beacon {
  final DeployedContract _contract;
  final BeaconState _state;

  BeaconImpl(this._contract, this._state);

  @override
  Future<BeaconState> getState({int? epoch}) async {
    if (epoch == null || epoch == _state.epoch) {
      return _state;
    }
    final client = Web3Client(
        contractConfig['0x${DEFAULT_CHAIN_ID.toRadixString(16)}']!['rpcUrl']!,
        Client());
    return fetchEpochData(_contract, client, epoch);
  }

  @override
  Future<void> close() async {
    // No need to implement close for Web3Dart
  }
}

Beacon makeBeaconCacheable(Beacon beacon) {
  final cache = <int, Future<BeaconState>>{};

  return _CacheableBeacon(beacon, cache);
}

class _CacheableBeacon implements Beacon {
  final Beacon _beacon;
  final Map<int, Future<BeaconState>> _cache;

  _CacheableBeacon(this._beacon, this._cache);

  @override
  Future<BeaconState> getState({int? epoch}) async {
    if (epoch == null) {
      return await _beacon.getState();
    }

    if (!_cache.containsKey(epoch)) {
      _cache[epoch] = _beacon.getState(epoch: epoch);
    }

    return await _cache[epoch]!;
  }

  @override
  Future<void> close() async {
    await _beacon.close();
  }
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
  final function = contract.function('fetchEpoch');
  final response = await client.call(
    contract: contract,
    function: function,
    params: [BigInt.from(epochId)],
  );

  if (response[0] == null) {
    logger.info('Invalid epoch ID: $epochId');
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
