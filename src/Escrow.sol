// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title ESCROW
 * @author 4B
 * @notice Standard escrow contract
 */
contract Escrow {
    using SafeERC20 for IERC20;

    // events
    event ArbitratorAdded(address newArb);
    event EscrowCreated(uint256 id);
    event EscrowRefunded(uint256 id);
    event EscrowReleased(uint256 id, uint256 amount);

    // enum
    enum AssetType{ERC20, ERC721, Native}
    enum EscrowStatus{NONE, SETTLED, REFUNDED}

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
    }

    // mapping
    mapping (address user => uint256 points) reputation;
    mapping (uint256 id => EscrowInfo escrow) escrows;
    mapping (address user => bool status) arbitrators;

    //storage var
    uint256 insurancePool; // i think we should make this var a fee for every txn
    address owner;// owner of contract
    IERC20 token; // I think we'll fuck with usdc for now 
    address arbitratorFeeBPS = 200; // it will 200BPS of every deposit

    constructor(address _owner, address _token){
        owner = _owner;
        token = IERC20(_token);
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
            if(token.balanceOf(msg.sender) < newEscrow.amount){ revert("Not Enough Funds"); }
            token.safeTransferFrom(msg.sender,address(this), newEscrow.amount);
            escrows[id] = newEscrow;
            
        }else if(newEscrow.asset == AssetType.Native){
            require(msg.value == newEscrow.amount);
            escrows[id] = newEscrow;
        }else if(newEscrow.asset == AssetType.ERC721){
            //SafeERC721.transferFrom(msg.sender,address(this),newEscrow.amount);
            //write logic to transfer the nft
        }else {
            revert("invalid asset");
        }

        id++;

        return(id-1);
        
    }

    function confirmEscrow(uint256 _id) external {
        require(escrows[_id].deadline >= block.timestamp);
        require(msg.sender == escrows[_id].seller || msg.sender == escrows[_id].buyer,"Cant call this function");
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
        require(escrows[_id].status != EscrowStatus.REFUNDED,"Escrow already refunded");
        require(escrows[_id].sellerConfirm == false || escrows[_id].buyerConfirm == false, "Disagreement");
        if(escrows[_id].asset == AssetType.ERC20){
            if(token.balanceOf(address(this))<escrows[_id].amount){
                revert("Insufficient balance");
            }
            token.safeTransfer(escrows[_id].seller, escrows[_id].amount);
        }else if(escrows[_id].asset == AssetType.ERC721){
            //nft transfer logic
            //transferFrom(address(this), escrowSender);
        }else if(escrows[_id].asset == AssetType.Native){
            (bool ok, )=payable(escrows[_id].seller).call{value: escrows[_id].amount}("");
            require(ok);
        }else{
            revert("Not a valid asset type");
        }

        escrows[_id].amount = 0;
        escrows[_id].status = EscrowStatus.REFUNDED;

        emit EscrowRefunded(_id);
    }

    function releaseEscrow(uint256 idd) external onlyArbitrator(msg.sender){
        // check whether buyer and seller has confirmed
        require(escrows[idd].sellerConfirm == true && escrows[idd].buyerConfirm == true, "Can't release escrow");
        // send tokens to receiver but check which token type before
        uint256 amount = escrows[idd].amount;
        address receiver = escrows[idd].buyer;

        if(escrows[idd].asset == AssetType.ERC20){
            if(amount > token.balanceOf(address(this))){
                revert(" Insufficient funds ");
            }
            escrows[idd].amount = 0;
            token.safeTransfer(receiver, amount);
            escrows[idd].status = EscrowStatus.SETTLED;
        }else if(escrows[idd].asset == AssetType.Native){
            if(amount<=address(this).balance){
                (bool ok, ) = payable(receiver).call{value: amount}("");
                require(ok);
            }else{
                revert("Not enough balance");
            }

            escrows[idd].amount=0;
            escrows[idd].status = EscrowStatus.SETTLED;
        }else{
            // nft transfer logic
            escrows[idd].status= EscrowStatus.SETTLED;
        }
        //a percentage of the escrow must go to the contract for maintenance

        emit EscrowReleased(idd,amount);
    }
}