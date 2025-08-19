// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Order, toOrder} from "../types/Order.sol";

contract TestOrder {
    function test()
        external
        pure
        returns (Order order, address maker_, uint256 tokenId_, bool zeroForOne_, uint8 leverage_)
    {
        // Valores de ejemplo
        address makerAddr = 0x1234567890AbcdEF1234567890aBcdef12345678;
        uint256 tokenIdVal = 123456;
        bool zeroForOne = true;
        uint8 leverageVal = 5;

        // Packing
        order = toOrder(makerAddr, tokenIdVal, leverageVal, zeroForOne);

        // Unpacking
        maker_ = order.maker();
        tokenId_ = order.tokenId();
        zeroForOne_ = order.zeroForOne();
        leverage_ = order.leverage();
    }
}
