// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IProposalValidationStrategy } from "../interfaces/IProposalValidationStrategy.sol";
import { IndexedStrategy, Strategy } from "../types.sol";
import { PropositionPower } from "../utils/PropositionPower.sol";

/// @title Proposition Power Proposal Validation Strategy
/// @notice Strategy that limits proposal creation to authors that exceed a threshold proposition power
///         over a set of voting strategies.
contract PropositionPowerProposalValidationStrategy is PropositionPower, IProposalValidationStrategy {
    /// @notice Validates an author by checking if the proposition power of the author exceeds a threshold
    ///         over a set of strategies.
    /// @param author Author of the proposal.
    /// @param params ABI encoded array that should contain the following:
    ///                 proposalThreshold: Minimum proposition power required to create a proposal.
    ///                 allowedStrategies: Array of allowed voting strategies.
    ///                 maxBlockAge: Maximum number of blocks between the block chosen by the author and the current block.
    /// @param userParams ABI encoded array that should contain the following:
    ///                 blockNumber: Block at which the proposition power is computed.
    ///                 userStrategies: Array of user voting strategies.
    function validate(
        address author,
        bytes calldata params,
        bytes calldata userParams
    ) external view override returns (bool) {
        (uint256 proposalThreshold, Strategy[] memory allowedStrategies, uint32 maxBlockAge) = abi.decode(
            params,
            (uint256, Strategy[], uint32)
        );
        (uint32 blockNumber, IndexedStrategy[] memory userStrategies) = abi.decode(
            userParams,
            (uint32, IndexedStrategy[])
        );

        return _validate(author, proposalThreshold, allowedStrategies, maxBlockAge, blockNumber, userStrategies);
    }
}
