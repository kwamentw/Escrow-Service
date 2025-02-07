// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract Escrow {
    event ArbitratorAdded(address newArb);
    enum AssetType{ERC20, ERC721, Native}
    enum EscrowStatus{NONE, SETTLED, UNSETTLED}

    struct EscrowInfo {
        uint256 id;
        address buyer;
        address seller;
        AssetType asset;
        uint256 amount;
        uint256 deadline;
        bool buyerConfirm;
        bool sellerConfirm;
        EscrowStatus status;
    }

    mapping (address user => uint256 points) reputation;
    mapping (uint256 id => EscrowInfo escrow) escrows;
    mapping (address user => bool status) arbitrators;
    uint256 insurancePool;

    function createEscrow(EscrowInfo memory newEscrow) external {
        require(newEscrow.buyer == address(0));
        require(newEscrow.status == EscrowStatus.NONE);
    }

    function addArbitrator(address newArbitrator) external {
        require(arbitrators[newArbitrator]== false, "already an arbitrator");
        arbitrators[newArbitrator] = true;
        emit ArbitratorAdded(newArbitrator);
    }
}