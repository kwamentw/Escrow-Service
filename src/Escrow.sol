// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract Escrow {
    event ArbitratorAdded(address newArb);
    enum AssetType{ERC20, ERC721, Native}
    enum EscrowStatus{NONE, SETTLED, UNSETTLED}

    uint256 id = 0;

    struct EscrowInfo {
        address buyer;
        address seller;
        AssetType asset;
        uint256 amount;
        uint256 deadline;
        bool buyerConfirm;
        bool sellerConfirm;
        EscrowStatus status;
        //maybe add param for nft
    }

    mapping (address user => uint256 points) reputation;
    mapping (uint256 id => EscrowInfo escrow) escrows;
    mapping (address user => bool status) arbitrators;
    uint256 insurancePool;

    function createEscrow(EscrowInfo memory newEscrow) external  payable {
        require(escrows[id].buyer == address(0));
        require(newEscrow.buyer != address(0));
        require(newEscrow.seller != address(0));
        require(newEscrow.amount > 0);
        require(newEscrow.deadline > block.timestamp);
        require(newEscrow.status == EscrowStatus.NONE);

        if(newEscrow.asset == AssetType.ERC20){
            //SafeErc20.transferFrom(msg.sender,address(this),newEscrow.amount)
            escrows[id] = newEscrow;
            
        }else if(newEscrow.asset == AssetType.Native){
            require(msg.value == newEscrow.amount);
            escrows[id] = newEscrow;
        }else{
            //SafeERC721.transferFrom(msg.sender,address(this),newEscrow.amount);
            //write logic to transfer the nft
        }

        id++;
        
    }

    function addArbitrator(address newArbitrator) external {
        require(arbitrators[newArbitrator]== false, "already an arbitrator");
        arbitrators[newArbitrator] = true;
        emit ArbitratorAdded(newArbitrator);
    }
}