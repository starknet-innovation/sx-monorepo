// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { SXUtils } from "./SXUtils.sol";
import { IndexedStrategy, Strategy } from "../types.sol";
import { IVotingStrategy } from "../interfaces/IVotingStrategy.sol";

/// @title Proposition Power Proposal Validation Strategy Module
/// @notice This module allows a proposal to be validated based on the proposition power of an author exceeding
///         a threshold over a set of voting strategies, at a recent block chosen by the author.
/// @dev The voting strategies used here are configured independently of the strategies set in the Space.
///      The author chooses the block so that strategies whose voting power is signed offchain can be used.
abstract contract PropositionPower {
    using SXUtils for IndexedStrategy[];

    /// @notice Thrown when an invalid strategy index is supplied.
    error InvalidStrategyIndex(uint256 index);

    /// @notice Thrown when the block number is in the future or older than the maximum block age.
    error InvalidBlockNumber(uint32 blockNumber);

    /// @dev Validates an author based on the voting power of the author at `blockNumber` exceeding a threshold over a
    ///      set of strategies. `blockNumber` must not be in the future nor older than `maxBlockAge` blocks.
    function _validate(
        address author,
        uint256 proposalThreshold,
        Strategy[] memory allowedStrategies,
        uint32 maxBlockAge,
        uint32 blockNumber,
        IndexedStrategy[] memory userStrategies
    ) internal view returns (bool) {
        if (blockNumber > block.number || block.number - blockNumber > maxBlockAge) {
            revert InvalidBlockNumber(blockNumber);
        }
        uint256 votingPower = _getCumulativePower(author, blockNumber, userStrategies, allowedStrategies);
        return (votingPower >= proposalThreshold);
    }

    /// @dev Computes the cumulative proposition power of an address at a given block number over a set of strategies.
    function _getCumulativePower(
        address userAddress,
        uint32 blockNumber,
        IndexedStrategy[] memory userStrategies,
        Strategy[] memory allowedStrategies
    ) internal view returns (uint256) {
        // Ensure there are no duplicates to avoid an attack where people double count a strategy.
        userStrategies.assertNoDuplicateIndicesMemory();

        uint256 totalVotingPower;
        for (uint256 i = 0; i < userStrategies.length; ++i) {
            uint256 strategyIndex = userStrategies[i].index;
            if (strategyIndex >= allowedStrategies.length) revert InvalidStrategyIndex(strategyIndex);
            Strategy memory strategy = allowedStrategies[strategyIndex];

            totalVotingPower += IVotingStrategy(strategy.addr).getVotingPower(
                blockNumber,
                userAddress,
                strategy.params,
                userStrategies[i].params
            );
        }
        return totalVotingPower;
    }
}
