// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title ESCROW
 * @author 4B
 * @notice Standard escrow contract
 */
contract Escrow{
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
        // NftInfo nftt;
        address nftAddress;
        uint256 tokenId;
    }

    /**
     * @dev Nft escrowed information
     */
    // struct NftInfo{
    //     address nftAddress;
    //     uint256 tokenId;
    // }

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

    // TODO: Change buyer and seller to depositor and receiverr to make it less confusing

    function createEscrow(EscrowInfo memory newEscrow) external  payable returns(uint256){
        require(escrows[id].buyer == address(0));
        require(newEscrow.buyer != address(0));
        require(newEscrow.seller != address(0));
        require(newEscrow.amount > 0);
        require(newEscrow.deadline > block.timestamp);
        require(newEscrow.status == EscrowStatus.NONE);
        
        userToActivEscrow[msg.sender] = id;
        uint256 arbitratorFee = arbitratorFeeBPS * newEscrow.amount / BASIS_POINT;

        if(newEscrow.asset == AssetType.ERC20){
            newEscrow.arbitratorFee = arbitratorFee;
            if(token.balanceOf(newEscrow.seller ) < newEscrow.amount + arbitratorFee){ revert("Not Enough Funds"); }
            token.safeTransferFrom(newEscrow.buyer,address(this), newEscrow.amount);
            token.safeTransferFrom(newEscrow.buyer , address(this), arbitratorFee);
            
            escrows[id] = newEscrow;
            
        }

        if(newEscrow.asset == AssetType.Native){
            require(msg.value == newEscrow.amount + arbitratorFee,"heyy");
            newEscrow.arbitratorFee = arbitratorFee;
            escrows[id] = newEscrow;
        }
        uint256 currentId = id;

        id++;

        emit EscrowCreated(currentId);

        return(currentId);
        
    }

 
    function create721Escrow(EscrowInfo memory newEscrow) external  payable returns(uint256){
        require(escrows[id].buyer == address(0),"f");
        require(newEscrow.buyer != address(0),"e");
        require(newEscrow.seller != address(0),"d");
        require(newEscrow.deadline > block.timestamp,"b");
        require(newEscrow.status == EscrowStatus.NONE,"a");
        
        userToActivEscrow[msg.sender] = id;


        if(newEscrow.asset != AssetType.ERC721){ revert ("Incorrect asset");}

        address nftcontract = newEscrow.nftAddress;
        uint256 tokenID = newEscrow.tokenId;
        require(msg.value == arbitratorFeeForNFT, "arbitrator Fees not paid");
        require(newEscrow.nftAddress != address(0),"yy");
        require(newEscrow.amount == 0, "no need to deposit tokens");
        require(IERC721(nftcontract).ownerOf(tokenID)==newEscrow.buyer,"Trying to sell what is not yours");
        IERC721(nftcontract).transferFrom(newEscrow.buyer,address(this),tokenID);
        newEscrow.arbitratorFee = arbitratorFeeForNFT;


        escrows[id] = newEscrow;

        uint256 currentId = id;

        id++;

        emit EscrowCreated(currentId);

        return(currentId);
        
    }

    function confirmEscrow(uint256 _id) external {
        require(escrows[_id].deadline >= block.timestamp,"deadline");
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
        require(escrows[_id].sellerConfirm == false || escrows[_id].buyerConfirm == false, "Two parties Have Agreed! Funds need to be released");

        uint256 fee = escrows[_id].arbitratorFee;

        if(escrows[_id].asset == AssetType.ERC20){
            if(token.balanceOf(address(this))<escrows[_id].amount + fee){
                revert("Insufficient balance");
            }
            token.safeTransferFrom(address(this), msg.sender, fee);
            token.safeTransferFrom(address(this), escrows[_id].buyer, escrows[_id].amount);

        }else if(escrows[_id].asset == AssetType.ERC721){
            address nftContract = escrows[_id].nftAddress;
            uint256 tokenID = escrows[_id].tokenId;
            (bool okay, )=payable(msg.sender).call{value: fee}("");
            require(okay);
            IERC721(nftContract).safeTransferFrom(address(this), escrows[_id].buyer, tokenID);

        }else if(escrows[_id].asset == AssetType.Native){
            (bool okay, )=payable(msg.sender).call{value: fee}("");
            require(okay);

            (bool ok, )=payable(escrows[_id].buyer).call{value: escrows[_id].amount}("");
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
        address receiver = escrows[idd].seller;

        if(escrows[idd].asset == AssetType.ERC20){
            if(amount > token.balanceOf(address(this))){
                revert(" Insufficient funds ");
            }
            escrows[idd].amount = 0;
            token.safeTransfer(receiver, amount);
        }else if(escrows[idd].asset == AssetType.Native){
            if(amount<=address(this).balance){
                (bool ok, ) = payable(receiver).call{value: amount}("");
                require(ok);
            }else{
                revert("Not enough balance");
            }
            escrows[idd].amount=0;
        }else{
            address nftContract = escrows[idd].nftAddress;
            uint256 tokenID = escrows[idd].tokenId;
            IERC721(nftContract).safeTransferFrom(address(this), escrows[idd].seller, tokenID);

            (bool okay,) = payable(msg.sender).call{value: arbitratorFeeForNFT}("");
            require(okay, "TXN FAILED");
            delete escrows[idd];
            
        }

        escrows[idd].status= EscrowStatus.SETTLED;
        userToActivEscrow[msg.sender] = 0;
        emit EscrowReleased(idd,amount);
    }

    function getEscrowId(address user) external view returns(uint256) {
        return userToActivEscrow[user];
    }

    function getUserEscrow(uint256 escrowId) external view returns(EscrowInfo memory){
        return escrows[escrowId];
    }

    function getArbitratorStatus(address arb) external view returns(bool){
        return arbitrators[arb];
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external view returns(bytes4){
        require(userToActivEscrow[operator] != 0, "Nft can only be sent by the seller");
        uint256 escrowId = userToActivEscrow[operator];
        require(escrows[escrowId].tokenId == tokenId, " User trying to send a different token");
        return this.onERC721Received.selector;
    }
}