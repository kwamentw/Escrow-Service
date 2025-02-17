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

    uint256 id; // escrow starting ID

    /**
     * Details / configuration information of the escrow.
     */
    struct EscrowInfo {
        address buyer;
        address seller;
        AssetType asset;
        uint256 amount;
        uint256 deadline;
        uint256 arbitratorFee;
        bool buyerConfirm;
        bool sellerConfirm;
        EscrowStatus status;
        NftInfo nftt;
    }

    struct NftInfo{
        address nftAddress;
        uint256 tokenId;
    }

    // mappings
    mapping (address user => uint256 id) userToActivEscrow;
    mapping (uint256 id => EscrowInfo escrow) escrows;
    mapping (address user => bool status) arbitrators;

    // storage vars
    uint256 immutable BASIS_POINT = 1e4;
    address owner; //owner of contract
    IERC20 token; //I think we'll fuck with usdc for now 
    uint32 arbitratorFeeBPS; //it will 200BPS of every deposit
    uint256 arbitratorFeeForNFT; // fee charged in native currency for every deposit

    constructor(address _owner, address _token){
        owner = _owner;
        token = IERC20(_token);
        arbitratorFeeBPS = 200;
        arbitratorFeeForNFT = 0.001e18;
        id = 1;
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
        require(newEscrow.nftt.nftAddress != address(0));

        userToActivEscrow[msg.sender] = id;
        uint256 arbitratorFee = arbitratorFeeBPS * newEscrow.amount / BASIS_POINT;

        if(newEscrow.asset == AssetType.ERC20){
            if(token.balanceOf(msg.sender) < newEscrow.amount + arbitratorFee){ revert("Not Enough Funds"); }
            token.safeTransferFrom(msg.sender,address(this), newEscrow.amount);
            token.safeTransferFrom(msg.sender, address(this), arbitratorFee);
            newEscrow.arbitratorFee = arbitratorFee;
            escrows[id] = newEscrow;
            
        }else if(newEscrow.asset == AssetType.Native){
            require(msg.value == newEscrow.amount + arbitratorFee);
            newEscrow.arbitratorFee = arbitratorFee;
            escrows[id] = newEscrow;
        }else if(newEscrow.asset == AssetType.ERC721){
            require(msg.value == arbitratorFeeForNFT, "arbitrator Fees not paid");
            address nftcontract = newEscrow.nftt.nftAddress;
            uint256 tokenID = newEscrow.nftt.tokenId;
            require(IERC721(nftcontract).ownerOf(tokenID)==newEscrow.seller,"Trying to sell what is not yours");
            IERC721(nftcontract).safeTransferFrom(msg.sender,address(this),tokenID);
            newEscrow.arbitratorFee = arbitratorFeeForNFT;
            escrows[id] = newEscrow;
        }

        id++;

        uint256 currentId = id-1;
        emit EscrowCreated(currentId);

        return(currentId);
        
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

        uint256 fee = escrows[_id].arbitratorFee;
        escrows[_id].amount = 0;

        if(escrows[_id].asset == AssetType.ERC20){
            if(token.balanceOf(address(this))<escrows[_id].amount + fee){
                revert("Insufficient balance");
            }
            token.safeTransferFrom(address(this), msg.sender, fee);
            token.safeTransferFrom(address(this), escrows[_id].seller, escrows[_id].amount);

        }else if(escrows[_id].asset == AssetType.ERC721){
            address nftContract = escrows[_id].nftt.nftAddress;
            uint256 tokenID = escrows[_id].nftt.tokenId;
            (bool okay, )=payable(msg.sender).call{value: fee}("");
            require(okay);
            IERC721(nftContract).safeTransferFrom(address(this), escrows[_id].buyer, tokenID);

        }else if(escrows[_id].asset == AssetType.Native){
            (bool okay, )=payable(msg.sender).call{value: fee}("");
            require(okay);

            (bool ok, )=payable(escrows[_id].seller).call{value: escrows[_id].amount}("");
            require(ok);
        }

        escrows[_id].amount = 0;
        userToActivEscrow[msg.sender] = 0;
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
            address nftContract = escrows[idd].nftt.nftAddress;
            uint256 tokenID = escrows[idd].nftt.tokenId;
            IERC721(nftContract).safeTransferFrom(address(this), escrows[idd].buyer, tokenID);

            (bool okay,) = payable(msg.sender).call{value: arbitratorFeeForNFT}("");
            require(okay, "TXN FAILED");
            delete escrows[idd].nftt;
            escrows[idd].status= EscrowStatus.SETTLED;
        }

        userToActivEscrow[msg.sender] = 0;
        emit EscrowReleased(idd,amount);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external view returns(bytes4){
        require(userToActivEscrow[operator] != 0, "Nft can only be sent by the seller");
        uint256 escrowId = userToActivEscrow[operator];
        require(escrows[escrowId].nftt.tokenId == tokenId, " User trying to send a different token");
        return this.onERC721Received.selector;
    }
}