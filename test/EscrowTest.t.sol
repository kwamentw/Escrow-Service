// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

///// imports

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";
import {MockNFT} from "./MockNft.sol";
import {console2} from "forge-std/console2.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * A TEST SUIT FOR ESCROW.SOL
 */
contract EscrowTest is Test{

    using SafeERC20 for IERC20;

    // Escrow contract
    Escrow escrow;
    // NFT contract
    MockNFT mocknft;
    // USDC - ERC20 used with this escrow
    address token = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function setUp() public{
        escrow = new Escrow(address(this),token);
        mocknft = new MockNFT();
    }

    /////////////////////////////////////////////////////////////////////////////////
    ////////////////////// CREATE ESCROW HELPER FUNCTIONS ///////////////////////////
    /////////////////////////////////////////////////////////////////////////////////

    /**
     * Helper function to create eth escrow 
     */
    function createNativeEscrow() public payable returns(uint256 _id) {
        
        Escrow.EscrowInfo memory firstEscrow;

        firstEscrow.depositor = address(0xabc);
        firstEscrow.receiver = address(0xbac);
        firstEscrow.asset = Escrow.AssetType.Native;
        firstEscrow.amount = 50e18;
        firstEscrow.deadline = block.timestamp + 30 days;
        firstEscrow.arbitratorFee = 1e18;
        firstEscrow.depositorConfirm = false;
        firstEscrow.receiverConfirm = false;
        firstEscrow.status = Escrow.EscrowStatus.NONE;
        firstEscrow.nftAddress = address(0);
        firstEscrow.tokenId = 0;

        deal(address(0xabc), firstEscrow.amount + firstEscrow.arbitratorFee);

        vm.prank(address(0xabc));
        _id = escrow.createEscrow{value: firstEscrow.amount + firstEscrow.arbitratorFee}(firstEscrow);
    }

    /**
     * Helper function to create ERC20 escrow 
     */
    function createERC20Escrow() public payable returns(uint256 _id) {
        
        Escrow.EscrowInfo memory firstEscrow;

        firstEscrow.depositor = address(0xabc);
        firstEscrow.receiver = address(0xbac);
        firstEscrow.asset = Escrow.AssetType.ERC20;
        firstEscrow.amount = 50e18;
        firstEscrow.deadline = block.timestamp + 30 days;
        firstEscrow.arbitratorFee = 1e18;
        firstEscrow.depositorConfirm = false;
        firstEscrow.receiverConfirm = false;
        firstEscrow.status = Escrow.EscrowStatus.NONE;
        firstEscrow.nftAddress = address(0);
        firstEscrow.tokenId = 0;

        deal(address(token), address(0xabc), 10000e18);

        vm.prank(address(0xabc));
        IERC20(token).approve(address(escrow), type(uint256).max);

        vm.prank(address(0xabc));
        _id = escrow.createEscrow(firstEscrow);
    }

    /**
     * Helper function to create NFT escrow
     */
    function createNftEscrow() public returns(uint256 id){
        Escrow.EscrowInfo memory firstEscrow;
        mocknft.mint(address(0xabc),2223);

        firstEscrow.depositor = address(0xabc);
        firstEscrow.receiver = address(0xbac);
        firstEscrow.asset = Escrow.AssetType.ERC721;
        firstEscrow.amount = 0;
        firstEscrow.deadline = block.timestamp + 30 days;
        firstEscrow.arbitratorFee = 0.001e18;
        firstEscrow.depositorConfirm = false;
        firstEscrow.receiverConfirm = false;
        firstEscrow.status = Escrow.EscrowStatus.NONE;
        firstEscrow.nftAddress = address(mocknft);
        firstEscrow.tokenId = 2223;
        deal(address(0xabc), 1004e18);

        vm.prank(address(0xabc));
        IERC721(mocknft).approve(address(escrow), 2223);

        vm.prank(address(0xabc));
        id = escrow.create721Escrow{value: 0.001e18}(firstEscrow);
    }

    ///////////////////////////////////////////////////////////////////////////////
    ////////////////////// CREATE ESCROW TEST FUNCTIONS ///////////////////////////
    ///////////////////////////////////////////////////////////////////////////////

    function testCanCreateDiffTypOfEscrowAtOnce() public{
        uint256 id = createNativeEscrow();
        uint256 id2 = createERC20Escrow();
        uint256 id3 = createNftEscrow();

        Escrow.EscrowInfo memory nativeEscrow = escrow.getUserEscrow(id);
        Escrow.EscrowInfo memory erc20Escrow = escrow.getUserEscrow(id2);
        Escrow.EscrowInfo memory nftEscrow = escrow.getUserEscrow(id3);

        assertNotEq(nativeEscrow.receiver, address(0));
        assertNotEq(erc20Escrow.receiver, address(0));
        assertNotEq(nftEscrow.receiver, address(0));

        assertGt(nativeEscrow.amount, 0);
        assertGt(erc20Escrow.amount, 0);
        assertEq(nftEscrow.amount, 0);

        assertNotEq(nftEscrow.nftAddress, address(0));

        assertGt(nativeEscrow.deadline, 0);
        assertGt(erc20Escrow.deadline, 0);
        assertGt(nftEscrow.deadline,0);
    }

    function testCanCreateMultipleNativeEscrows() public {
        uint256 id = createNativeEscrow();
        uint256 id2 = createNativeEscrow();
        uint256 id3 = createNativeEscrow();

        console2.log(id, id2, id3);
    }

    function testCanCreateMultiE20Escrws() public{
        uint256 id2 = createERC20Escrow();
        uint256 id4 = createERC20Escrow();
        uint256 id8 = createERC20Escrow();

        console2.log(id2, id4, id8);
    }
    function testCanCreateMultiNftEscrws() public {
        uint256 id3 = createNftEscrow();
        uint256 id8 = createNftEscrow();
        uint256 id4 = createNftEscrow();

        console2.log(id3, id4, id8);
    }

    function testCanCreateE20Escrow() public{
        uint256 id = createERC20Escrow();

        Escrow.EscrowInfo memory firstERC20Escrow = escrow.getUserEscrow(id);

        assertEq(firstERC20Escrow.depositor, address(0xabc));
        assertNotEq(firstERC20Escrow.deadline,0);
        assertNotEq(firstERC20Escrow.receiver, address(0));
        assertEq(firstERC20Escrow.amount, 50e18);
        assertEq(IERC20(token).balanceOf(address(escrow)), 50e18 + firstERC20Escrow.arbitratorFee );
    }

    function testCanCreate721Escrow() public{
        uint256 id = createNftEscrow();

        Escrow.EscrowInfo memory firstNftEscrow = escrow.getUserEscrow(id);

        assertEq(IERC721(mocknft).balanceOf(address(escrow)),1);
        assertEq(IERC721(mocknft).ownerOf(firstNftEscrow.tokenId), address(escrow));
        assertNotEq(firstNftEscrow.nftAddress, address(0));

    }

    function testCanCreateNativeEscrow() public {
 
        uint256 id = createNativeEscrow();

        Escrow.EscrowInfo memory firstNatEscrow = escrow.getUserEscrow(id);

        assertEq(firstNatEscrow.depositor, address(0xabc));
        assertNotEq(firstNatEscrow.deadline,0);
        assertEq(firstNatEscrow.amount, 50e18);
        //todo: should add a balance check 
    }

    ////////////////////////////////////////////////////////////////////////
    ////////////////////// REFUND TEST FUNCTIONS ///////////////////////////
    ////////////////////////////////////////////////////////////////////////

    function testRefundE20Escrow() public{
        uint256 id = createERC20Escrow();
        Escrow.EscrowInfo memory firstERC20Escrow = escrow.getUserEscrow(id);

        vm.prank(firstERC20Escrow.receiver);
        escrow.confirmEscrow(id);

        escrow.addArbitrator(address(0xFFF));

        uint256 balBefore = IERC20(token).balanceOf(address(0xabc));
        
        vm.prank(address(0xFFF));
        vm.warp(40 days);
        escrow.refundEscrow(id);

        uint256 balAfter = IERC20(token).balanceOf(address(0xabc));

        assertGt(balAfter, balBefore);
        assertTrue(escrow.getUserEscrow(id).status == Escrow.EscrowStatus.REFUNDED);
    }
    

    function testRevertRefundDueToAgreement() public{
        uint256 id = createERC20Escrow();
        Escrow.EscrowInfo memory firstERC20Escrow = escrow.getUserEscrow(id);

        vm.prank(firstERC20Escrow.receiver);
        escrow.confirmEscrow(id);

        vm.prank(firstERC20Escrow.depositor);
        escrow.confirmEscrow(id);

        escrow.addArbitrator(address(0xFFF));
        
        vm.warp(block.timestamp + 40 days);
        // vm.roll(100);
        vm.prank(address(0xFFF));
        escrow.refundEscrow(id); /// should revert cos both parties have agreed
    }
    

    function testRevertRefundDueToDeadline() public{
        uint256 id = createERC20Escrow();

        escrow.addArbitrator(address(0xFFF));

        vm.prank(address(0xFFF));
        escrow.refundEscrow(id); //escrow will revert because there is deadline has not reached
    }

    function testCanRefund721() public{
        uint256 id = createNftEscrow();

        Escrow.EscrowInfo memory firstNftEscrow = escrow.getUserEscrow(id);

        assertEq(IERC721(mocknft).ownerOf(firstNftEscrow.tokenId), address(escrow));

        // we have to make sure only one party confirms

        vm.prank(firstNftEscrow.depositor);
        escrow.confirmEscrow(id);

        escrow.addArbitrator(address(0xfff));

        vm.warp(32 days);
        vm.prank(address(0xfff));
        escrow.refundEscrow(id);

        assertEq(IERC721(mocknft).ownerOf(firstNftEscrow.tokenId), firstNftEscrow.depositor);
        assertTrue(escrow.getUserEscrow(id).status == Escrow.EscrowStatus.REFUNDED);
    }

    function testRevert721RefundDueToConfirm() public{
        uint256 id = createNftEscrow();

        Escrow.EscrowInfo memory firstNftEscrow = escrow.getUserEscrow(id);

        vm.prank(firstNftEscrow.depositor);
        escrow.confirmEscrow(id);

        vm.prank(firstNftEscrow.receiver);
        escrow.confirmEscrow(id);

        escrow.addArbitrator(address(0xccc));

        vm.warp(32 days);

        vm.expectRevert();
        vm.prank(address(0xccc));
        escrow.refundEscrow(id);
    }

    function testRevertRefund721DueToDeadline() public{
        uint256 id = createNftEscrow();

        Escrow.EscrowInfo memory firstNftEscrow = escrow.getUserEscrow(id);

        // simulate that only one party has agreed and the arbitrator is trying to refund
        vm.prank(firstNftEscrow.receiver);
        escrow.confirmEscrow(id);

        escrow.addArbitrator(address(0xccc));

        //There will be a revert because the agreed time for the escrow to run has not been reached

        vm.expectRevert();
        vm.prank(address(0xccc));
        escrow.refundEscrow(id);
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


    function testCannotRefundDeadlineHasntReached() public{
        uint256 id = createNativeEscrow();
        vm.warp(5 days);

        escrow.addArbitrator(address(0xfff));

        vm.expectRevert();
        vm.prank(address(0xfff));
        escrow.refundEscrow(id);
    }

    function testRevertRefundIfAllUsersConfirm() public{
        uint256 id = createNativeEscrow();
        vm.warp(3 days);

        escrow.addArbitrator(address(0xfff));

        vm.prank(address(0xabc));
        escrow.confirmEscrow(id);

        vm.prank(address(0xbac));
        escrow.confirmEscrow(id);

        vm.warp(33 days);

        vm.expectRevert();
        vm.prank(address(0xfff));
        escrow.refundEscrow(id);
    }

    function testRevertRefundNotArbitrator() public{
        uint256 id = createNativeEscrow();
        vm.warp(3 days);

        vm.prank(address(0xabc));
        escrow.confirmEscrow(id);

        vm.warp(33 days);

        vm.expectRevert(); // expert to refund not arbitrator
        escrow.refundEscrow(id);
    }

    function testRevertAlreadyRefunded() public{

        uint256 id = createNativeEscrow();
        vm.warp(32 days);

        escrow.addArbitrator(address(0xfff));

        vm.prank(address(0xfff));
        escrow.refundEscrow(id);

        vm.expectRevert(); // it will will revert wil "alreadyRefunded" hence test passing
        vm.prank(address(0xfff));
        escrow.refundEscrow(id);

    }

    /////////////////////////////////////////////////////////////////////////
    ////////////////////// RELEASE TEST FUNCTIONS ///////////////////////////
    /////////////////////////////////////////////////////////////////////////
    
    function testReleaseE20Escrow() public{
        uint256 id = createERC20Escrow();
        Escrow.EscrowInfo memory firstERC20Escrow = escrow.getUserEscrow(id);

        vm.prank(firstERC20Escrow.receiver);
        escrow.confirmEscrow(id);

        vm.prank(firstERC20Escrow.depositor);
        escrow.confirmEscrow(id);

        uint256 balBefore = IERC20(token).balanceOf(firstERC20Escrow.receiver);

        escrow.addArbitrator(address(0xFFF));

        vm.prank(address(0xFFF));
        escrow.releaseEscrow(id);

        uint256 balAfter = IERC20(token).balanceOf(firstERC20Escrow.receiver);

        assertGt(balAfter, balBefore);
        assertTrue(escrow.getUserEscrow(id).status == Escrow.EscrowStatus.SETTLED);
    }

    function testRevertReleaseE20() public{
        uint256 id = createERC20Escrow();
        Escrow.EscrowInfo memory firstERC20Escrow = escrow.getUserEscrow(id);

        // only one party confirms
        vm.prank(firstERC20Escrow.receiver);
        escrow.confirmEscrow(id);

        // adding arbitrator that will call the release
        escrow.addArbitrator(address(0xFFF));

        // arbitrator was lured to release funds
        vm.prank(address(address(0xFFF)));
        // But this will regret because all parties have not confirmed
        vm.expectRevert();
        escrow.releaseEscrow(id);
    }

    function testCanRelease721() public{
        uint256 id = createNftEscrow();

        Escrow.EscrowInfo memory firstNftEscrow = escrow.getUserEscrow(id);

        assertEq(IERC721(mocknft).ownerOf(firstNftEscrow.tokenId), address(escrow));

        vm.prank(firstNftEscrow.depositor);
        escrow.confirmEscrow(id);

        vm.prank(firstNftEscrow.receiver);
        escrow.confirmEscrow(id);

        escrow.addArbitrator(address(0xccc));

        vm.prank(address(0xccc));
        escrow.releaseEscrow(id);

        assertEq(IERC721(mocknft).ownerOf(firstNftEscrow.tokenId), firstNftEscrow.receiver);
        assertTrue(escrow.getUserEscrow(id).status == Escrow.EscrowStatus.SETTLED);
    }

    function testRevertWhenReleasing721DueToDisagreement() public{
        uint256 id = createNftEscrow();

        Escrow.EscrowInfo memory firstNftEscrow = escrow.getUserEscrow(id);

        // let's assume only the receiver agrees 
        vm.prank(firstNftEscrow.receiver);
        escrow.confirmEscrow(id);

        //add arbitrator who will call the release
        escrow.addArbitrator(address(0xCCC));

        vm.expectRevert();
        vm.prank(address(0xCCC));
        escrow.releaseEscrow(id);
    }

    function testReleaseEscrow() public{
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

    function testCannotReleaseEscrow() public{
        uint256 id= createNativeEscrow();
        vm.warp(20 days);

        vm.prank(address(0xabc));
        escrow.confirmEscrow(id);

        // lets make only one user confirm to trigger the error

        escrow.addArbitrator(address(0xfff));

        vm.expectRevert();
        vm.prank(address(0xfff));
        escrow.releaseEscrow(id);
    }

    /////////////////////////////////////////////////////////////////////////
    ////////////////////// CONFIRM TEST FUNCTIONS ///////////////////////////
    /////////////////////////////////////////////////////////////////////////

    function testConfirmEscrow() public{
        uint256 id = createNativeEscrow();

        Escrow.EscrowInfo memory esscrow = escrow.getUserEscrow(id);

        address receiver = esscrow.receiver;
        address depositor = esscrow.depositor;

        vm.prank(receiver);
        escrow.confirmEscrow(id);

        vm.prank(depositor);
        escrow.confirmEscrow(id);

        assertTrue(escrow.getUserEscrow(id).receiverConfirm);
        assertTrue(escrow.getUserEscrow(id).depositorConfirm);
    }

    function testRevertConfirmationDeadlineReached() public{
        uint256 id = createNativeEscrow();

        Escrow.EscrowInfo memory escrowCon = escrow.getUserEscrow(id);

        //receiver confirms

        vm.prank(escrowCon.receiver);
        escrow.confirmEscrow(id);

        // depositor will not be able to confirm because deadline has reached
        vm.warp(44 days);

        vm.expectRevert();
        vm.prank(escrowCon.depositor);
        escrow.confirmEscrow(id);
    }

    function testRevertConfirmCallerisNotReceiverorDepositor() public{
        uint256 id = createNativeEscrow();
        Escrow.EscrowInfo memory esscrow = escrow.getUserEscrow(id);

        address receiver = esscrow.receiver;
        address depositor = esscrow.depositor;
        address sender = address(4444);

        assertNotEq(sender,depositor);
        assertNotEq(sender,receiver);

        vm.expectRevert();
        vm.prank(sender);
        escrow.confirmEscrow(id);

    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////// ARBITRATOR TEST FUNCTIONS ///////////////////////////
    ////////////////////////////////////////////////////////////////////////////

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

    ///////////////////////////////////////////////////////////////////////
    ////////////////////// OTHER TEST FUNCTIONS ///////////////////////////
    ///////////////////////////////////////////////////////////////////////

    /**
     * Random addresses should not be able to send Nfts to this contract
     * it should revert with [FAIL: revert: Nft can only be sent by the depositor]
     * Anytime senders are not trying to use the protocol
     */
    function testNftDepositRevert() public{
        mocknft.mint(address(0xddd), 222);

        vm.prank(address(0xddd));
        IERC721(mocknft).approve(address(this), 222);

        IERC721(mocknft).safeTransferFrom(address(0xddd), address(escrow), 222);
    }


    function testRevertReleaseLockedTkns() public{
        address unAcceptedToken = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        deal(unAcceptedToken, address(0xDDD), 10e18);

        //SHOULD EXPECT A NOT AUTHORISED REVERT
        vm.expectRevert();
        
        vm.prank(address(0xFFF));
        escrow.releaseLockedTkns(unAcceptedToken);
    }

    ////////////////////////////////////////////////////////////////////////
    //////////////////////     FUZZING TEST      ///////////////////////////
    ////////////////////////////////////////////////////////////////////////

    function testFuzzCreateNativeEscrow(uint256 amount) public {
        // vm.assume(amount <= type(uint128).max);

        amount = bound(amount, 1, type(uint128).max);
        
        Escrow.EscrowInfo memory firstEscrow;

        uint256 arbitratorFee = 200 * amount / 1e4;

        firstEscrow.depositor = address(0xabc);
        firstEscrow.receiver = address(0xbac);
        firstEscrow.asset = Escrow.AssetType.Native;
        firstEscrow.amount = amount;
        firstEscrow.deadline = block.timestamp + 30 days;
        firstEscrow.arbitratorFee = arbitratorFee;
        firstEscrow.depositorConfirm = false;
        firstEscrow.receiverConfirm = false;
        firstEscrow.status = Escrow.EscrowStatus.NONE;
        firstEscrow.nftAddress = address(0);
        firstEscrow.tokenId = 0;

        deal(address(0xabc), amount + arbitratorFee);

        vm.prank(address(0xabc));
        uint256 _id = escrow.createEscrow{value: amount + arbitratorFee}(firstEscrow);
    }

    function testFuzzCreateE20Escrow(uint256 amount) public{

        Escrow.EscrowInfo memory firstEscrow;

        amount = bound(amount, 1, type(uint128).max);

        uint256 arbitratorFee = 200 * amount / 1e4;

        firstEscrow.depositor = address(0xabc);
        firstEscrow.receiver = address(0xbac);
        firstEscrow.asset = Escrow.AssetType.ERC20;
        firstEscrow.amount = amount;
        firstEscrow.deadline = block.timestamp + 30 days;
        firstEscrow.arbitratorFee = arbitratorFee;
        firstEscrow.depositorConfirm = false;
        firstEscrow.receiverConfirm = false;
        firstEscrow.status = Escrow.EscrowStatus.NONE;
        firstEscrow.nftAddress = address(0);
        firstEscrow.tokenId = 0;

        deal(address(token), address(0xabc), amount + arbitratorFee);

        vm.prank(address(0xabc));
        IERC20(token).approve(address(escrow), type(uint256).max);

        vm.prank(address(0xabc));
        uint256 _id = escrow.createEscrow(firstEscrow);
    }

    function testFuzzCreateNFTEscrow(uint256 id) public {
        Escrow.EscrowInfo memory firstEscrow;
        mocknft.mint(address(0xabc),id);

        firstEscrow.depositor = address(0xabc);
        firstEscrow.receiver = address(0xbac);
        firstEscrow.asset = Escrow.AssetType.ERC721;
        firstEscrow.amount = 0;
        firstEscrow.deadline = block.timestamp + 30 days;
        firstEscrow.arbitratorFee = 0.001e18;
        firstEscrow.depositorConfirm = false;
        firstEscrow.receiverConfirm = false;
        firstEscrow.status = Escrow.EscrowStatus.NONE;
        firstEscrow.nftAddress = address(mocknft);
        firstEscrow.tokenId = id;
        deal(address(0xabc), 1004e18);

        vm.prank(address(0xabc));
        IERC721(mocknft).approve(address(escrow), id);

        vm.prank(address(0xabc));
        id = escrow.create721Escrow{value: 0.001e18}(firstEscrow);
    }
}