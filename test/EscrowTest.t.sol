// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";
import {MockNFT} from "./MockNft.sol";

contract EscrowTest is Test{
    Escrow escrow;
    MockNFT mocknft;

    function setUp() public{
        address token = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; //usdc
        escrow = new Escrow(address(this),token);
        mocknft = new MockNFT();
    }

    function test_canCreateEscrow() public {
        Escrow.EscrowInfo memory firstEscrow;
        firstEscrow.buyer = address(0xabc);
        firstEscrow.seller = address(0xbac);
        firstEscrow.asset = Escrow.AssetType.Native;
        firstEscrow.amount = 50e18;
        firstEscrow.deadline = block.timestamp + 30 days;
        firstEscrow.arbitratorFee = 0;
        firstEscrow.buyerConfirm = false;
        firstEscrow.sellerConfirm = false;
        firstEscrow.status = Escrow.EscrowStatus.NONE;
        firstEscrow.nftt = Escrow.NftInfo({
            nftAddress: address(mocknft),
            tokenId: 1 // mint a token id to seller and insert the right ID
        });
        // escrow.createEscrow();
    }
}