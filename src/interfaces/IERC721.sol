// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice ERC-721 interface, compatible with OpenZeppelin and Solmate.
interface IERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 id) external view returns (address owner);

    function approve(address spender, uint256 id) external;
    function setApprovalForAll(address operator, bool approved) external;

    function getApproved(uint256 id) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(address from, address to, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external;

    /*//////////////////////////////////////////////////////////////
                         METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 id) external view returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/// @notice Interface for contracts that accept ERC721 tokens.
interface IERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}
