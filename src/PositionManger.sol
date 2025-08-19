// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@uniswap/soulmate/tokens/ERC721.sol";

contract PositionManager is ERC721 {
    constructor() ERC721("PositionManager", "Order") {}

    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }
}
