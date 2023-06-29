# A Simple Staking App

## Contracts

1. Stake : All staking logic can be found in this contract.
2. Reward: The reward token is different from the staking token.
3. MyToken: The token which is staked for earning Reward tokens.
4. ClaimMTK: A contract which facilitates claiming MyToken for free, which then can be used for staking.

## Reward Mechanism

Rewards are accumulated with each passing second and can be claimed at any point of time.
However, if the rewards are claimed within the cooldown period then only half the accumulated rewards are transferred.

## Contract Addresses:

All contracts are deployed on Sepolia Testnet:

[MyToken](https://sepolia.etherscan.io/address/0x5464fAAC7a9f74B76c7BBF64fF95B593CE2F1fa7#code)

[Stake](https://sepolia.etherscan.io/address/0x69a7DED635ad8aDc70477B465FE08080a632dd2b)

[Reward](https://sepolia.etherscan.io/address/0x9C39648A9b7951f86E57713B10B94fc9Cd19c650)

[ClaimMTK](https://sepolia.etherscan.io/address/0x2C9914A69CD6A887145fc684834cccb89837ecD4)

Note:

- The unverified contracts can be checked for their authenticity in the repo itself.