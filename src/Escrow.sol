// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract Escrow {
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
    }

    mapping (address user => uint256 points) reputation;
    mapping (uint256 id => bool status) escrowExist;
    address[] public arbitrators;
    uint256 insurancePool;

    function createEscrow() external {}
}