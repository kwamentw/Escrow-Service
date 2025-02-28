// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";
import {MockNFT} from "./MockNft.sol";
import {console2} from "forge-std/console2.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EscrowTest is Test{
    Escrow escrow;
    MockNFT mocknft;
    address token = 0x6B175474E89094C44Da98b954EedeAC495271d0F; //usdc

    function setUp() public{
        escrow = new Escrow(address(this),token);
        mocknft = new MockNFT();
    }

    function createNativeEscrow() public payable returns(uint256 _id) {
        
        Escrow.EscrowInfo memory firstEscrow;

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
        deal(address(0xabc), firstEscrow.amount + firstEscrow.arbitratorFee);

        vm.prank(address(0xabc));
        _id = escrow.createEscrow{value: firstEscrow.amount + firstEscrow.arbitratorFee}(firstEscrow);
    }

        function createERC20Escrow() public payable returns(uint256 _id) {
        
        Escrow.EscrowInfo memory firstEscrow;

        firstEscrow.buyer = address(0xabc);
        firstEscrow.seller = address(0xbac);
        firstEscrow.asset = Escrow.AssetType.ERC20;
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
        // deal(address(0xbac), 1004e18);
        deal(address(token), address(0xabc), 10000e18);

        vm.prank(address(0xabc));
        IERC20(token).approve(address(escrow), type(uint256).max);

        vm.prank(address(0xabc));
        _id = escrow.createEscrow(firstEscrow);
    }

    function createNftEscrow() public returns(uint256 id){
        Escrow.EscrowInfo memory firstEscrow;
        mocknft.mint(address(0xbac),2223);

        firstEscrow.buyer = address(0xabc);
        firstEscrow.seller = address(0xbac);
        firstEscrow.asset = Escrow.AssetType.ERC721;
        firstEscrow.amount = 0;
        firstEscrow.deadline = block.timestamp + 30 days;
        firstEscrow.arbitratorFee = 0.001e18;
        firstEscrow.buyerConfirm = false;
        firstEscrow.sellerConfirm = false;
        firstEscrow.status = Escrow.EscrowStatus.NONE;
        firstEscrow.nftt = Escrow.NftInfo({
            nftAddress: address(mocknft),
            tokenId: 2223 // mint a token id to seller and insert the right ID
        });
        deal(address(0xabc), 1004e18);

        vm.prank(address(0xabc));
        IERC721(mocknft).approve(address(escrow), 2223);

        vm.prank(address(0xabc));
        id = escrow.create721Escrow(firstEscrow);
    }


    function test_canCreateNativeEscrow() public {
 
        uint256 id = createNativeEscrow();

        Escrow.EscrowInfo memory firstNatEscrow = escrow.getUserEscrow(id);

        assertEq(firstNatEscrow.buyer, address(0xabc));
        assertNotEq(firstNatEscrow.deadline,0);
        assertEq(firstNatEscrow.amount, 50e18);
        //todo: should add a balance check

        
    }

    function testCanCreateE20Escrow() public{
        uint256 id = createERC20Escrow();

        Escrow.EscrowInfo memory firstERC20Escrow = escrow.getUserEscrow(id);

        assertEq(firstERC20Escrow.buyer, address(0xabc));
        assertNotEq(firstERC20Escrow.deadline,0);
        assertNotEq(firstERC20Escrow.seller, address(0));
        assertEq(firstERC20Escrow.amount, 50e18);
        assertEq(IERC20(token).balanceOf(address(escrow)), 50e18 + firstERC20Escrow.arbitratorFee );
    }

    // function testCanCreate721Escrow() public{
    //     uint256 id = createNftEscrow();

    // }

    function testConfirmEscrow() public{
        uint256 id = createNativeEscrow();

        Escrow.EscrowInfo memory esscrow = escrow.getUserEscrow(id);

        address seller = esscrow.seller;
        address buyer = esscrow.buyer;

        vm.prank(seller);
        escrow.confirmEscrow(id);

        vm.prank(buyer);
        escrow.confirmEscrow(id);

        assertTrue(escrow.getUserEscrow(id).sellerConfirm);
        assertTrue(escrow.getUserEscrow(id).buyerConfirm);
    }

    function testRevertIfCallerisNotSellerorBuyer() public{
        uint256 id = createNativeEscrow();
        Escrow.EscrowInfo memory esscrow = escrow.getUserEscrow(id);

        address seller = esscrow.seller;
        address buyer = esscrow.buyer;
        address sender = address(4444);

        assertNotEq(sender,buyer);
        assertNotEq(sender,seller);

        vm.expectRevert();
        vm.prank(sender);
        escrow.confirmEscrow(id);

    }

    function testAddArbitrator() public{
        address newArbitrator = address(0xabccc);
        escrow.addArbitrator(newArbitrator);

        assertTrue(escrow.getArbitratorStatus(newArbitrator));
    }

    function testRevertIfArbitratorAlreadyExists() public{
        address arbOne = address(0xabccc);
        escrow.addArbitrator(arbOne);

        vm.expectRevert();
        escrow.addArbitrator(arbOne);
    }

    function testRefundEscrow() public{
        uint256 id = createNativeEscrow();
        vm.warp(32 days);

        escrow.addArbitrator(address(0xfff));

        uint256 balBefore = address(0xabc).balance;

        vm.prank(address(0xfff));
        escrow.refundEscrow(id);
        
        uint256 balAfter = address(0xabc).balance;

        assertGt(balAfter, balBefore);
        assertGt(address(0xfff).balance, 0);

        bool refund;
        if(escrow.getUserEscrow(id).status == Escrow.EscrowStatus.REFUNDED){ refund = true;}
        assertTrue(refund);
    }


    function testCannotRefundEscrow() public{}

    function testReleaseEcrow() public{
        uint256 id = createNativeEscrow();
        vm.warp(20 days);

        vm.prank(address(0xabc));
        escrow.confirmEscrow(id);

        vm.prank(address(0xbac));
        escrow.confirmEscrow(id);

        escrow.addArbitrator(address(0xfff));

        uint256 balbef = address(0xbac).balance;

        vm.prank(address(0xfff));
        escrow.releaseEscrow(id);

        uint256 balAfter = address(0xbac).balance;

        assertGt(balAfter,balbef);
        bool released;
        if(escrow.getUserEscrow(id).status == Escrow.EscrowStatus.SETTLED){released = true;}
        assertTrue(released);
    }

    function testCannotReleaseEscrow() public{}
}