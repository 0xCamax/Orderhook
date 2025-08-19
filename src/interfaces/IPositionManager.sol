// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPositionManager as IPm} from "@uniswap/v4-periphery/interfaces/IPositionManager.sol";
import {IERC721} from "./IERC721.sol";

interface IPositionManager is IPm, IERC721 {}
