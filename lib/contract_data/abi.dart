const abi = """[
  {
  "inputs": [
    {
      "internalType": "uint32",
      "name": "epoch",
      "type": "uint32"
    }
  ],
  "name": "fetchEpoch",
  "outputs": [
    {
      "components": [
        {
          "internalType": "uint32",
          "name": "id",
          "type": "uint32"
        },
        {
          "internalType": "uint32",
          "name": "timestampStart",
          "type": "uint32"
        },
        {
          "internalType": "uint32",
          "name": "timestampEnd",
          "type": "uint32"
        },
        {
          "components": [
            {
              "internalType": "address",
              "name": "addr",
              "type": "address"
            },
            {
              "internalType": "string",
              "name": "host",
              "type": "string"
            }
          ],
          "internalType": "struct Reclaim.Witness[]",
          "name": "witnesses",
          "type": "tuple[]"
        },
        {
          "internalType": "uint8",
          "name": "minimumWitnessesForClaimCreation",
          "type": "uint8"
        }
      ],
      "internalType": "struct Reclaim.Epoch",
      "name": "",
      "type": "tuple"
    }
  ],
  "stateMutability": "view",
  "type": "function"
}
]""";
