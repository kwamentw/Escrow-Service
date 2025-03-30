## Escrow Service

**This repository contains a Solidity implementation of an Escrow Smart Contract, which facilitates secure transactions between two parties by holding funds until specified conditions are met. This is an Escrow contract for NFTs, native tokens and stablecoin(USDC): This contract is used for payment purposes, i.e if a user creates an escrow with this contract, he might be buying the services of someone he does not trust and needs a system to act as a mediator of payment to prevent fraud.**

## Features 

    * Secure Fund Storage: Funds are securely stored in the smart contract until release conditions are fulfilled.

    * Two-Party Agreement: Both the sender (payer) and the receiver (payee) must agree before funds are released.

    * Deposits and Withdrawals: The contract allows deposits by the payer and withdrawals by the payee under defined rules.

    * Arbitration: Optionally, a third party (arbitrator) can mediate in case of disputes.

    * Transparency and Decentralization: Transactions are recorded on the blockchain, ensuring transparency.


## How this contract works

    The user has to create an escrow and deposit whatever token he will be paying out into the contract
    set the necessary parameters of the escrow like who the recevier is and others.

    After this, if the user feels he is satisfied with the services of the receiver. He will have to confirm the release of tokens by calling the function, and if the receiver has also successfully rendered the service he has to call confirm to indicate he has done his part successfully.

    However, There could be problems like one of the parties involved in the escrow agreement not fulfilling their part of the agreement. In cases like this, we have arbitrators in the system that will look into the agreement and depict whether funds should be refunded or released.

    Arbitrators decisions are final.

    In cases where the deadline for confirming agreement is reached and both parties have confirmed successfully, The arbitrator will release funds to the reciever and end the escrow, Otherwise the escrow is refunded.

    Assets this escrow can handle: NFTs, ERC20(USDC), native eth

    This is intended to be deployed on the Ethereum network. However L2s might follow later.

## Key Actors
    * Owner: owner of the protocol
    * Arbitrtator: In charge of mediating escrows
    * Depositor: Creator of escrow, that deposits assets into escrow
    * Receiver: Receiver of assets escrowed

## What problem does this protocol solve?
    This protocol solves the problem of trust when purchasing goods or services from unknown people.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

