// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Order, toOrder} from "./Order.sol";

struct OrderRequest {
    address maker;
    bool zeroForOne;
    uint8 leverage;
}

using OrderRequestLib for OrderRequest global;

library OrderRequestLib {
    function isValid(OrderRequest memory req) internal pure {
        require(req.maker != address(0), "Invalid Address");
        require(req.leverage <= 20, "Invalid leverage");
    }

    function makeOrder(
        OrderRequest memory req,
        uint256 id
    ) internal pure returns (Order) {
        req.isValid();
        return toOrder(req.maker, id, req.leverage, req.zeroForOne);
    }
}
