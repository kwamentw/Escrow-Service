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

    function createNativeEscrow() public payable returns(uint256 _id) {
        
        Escrow.EscrowInfo memory firstEscrow;
        // mocknft.mint(firstEscrow.seller,1);

        firstEscrow.buyer = address(0xabc);
        firstEscrow.seller = address(0xbac);
        firstEscrow.asset = Escrow.AssetType.Native;
        firstEscrow.amount = 50e18;
        firstEscrow.deadline = block.timestamp + 30 days;
        firstEscrow.arbitratorFee = 1e18;
        firstEscrow.buyerConfirm = false;
        firstEscrow.sellerConfirm = false;
        firstEscrow.status = Escrow.EscrowStatus.NONE;
        firstEscrow.nftt = Escrow.NftInfo({
            nftAddress: address(0),
            tokenId: 0 // mint a token id to seller and insert the right ID
        });
        deal(address(0xbac), 1004e18);

        vm.prank(address(0xbac));
        _id = escrow.createEscrow{value: firstEscrow.amount + firstEscrow.arbitratorFee}(firstEscrow);
    }

    function test_canCreateNativeEscrow() public {
 
        uint256 id = createNativeEscrow();

        Escrow.EscrowInfo memory firstNatEscrow = escrow.getUserEscrow(id);

        assertEq(firstNatEscrow.buyer, address(0xabc));
        assertNotEq(firstNatEscrow.deadline,0);
        assertEq(firstNatEscrow.amount, 50e18);

        
    }
}