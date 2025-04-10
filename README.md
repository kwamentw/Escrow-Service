## Escrow Service

**This repository provides a Solidity implementation of an Escrow Smart Contract, designed to enable secure transactions between two parties by holding funds until agreed-upon conditions are met before transfer to receiver. The contract supports NFTs, native tokens, and stablecoins (e.g. USDC). It acts as a mediator to ensure trust and prevent fraud during transactions.**

## Main Features 

    🔒 Secure Fund Storage: 💰 Funds are securely held within the smart contract until the specified release conditions are met.

    🔧 Two-Party Agreement: Both the sender (📤 payer) and the receiver (📥 payee) must agree before the funds are released.

    📚 Deposits and Withdrawals: The contract facilitates 💳 deposits by the payer and withdrawals by the payee according to predefined rules.

    ⚖️ Arbitration: In case of disputes, an 🤷 arbitrator can mediate and make a 🔒 final decision on fund release or refund.

    🕵️ Transparency and Decentralization: All 📊 transactions are recorded on the 🔐 blockchain, ensuring a 🔓 transparent and tamper-proof system.


## How this contract works

    Creating an Escrow:

        The 📤 payer (depositor) creates an escrow and deposits the agreed-upon 💳 assets (🔑 NFTs, 💳 ERC20 tokens like 💵 USDC, or 📈 native ETH) into the contract.

        Parameters such as the receiver’s 🔍 address and additional terms are set.

    Confirming Services:

        Once the receiver renders the agreed-upon 🛠️ service, the payer confirms the release of the 💰 funds by calling the confirmEscrow function.

        The 📥 receiver must also confirm the ✅ successful completion of rendering their service.

    Handling Disputes:

        If either party fails to fulfill their agreement, an 🤷 arbitrator is involved to mediate the dispute and determine the outcome.

        The arbitrator’s decision is ⚖️ final, whether to refund the 📤 payer or release funds to the 📥 receiver.

    Automatic Resolution:

        If both parties confirm successfully before the ⏳ deadline, the arbitrator releases 💰 funds to the receiver.

        If the ⏰ deadline passes without confirmation, the 💰 funds are refunded to the depositor.

## Key Actors
    * 🔧 Owner: The administrator and owner of the protocol.
    * ⚖️ Arbitrator: A neutral 🤷 third party responsible for mediating disputes and making final decisions.
    * 📤 Depositor: The individual creating the escrow and depositing 💰 assets.
    * 📥 Receiver: The intended recipient of the escrowed 💰 assets.

## What problem does this protocol solve?
    This protocol addresses the issue of ✅ trust in 💳 transactions involving goods or services between parties who may not 👨‍👩‍👦 know or trust each other. By acting as a 🤝 mediator, it ensures that 💰 funds are only released once both parties fulfill their obligations.

## ⚙️ Usage

### 🔨 Build

```shell
$ forge build
```

### ✅ Test

```shell
$ forge test
```

## 📜 License
This project is licensed under the MIT License. 

## ✨ Contributions
Contributions are welcome! Please feel free to submit 📝 issues or suggestions to improve the project.

