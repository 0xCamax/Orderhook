# OrderHook Contract

A Uniswap V4 Hook implementation that enables advanced trading features while maintaining full compatibility with existing AMM infrastructure. This design ensures backwards compatibility with all currently active arbitrage bots, swappers, and aggregators, allowing anyone to fill maker orders through normal swapping operations.

## Overview

OrderHook extends the standard Uniswap V4 functionality by providing:

- **Orderbook Orders**: Limit orders that execute when price targets are reached
- **Option Contracts**: Creation and settlement of options (WIP)
- **Perpetual Positions**: Leveraged trading with borrowing/lending capabilities (WIP)

## Key Features

### 🔄 AMM Compatibility

The contract maintains full backwards compatibility with existing Uniswap infrastructure:

- Arbitrage bots continue working without modification
- Existing swap aggregators can fill orders
- Standard liquidity providers are unaffected
- All current tooling remains functional

### 📋 Order Management

- **Active Order Tracking**: Orders are mapped by tick and direction
- **Automatic Execution**: Orders resolve when price crosses target levels
- **Position-based Orders**: Each order is backed by a concentrated liquidity position

### 💰 Leverage Trading (WIP)

- **Borrowing Integration**: Leverage positions through the LiquidityManager
- **Liquidation System**: Risk management for leveraged positions
- **Fee Distribution**: Collected fees are distributed to liquidity providers

## Core Components

### Order Structure

Orders are created from `OrderRequest` structs and converted to `Order` objects with:

- Token ID (ERC721 position)
- Direction (zeroForOne boolean)
- Maker address
- Leverage multiplier
- Target tick range

### Position Requirements

- **Tick Spacing**: Must be exactly 1 tick
- **Position Width**: Exactly 1 tick wide (tickUpper - tickLower = 1)
- **Ownership**: Hook must own the position NFT

### Order Resolution

Orders automatically execute when:

1. Price moves across the target tick
2. The position becomes "100% covered"
3. Sufficient liquidity exists for settlement

## Usage Flow

### Creating an Order

1. Create a concentrated liquidity position (1 tick wide)
2. Transfer position ownership to the OrderHook
3. Call `addLiquidity` with `OrderRequest` in hookData
4. Order becomes active and awaits price target

### Order Execution

1. Regular swaps move the price
2. `afterSwap` hook detects price crossing target ticks
3. Affected orders are automatically burned
4. Proceeds are distributed to order makers
5. Fees are collected for liquidity providers

### Leverage Trading (WIP)

1. Specify leverage > 1 in order request
2. Additional funds are borrowed from LiquidityManager
3. Position is opened with leveraged size
4. Liquidation occurs if position becomes unhealthy

## Technical Details

### Hook Permissions

```solidity
// Required permissions for full functionality
BEFORE_INITIALIZE_FLAG |
BEFORE_SWAP_FLAG |
AFTER_SWAP_FLAG |
BEFORE_ADD_LIQUIDITY_FLAG |
AFTER_ADD_LIQUIDITY_FLAG |
AFTER_REMOVE_LIQUIDITY_FLAG
```

### State Management

- **Transient Storage**: Current tick is stored during swaps using `tstore`/`tload`
- **Order Mapping**: `activeOrders[tick][zeroForOne]` stores pending orders
- **Amount Tracking**: `expectedAmount` maps orders to expected proceeds

### Integration Points

- **IPositionManager**: Manages ERC721 position tokens
- **LiquidityManager**: Handles borrowing/lending for leverage
- **BaseHook**: Inherits standard Uniswap V4 hook functionality

## Security Considerations

⚠️ **Current Status**: This contract is in development with several WIP features

### Implemented Safety Checks

- Position ownership validation
- Tick spacing enforcement
- Position width validation

### Areas Under Development

- Leverage system implementation
- Liquidation mechanisms  
- Option contract functionality
- Comprehensive testing suite

## Deployment Requirements

### Dependencies

- Uniswap V4 Core contracts
- Position Manager implementation
- Liquidity Manager for leverage features
- Compatible ERC721 implementation

### Constructor Parameters

```solidity
constructor(
    IPoolManager _manager,        // Uniswap V4 Pool Manager
    address _positionManager,     // Position NFT manager
    address _liquidityManager     // Leverage liquidity provider
)
```

## Development Status

| Feature | Status |
|---------|--------|
| Basic Order Management | ✅ Implemented |
| AMM Compatibility | ✅ Implemented |
| Position Integration | ✅ Implemented |
| Fee Distribution | ✅ Implemented |
| Leverage Trading | 🚧 Work in Progress |
| Option Contracts | 🚧 Work in Progress |
| Liquidation System | 🚧 Work in Progress |

## Future Enhancements

- **Dynamic Fee Structure**: Implement variable fees based on market conditions
- **Advanced Order Types**: Stop-loss, take-profit combinations
- **Cross-margining**: Portfolio-level risk management
- **Oracle Integration**: External price feeds for liquidations
- **Governance**: Decentralized parameter management

## License

MIT License - See SPDX identifier in contract header.
