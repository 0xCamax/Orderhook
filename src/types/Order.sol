// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @notice Order empaquetado en un bytes32 con este layout (LSB -> MSB):
/// [ maker: 160 bits (0..159) ]
/// [ tokenId: 80 bits (160..239) ]
/// [ zeroForOne: 8 bits (240..247) ]
/// [ leverage: 8 bits (248..255) ]
type Order is bytes32;

using OrderLibrary for Order global;

function toOrder(
    address maker,
    uint256 tokenId,
    uint8 leverage,
    bool zeroForOne
) pure returns (Order result) {
    assembly {
        // Colocar maker (bits 0..159)
        result := and(maker, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)

        // Colocar tokenId (48 bits) en bits 160..207
        result := or(result, shl(160, and(tokenId, 0xFFFFFFFFFFFFFFFFFFFF)))

        // Colocar zeroForOne (40 bits) en bits 208..247
        result := or(result, shl(240, and(zeroForOne, 0xFF)))

        // Colocar leverage (8 bits) en bits 248..255
        result := or(result, shl(248, and(leverage, 0xFF)))
    }
}

library OrderLibrary {
    /// @notice Devuelve maker (address, 160 bits en 0..159)
    function maker(Order order) internal pure returns (address result) {
        assembly {
            result := and(order, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @notice Devuelve tokenId (80 bits en offset 160)
    function tokenId(Order order) internal pure returns (uint256 result) {
        assembly {
            result := and(shr(160, order), 0xFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @notice Devuelve zeroForOne (8 bits en offset 240)
    function zeroForOne(Order order) internal pure returns (bool result) {
        assembly {
            result := and(shr(240, order), 0xFF)
        }
    }

    /// @notice Devuelve leverage (8 bits en offset 248)
    function leverage(Order order) internal pure returns (uint8 result) {
        assembly {
            result := and(shr(248, order), 0xFF)
        }
    }

}
