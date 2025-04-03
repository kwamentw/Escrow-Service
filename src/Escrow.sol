// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// imports
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title ESCROW
 * @author 4B
 * @notice Standard escrow contract
 */
contract Escrow is ReentrancyGuard{
    using SafeERC20 for IERC20;

    ///////// events

    //Emits when a new arbitrator is added
    event ArbitratorAdded(address newArb);
    //Emits when a new escrow is created
    event EscrowCreated(uint256 id);
    //Emits when an escrow is refunded
    event EscrowRefunded(uint256 id);
    // Emits when a escrow is released to reciever
    event EscrowReleased(uint256 id, uint256 amount);

    ///////// enum

    //Type of asset deposited
    enum AssetType{ERC20, ERC721, Native}

    // Current status of escrow
    enum EscrowStatus{NONE, SETTLED, REFUNDED}

    uint256 id; // escrow starting ID

    /**
     * Escrow Details / configuration information of the escrow.
     */
    struct EscrowInfo {
        address depositor; // Depositor of funds into escrow & creator of escrow
        address receiver; // Receiver of assets deposited into the escrow & renderer of goods and services
        AssetType asset; // Type of asset to be deposited by creator
        uint256 amount; // amount of asset to be deposited | for NFTs this field is zero
        uint256 deadline; // How long escrow should run | so this is the stop time
        uint256 arbitratorFee; // amount of fees paid to arbitrator
        bool depositorConfirm; // bool to track depositor's confiramtion
        bool receiverConfirm; // bool to track receiver's confirmation
        EscrowStatus status; // Current status of Escrow
        address nftAddress; // If asset if NFT this stores the address
        uint256 tokenId; // token Id of stored address
    }

    ///////// mappings

    // address of user that deposited => the id of the escrow deposited in
    mapping (address user => uint256 id) userToActivEscrow; 
    // id of escrow => full details of escrow
    mapping (uint256 id => EscrowInfo escrow) escrows;
    // address of arbitrator => arbitrator status
    mapping (address user => bool status) arbitrators;

    ///////// storage vars

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



    /**
     * Only allows arbitrators to call functions with this modifier
     */
    modifier onlyArbitrator(address sender) {
        require(arbitrators[sender]== true,"Not arbitrator");
        _;
    }

    /**
     * Only allows owner to call functions with this modifier
     */
    modifier onlyOwner {
        require(msg.sender == owner,"Not Authorised");
        _;
    }


    /**
     * Creates a new erc20 escrow or Native token escrow for depositor/depositor
     * @param newEscrow escrow to be created
     * @return id the id of the escrow created
     */
    function createEscrow(EscrowInfo memory newEscrow) external nonReentrant payable returns(uint256){
        require(escrows[id].depositor == address(0), "depositor not set");
        require(newEscrow.depositor != address(0), "invalid depositor");
        require(newEscrow.receiver != address(0), "invalid receiver");
        require(newEscrow.amount > 0,"invalid amount");
        require(newEscrow.deadline > block.timestamp, "invalid deadline");
        require(newEscrow.status == EscrowStatus.NONE, "not a new escrow");
        require(msg.sender == newEscrow.depositor,"not depositor");
        
        userToActivEscrow[msg.sender] = id;
        uint256 arbitratorFee = arbitratorFeeBPS * newEscrow.amount / BASIS_POINT;

        if(newEscrow.asset == AssetType.ERC20){
            newEscrow.arbitratorFee = arbitratorFee;
            if(token.balanceOf(newEscrow.depositor) < newEscrow.amount + arbitratorFee){ revert("Not Enough Funds"); }
            token.safeTransferFrom(newEscrow.depositor, address(this), newEscrow.amount);
            token.safeTransferFrom(newEscrow.depositor, address(this), arbitratorFee);
            
            escrows[id] = newEscrow;
            
        }

        if(newEscrow.asset == AssetType.Native){
            require(msg.value == newEscrow.amount + arbitratorFee,"Incorrect amount");
            newEscrow.arbitratorFee = arbitratorFee;
            escrows[id] = newEscrow;
        }
        uint256 currentId = id;

        id++;

        emit EscrowCreated(currentId);

        return(currentId);
    }

 
    /**
     * Creates a new NFT escrow for depositor/depositor
     * @param newEscrow new nft escrow to be cretaed
     * @return id the id of the escrow created
     */
    function create721Escrow(EscrowInfo memory newEscrow) external nonReentrant payable returns(uint256){
        require(escrows[id].depositor == address(0),"empty 721escrow");
        require(newEscrow.depositor != address(0),"invalid 721 depositor");
        require(newEscrow.receiver != address(0),"invalid 721 receiver");
        require(newEscrow.deadline > block.timestamp,"invalid deadline");
        require(newEscrow.status == EscrowStatus.NONE,"not a fresh escrow");
        
        userToActivEscrow[msg.sender] = id;


        if(newEscrow.asset != AssetType.ERC721){ revert ("Incorrect asset");}

        address nftcontract = newEscrow.nftAddress;
        uint256 tokenID = newEscrow.tokenId;
        require(msg.value == arbitratorFeeForNFT, "arbitrator Fees not paid");
        require(newEscrow.nftAddress != address(0),"incorrect nft");
        require(newEscrow.amount == 0, "MF its an NFT escrow");
        require(IERC721(nftcontract).ownerOf(tokenID)==newEscrow.depositor,"Trying to sell what is not yours");
        IERC721(nftcontract).transferFrom(newEscrow.depositor,address(this),tokenID);
        newEscrow.arbitratorFee = arbitratorFeeForNFT;


        escrows[id] = newEscrow;

        uint256 currentId = id;

        id++;

        emit EscrowCreated(currentId);
        return(currentId);
    }

    /**
     * Called by escrow users to confirm release of escrow
     * @param _id id of the escrow to confirm
     */
    function confirmEscrow(uint256 _id) external {
        require(escrows[_id].deadline >= block.timestamp,"deadline");
        require(msg.sender == escrows[_id].receiver || msg.sender == escrows[_id].depositor,"Cant call this function");
        if(msg.sender == escrows[_id].receiver){
            escrows[_id].receiverConfirm = true;
        }else{
            escrows[_id].depositorConfirm = true;
        }
    }

    /**
     * Adds a new arbitrator to the protocol
     * only owner can add
     * @param newArbitrator address of the new arbitrator
     */
    function addArbitrator(address newArbitrator) external onlyOwner {
        require(arbitrators[newArbitrator]== false, "already an arbitrator");
        arbitrators[newArbitrator] = true;
        emit ArbitratorAdded(newArbitrator);
    }

    //@TODO: add remove arbitrator

    /**
     * Refunds the amount/nft in the escrow back to the depositor/depositor
     * This is regulated by the arbitrator
     * @param _id Id of the escrow
     */
    function refundEscrow(uint256 _id) external nonReentrant onlyArbitrator(msg.sender){
        require(block.timestamp > escrows[_id].deadline,"Pending duration not expired");
        require(escrows[_id].status != EscrowStatus.REFUNDED,"Escrow already refunded");
        require(escrows[_id].receiverConfirm == false || escrows[_id].depositorConfirm == false, "Two parties Have Agreed! Funds need to be released");

        uint256 fee = escrows[_id].arbitratorFee;

        if(escrows[_id].asset == AssetType.ERC20){
            if(token.balanceOf(address(this))<escrows[_id].amount + fee){
                revert("Insufficient balance");
            }
            token.safeTransfer(msg.sender, fee);
            token.safeTransfer(escrows[_id].depositor, escrows[_id].amount);

        }else if(escrows[_id].asset == AssetType.ERC721){
            address nftContract = escrows[_id].nftAddress;
            uint256 tokenID = escrows[_id].tokenId;
            (bool okay, )=payable(msg.sender).call{value: fee}("");
            require(okay);
            IERC721(nftContract).safeTransferFrom(address(this), escrows[_id].depositor, tokenID);

        }else if(escrows[_id].asset == AssetType.Native){
            (bool okay, )=payable(msg.sender).call{value: fee}("");
            require(okay);

            (bool ok, )=payable(escrows[_id].depositor).call{value: escrows[_id].amount}("");
            require(ok);
        }

        escrows[_id].amount = 0;
        userToActivEscrow[msg.sender] = 0;
        escrows[_id].status = EscrowStatus.REFUNDED;

        emit EscrowRefunded(_id);
    }

    /**
     * Releases the tokens in the escrow to receiver/receiver
     * This is regulated by the arbitrator 
     * Can only be called when the receiver & buy have confirmed
     * @param idd id of the escrow
     */
    function releaseEscrow(uint256 idd) external  nonReentrant onlyArbitrator(msg.sender){
        // check whether depositor and receiver has confirmed
        require(escrows[idd].receiverConfirm == true && escrows[idd].depositorConfirm == true, "Can't release escrow");
        // send tokens to receiver but check which token type before
        uint256 amount = escrows[idd].amount;
        address receiver = escrows[idd].receiver;

        if(escrows[idd].asset == AssetType.ERC20){
            if(amount > token.balanceOf(address(this))){
                revert(" Insufficient funds ");
            }
            escrows[idd].amount = 0;
            token.safeTransfer(receiver, amount);
        }else if(escrows[idd].asset == AssetType.Native){
            if(amount <= address(this).balance){
                (bool ok, ) = payable(receiver).call{value: amount}("");
                require(ok);
            }else{
                revert("Not enough balance");
            }
            escrows[idd].amount=0;
        }else{
            address nftContract = escrows[idd].nftAddress;
            uint256 tokenID = escrows[idd].tokenId;
            IERC721(nftContract).safeTransferFrom(address(this), escrows[idd].receiver, tokenID);

            (bool okay,) = payable(msg.sender).call{value: arbitratorFeeForNFT}("");
            require(okay, "TXN FAILED");
            delete escrows[idd];
            
        }

        escrows[idd].status= EscrowStatus.SETTLED;
        userToActivEscrow[msg.sender] = 0;
        emit EscrowReleased(idd,amount);
    }

    /**
     * Sends tokens that have mistakenly been sent to the contract back to the owner
     * Any tokens aside the predefined tokens will be sent to owner
     * @param _token address of locked token
     */
    function releaseLockedTkns(address _token) external onlyOwner{
        if(IERC20(_token).balanceOf(address(this)) > 0){
            uint256 amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(owner, amount);
        }
    }

    /**
     * Gets escrow ID of user's escrow
     * @param user address of escrow depositor
     */
    function getEscrowId(address user) external view returns(uint256) {
        return userToActivEscrow[user];
    }

    /**
     * Gets full EscrowInfo of provided escrowId
     * @param escrowId id of escrow
     */
    function getUserEscrow(uint256 escrowId) external view returns(EscrowInfo memory){
        return escrows[escrowId];
    }

    /**
     * Gets status of arbitrator
     * @param arb address of arbitrator
     */
    function getArbitratorStatus(address arb) external view returns(bool){
        return arbitrators[arb];
    }

    /**
     * NFT interface for receiving nft the safe way
     * @param operator depositor of escrow
     * @param tokenId tokenid of the nft
     */
    function onERC721Received(address operator, address , uint256 tokenId, bytes calldata ) external view returns(bytes4){
        require(userToActivEscrow[operator] != 0, "Nft can only be sent by the depositor");
        uint256 escrowId = userToActivEscrow[operator];
        require(escrows[escrowId].tokenId == tokenId, " User trying to send a different token");
        return this.onERC721Received.selector;
    }

    /**
     * reverts when ether is being sent to the contract directly
     */
    receive() external payable{
        revert("Please create an Escrow: That's the only way you can deposit into this contract");
    }
}