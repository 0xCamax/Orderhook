// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseHook} from "./contracts/BaseHook.sol";
import {BeforeSwapDelta} from "@uniswap/v4-core/types/BeforeSwapDelta.sol";
import {Currency} from "@uniswap/v4-core/types/Currency.sol";
import {IPoolManager} from "@uniswap/v4-core/interfaces/IPoolManager.sol";
import {SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/types/PoolOperation.sol";
import {IPositionManager} from "./interfaces//IPositionManager.sol";
import {BalanceDelta, toBalanceDelta} from "@uniswap/v4-core/types/BalanceDelta.sol";
import {ERC721} from "@uniswap/soulmate/tokens/ERC721.sol";
import {IERC20Minimal} from "@uniswap/v4-core/interfaces/external/IERC20Minimal.sol";
import {StateLibrary} from "@uniswap/v4-core/libraries/StateLibrary.sol";
import {TransientStateLibrary} from "@uniswap/v4-core/libraries/TransientStateLibrary.sol";
import {TickMath} from "@uniswap/v4-core/libraries/TickMath.sol";
import {PoolId} from "@uniswap/v4-core/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/types/PoolKey.sol";
import {Actions} from "@uniswap/v4-periphery/libraries/Actions.sol";
import {OrderRequest, Order, toOrder} from "./types/index.sol";
import {LiquidityManager} from "./LiquidityManager.sol";
import {LiquidityAmounts} from "./libraries/LiquidityAmounts.sol";
import {LiquidityAmounts as v4Liq} from "@uniswap/v4-periphery/libraries/LiquidityAmounts.sol";

/**
 * This hook should be capable of:
 * - Handling orderbook orders.
 * - Creating and settling option contracts.
 * - Creating, closing and liquidating perpetual positions.
 */
contract Orderhook is BaseHook {
    using StateLibrary for IPoolManager;
    using TransientStateLibrary for IPoolManager;
    using TickMath for int24;

    // tick => zeroForOne => Order
    mapping(int24 => mapping(bool => Order[])) public activeOrders;
    mapping(Order => uint256) internal expectedAmount;

    IPositionManager public immutable positionManager;
    LiquidityManager public immutable liquidityManager;

    bool internal initialized;

    constructor(IPoolManager _manager, address _positionManger, address _liquidityManager) BaseHook(_manager) {
        positionManager = IPositionManager(_positionManger);
        liquidityManager = LiquidityManager(_liquidityManager);
    }

    function _beforeInitialize(address, PoolKey calldata key, uint160) internal pure override returns (bytes4) {
        require(key.tickSpacing == 1, "Tick spacing must be one");
        return (this.beforeInitialize.selector);
    }

    function _beforeSwap(address, PoolKey calldata key, SwapParams calldata params, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24 fee)
    {
        (, int24 currentTick,,) = poolManager.getSlot0(key.toId());
        assembly {
            tstore(0x00, currentTick)
        }
        //handle dynamic fee

        return (this.beforeSwap.selector, BeforeSwapDelta.wrap(params.amountSpecified), fee);
    }

    /// @inheritdoc BaseHook
    function _afterSwap(address, PoolKey calldata key, SwapParams calldata params, BalanceDelta, bytes calldata)
        internal
        override
        returns (bytes4, int128)
    {
        _resolveActiveOrders(key, params.zeroForOne);
        return (this.afterSwap.selector, 0);
    }

    // @inheritdoc BaseHook
    function _beforeAddLiquidity(address, PoolKey calldata, ModifyLiquidityParams calldata params, bytes calldata)
        internal
        view
        override
        returns (bytes4)
    {
        require(params.tickUpper - params.tickLower == 1, "Invalid position");
        require(positionManager.ownerOf(uint256(params.salt)) == address(this), "Invalid position owner");

        return this.beforeAddLiquidity.selector;
    }

    /// @inheritdoc BaseHook
    function _afterAddLiquidity(
        address,
        PoolKey calldata,
        ModifyLiquidityParams calldata params,
        BalanceDelta,
        BalanceDelta,
        bytes calldata hookData
    ) internal override returns (bytes4, BalanceDelta) {
        OrderRequest memory orderReq = abi.decode(hookData, (OrderRequest));
        Order order = orderReq.makeOrder(uint256(params.salt));
        int24 targetTick = orderReq.zeroForOne ? params.tickUpper : params.tickLower;
        activeOrders[targetTick][orderReq.zeroForOne].push(order);

        //settle happens in positionManager

        return (this.afterAddLiquidity.selector, toBalanceDelta(0, 0));
    }

    function _afterRemoveLiquidity(
        address,
        PoolKey calldata key,
        ModifyLiquidityParams calldata,
        BalanceDelta delta,
        BalanceDelta feesAccrued,
        bytes calldata hookData
    ) internal override onlyPoolManager returns (bytes4, BalanceDelta) {
        Order order = abi.decode(hookData, (Order));
        if (order.zeroForOne()) {
            poolManager.take(key.currency1, order.maker(), uint128(delta.amount1()));
            if (feesAccrued.amount1() > 0) {
                poolManager.take(key.currency1, address(this), uint128(feesAccrued.amount1()));
                liquidityManager.deposit(uint128(feesAccrued.amount1()));
            }
            if (feesAccrued.amount0() > 0) {
                poolManager.take(key.currency1, address(liquidityManager), uint128(feesAccrued.amount0()));
            }
        } else {
            poolManager.take(key.currency1, order.maker(), uint128(delta.amount0()));
            if (feesAccrued.amount0() > 0) {
                poolManager.take(key.currency1, address(this), uint128(feesAccrued.amount0()));
                liquidityManager.deposit(uint128(feesAccrued.amount0()));
            }
            if (feesAccrued.amount1() > 0) {
                poolManager.take(key.currency1, address(liquidityManager), uint128(feesAccrued.amount1()));
            }
        }

        return (this.afterRemoveLiquidity.selector, delta);
    }

    /**
     * Close finalized orders 
     *         Is finialized if:
     *             -Is 100% covered
     */
    function _resolveActiveOrders(PoolKey memory key, bool zeroForOne) internal {
        (, int24 currentTick,,) = poolManager.getSlot0(key.toId());
        int24 initialTick;
        assembly {
            initialTick := tload(0x00)
        }

        if (currentTick == initialTick) return; // No movement, no orders to resolve

        (int24 start, int24 end) = zeroForOne ? (currentTick + 1, initialTick + 1) : (initialTick, currentTick);

        bytes memory actions;
        bytes[] memory params;
        while (start < end) {
            Order[] memory _orders = activeOrders[start][!zeroForOne];

            for (uint256 i = 0; i < _orders.length; i++) {
                (actions, params) = _burnPosition(_orders[i], actions, params);
            }

            delete activeOrders[start][!zeroForOne];

            unchecked {
                start++;
            }
        }
        positionManager.modifyLiquiditiesWithoutUnlock(actions, params);
    }

    function _burnPosition(Order order, bytes memory actions, bytes[] memory params)
        internal
        view
        returns (bytes memory, bytes[] memory)
    {
        bytes[] memory _params = new bytes[](params.length + 1);
        for (uint256 i = 0; i < params.length; i++) {
            _params[i] = params[i];
        }

        _params[params.length] = abi.encode(
            order.tokenId(),
            order.zeroForOne() ? 0 : expectedAmount[order],
            order.zeroForOne() ? expectedAmount[order] : 0,
            abi.encode(order)
        );

        return (abi.encodePacked(actions, uint8(Actions.BURN_POSITION)), _params);
    }

    //WIP
    function _borrowLeverage(Order order, ModifyLiquidityParams memory params, int24 currentTick) internal {
        require(order.leverage() > 1, "Invalid leverage");
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            currentTick.getSqrtPriceAtTick(),
            params.tickLower.getSqrtPriceAtTick(),
            params.tickUpper.getSqrtPriceAtTick(),
            uint128(uint256(params.liquidityDelta))
        );

        uint256 amount = (amount0 != 0) ? amount0 : amount1;
        amount = (amount * (order.leverage() - 1)) / order.leverage();

        liquidityManager.borrow(amount, order.maker());
    }

    function _repayLeverage(Order order) internal {
        uint256 owed = liquidityManager.getTotalOwed(order.maker());
        liquidityManager.repay(order.maker(), owed);
    }

    function _liquidate(Order order) internal {
        //todo
    }
}
