// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * @title ESCROW
 * @author 4B
 * @notice Standard escrow contract
 */
contract Escrow {

    event ArbitratorAdded(address newArb);
    event EscrowCreated(uint256 id);
    event EscrowRefunded(uint256 id);
    event EscrowReleased(uint256 id, uint256 amount);

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
    address owner;

    constructor(address _owner){
        owner = _owner;
    }

    modifier onlyArbitrator(address sender) {
        require(arbitrators[sender]== true,"Not arbitrator");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Not Authorised");
        _;
    }

    function createEscrow(EscrowInfo memory newEscrow) external  payable returns(uint256){
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

        return(id-1);
        
    }

    function confirmEscrow(uint256 _id) external {
        require(escrows[_id].deadline >= block.timestamp);
        require(msg.sender == escrows[_id].seller || msg.sender == escrows[_id].buyer);
        if(msg.sender == escrows[_id].seller){
            escrows[_id].sellerConfirm = true;
        }else{
            escrows[_id].buyerConfirm = true;
        }
    }

    function addArbitrator(address newArbitrator) external onlyOwner {
        require(arbitrators[newArbitrator]== false, "already an arbitrator");
        arbitrators[newArbitrator] = true;
        emit ArbitratorAdded(newArbitrator);
    }

    function refundEscrow(uint256 _id) external onlyArbitrator(msg.sender){
        require(escrows[_id].deadline < block.timestamp,"Pending duration not expired");
        require(escrows[_id].sellerConfirm == false || escrows[_id].buyerConfirm == false, "Disagreement");
        if(escrows[_id].asset == AssetType.ERC20){
            //erc20 transfer logic
            //transferFrom(address(this), escrowSender);
        }else if(escrows[_id].asset == AssetType.ERC721){
            //nft transfer logic
            //transferFrom(address(this), escrowSender);
        }else{
            (bool ok, )=payable(escrows[_id].seller).call{value: escrows[_id].amount}("");
            require(ok);
        }

        escrows[_id].amount = 0;

        emit EscrowRefunded(_id);

    }

    function releaseEscrow() external onlyArbitrator(msg.sender){
        //a percentage of the escrow must go to the contract for maintenance
        // check whether buyer and seller has confirmed
        // send tokens to receiver but check which token type before

    }
}