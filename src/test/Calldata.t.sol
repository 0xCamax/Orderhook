// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CalldataDecoder} from "@uniswap/v4-periphery/libraries/CalldataDecoder.sol";
import {PoolKey} from "@uniswap/v4-core/types/PoolKey.sol";

library DecodeCalldataTest {
    using CalldataDecoder for bytes;

    function decodeMintParams(
        bytes calldata data
    )
        public
        pure
        returns (
            PoolKey calldata poolKey,
            int24 tickLower,
            int24 tickUpper,
            uint256 liquidity,
            uint128 amount0Max,
            uint128 amount1Max,
            address owner,
            bytes calldata hookData
        )
    {
        return data.decodeMintParams();
    }

    function unlockCalldata(bytes calldata data) public pure returns (bytes memory actions, bytes[] memory params){
        (actions, params) = data.decodeActionsRouterParams();
    }
}
