// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPositionManager} from "../interfaces/IPositionManager.sol";
import {PoolKey} from "@uniswap/v4-core/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/types/Currency.sol";
import {Actions} from "@uniswap/v4-periphery/libraries/Actions.sol";
import {IHooks} from "@uniswap/v4-core/interfaces/IHooks.sol";
import {OrderRequest} from "../types/OrderRequest.sol";
import {LiquidityAmounts} from "@uniswap/v4-periphery/libraries/LiquidityAmounts.sol";
import {StateLibrary} from "@uniswap/v4-core/libraries/StateLibrary.sol";
import {TickMath} from "@uniswap/v4-core/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/interfaces/IPoolManager.sol";
import {IV4Router} from "@uniswap/v4-periphery/interfaces/IV4Router.sol";
import {Commands} from "@uniswap/v4-periphery/libraries/Commands.sol";

contract TestHook {
    using TickMath for int24;
    using StateLibrary for IPoolManager;

    IPoolManager public constant poolManager =
        IPoolManager(0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32);
    IV4Router public constant router =
        IV4Router(0xA51afAFe0263b40EdaEf0Df8781eA9aa03E381a3);

    PoolKey public key =
        PoolKey(
            Currency.wrap(address(0)),
            Currency.wrap(0xaf88d065e77c8cC2239327C5EDb3A432268e5831),
            500,
            1,
            IHooks(0x7059DFe34A6f40fA9A341aF1313CB79720b76DC1)
        );

    function getSlot0()
        public
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint24 protocolFee,
            uint24 lpFee
        )
    {
        return poolManager.getSlot0(key.toId());
    }

    function openOrder()
        public
        view
        returns (bytes memory, bytes[] memory, bytes memory)
    {
        (, int24 tick, , ) = poolManager.getSlot0(key.toId());
        if(tick == 0){
            tick = -191897;
        }
        int24 tickLower = true ? tick + 3 : tick - 1 - 1;
        int24 tickUpper = true ? tick + 3 + 1 : tick - 1;
        uint256 liquidity = true
            ? LiquidityAmounts.getLiquidityForAmount0(
                tickLower.getSqrtPriceAtTick(),
                tickUpper.getSqrtPriceAtTick(),
                100000000000
            )
            : LiquidityAmounts.getLiquidityForAmount1(
                tickLower.getSqrtPriceAtTick(),
                tickUpper.getSqrtPriceAtTick(),
                100000000000
            );
        bytes memory actions = abi.encodePacked(
            uint8(Actions.MINT_POSITION),
            uint8(Actions.SETTLE)
        );
        bytes[] memory params = new bytes[](2);

        params[0] = abi.encode(
            key,
            tickLower,
            tickUpper,
            liquidity,
            type(uint128).max,
            type(uint128).max,
            0x7059DFe34A6f40fA9A341aF1313CB79720b76DC1,
            abi.encode(OrderRequest(msg.sender, true, 1))
        );

        params[1] = abi.encode(address(0), 100000000000, true);

        return (actions, params, abi.encode(actions, params));
    }

    function swap()
        public
        view
        returns (bytes memory commands, bytes[] memory callData)
    {
        bytes[] memory _params = new bytes[](4);

        _params[0] = abi.encode(
            IV4Router.ExactOutputSingleParams(key, false, 250000000000, 1e6, "")
        );

        _params[1] = abi.encode(
            Currency.wrap(0xaf88d065e77c8cC2239327C5EDb3A432268e5831),
            1e4,
            true
        );
        _params[2] = abi.encode(Currency.wrap(address(0)), 0);
        _params[3] = abi.encode(
            Currency.wrap(0xaf88d065e77c8cC2239327C5EDb3A432268e5831),
            0
        );

        bytes[] memory input = new bytes[](1);

        input[0] = abi.encode(
            abi.encodePacked(
                uint8(Actions.SWAP_EXACT_OUT_SINGLE),
                uint8(Actions.SETTLE),
                uint8(Actions.TAKE_ALL),
                uint8(Actions.TAKE_ALL)
            ),
            _params
        );

        return (abi.encodePacked(uint8(Commands.V4_SWAP)), input);
    }
}
