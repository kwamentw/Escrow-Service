// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockNFT is ERC721{

    constructor() ERC721("MOCKNFT","MNFT"){
        
    }

    function mint(address to, uint256 id) public{
        _mint(to,id);
    }

}