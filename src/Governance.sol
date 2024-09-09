// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "./veSTAR.sol";

contract AstraGovernor is Governor, GovernorVotes, GovernorCountingSimple, GovernorTimelockControl {
    constructor(veSTARToken _token, TimelockController _timelock)
        Governor("veSTAR Governor")
        GovernorVotes(_token)
        GovernorTimelockControl(_timelock)
    {}

    function votingDelay() public pure override returns (uint256) {
        return 1; 
    }

    function votingPeriod() public pure override returns (uint256) {
        return 45818;
    }

    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 1000e18;
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 100e18; 
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function state(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

contract veSTARTimelock is TimelockController {
    constructor(
        uint256 minDelay, 
        address[] memory proposers, 
        address[] memory executors 
    ) TimelockController(minDelay, proposers, executors) {}
}
