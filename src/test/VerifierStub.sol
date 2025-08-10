// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {IAdrastiaVerifierProxy} from "src/interfaces/IAdrastiaVerifierProxy.sol";
import {DataStreamsStructs} from "src/structs/DataStreamsStructs.sol";
import {FeedDataFixture} from ".//FeedDataFixture.sol";
import {IAdrastiaFeeManager} from "src/interfaces/IAdrastiaFeeManager.sol";
import {DataStreamsStructs} from "src/structs/DataStreamsStructs.sol";
import {RewardManagerStub} from "./RewardManagerStub.sol";

contract VerifierStub is IAdrastiaVerifierProxy, DataStreamsStructs, FeedDataFixture {
    address internal _feeManager;

    bool internal overrideVerifyBulk;
    bytes[] internal overriddenVerifiedReports;

    constructor() {}

    /// @inheritdoc IAdrastiaVerifierProxy
    function verify(
        bytes calldata payload,
        bytes calldata parameterPayload
    ) public payable override returns (bytes memory) {
        if (_feeManager != address(0)) {
            address linkAddress = IAdrastiaFeeManager(_feeManager).i_linkAddress();
            address rewardManager = IAdrastiaFeeManager(_feeManager).i_rewardManager();

            if (linkAddress != address(0) && rewardManager != address(0)) {
                address providedLinkAddress = abi.decode(parameterPayload, (address));
                if (providedLinkAddress != linkAddress) {
                    revert("VerifierStub: provided link address does not match fee manager's link address");
                }

                (DataStreamsStructs.Asset memory fee, , ) = IAdrastiaFeeManager(_feeManager).getFeeAndReward(
                    msg.sender,
                    payload,
                    linkAddress
                );

                if (fee.amount > 0) {
                    RewardManagerStub(rewardManager).collectFee(linkAddress, msg.sender, fee.amount);
                }
            }
        }

        // Decode the payload as (bytes32[3], bytes)
        (bytes32[3] memory metadata, bytes memory rawData) = abi.decode(payload, (bytes32[3], bytes));

        if (metadata[0] != FEED_SIGNED) {
            revert("REPORT_NOT_SIGNED");
        }

        // Parse the 2-byte version manually
        uint16 version = (uint16(uint8(rawData[0])) << 8) | uint16(uint8(rawData[1]));

        // Decode report based on version
        if (version == 4) {
            ReportV4 memory report = abi.decode(rawData, (ReportV4));
            return abi.encode(report);
        } else if (version == 3) {
            ReportV3 memory report = abi.decode(rawData, (ReportV3));
            return abi.encode(report);
        } else if (version == 2) {
            ReportV2 memory report = abi.decode(rawData, (ReportV2));
            return abi.encode(report);
        } else if (version == UNSUPPORTED_REPORT_VERSION) {
            return rawData;
        } else {
            revert("VerifierStub: unsupported version");
        }
    }

    /// @inheritdoc IAdrastiaVerifierProxy
    function verifyBulk(
        bytes[] calldata payloads,
        bytes calldata parameterPayload
    ) external payable override returns (bytes[] memory verifiedReports) {
        if (overrideVerifyBulk) {
            return overriddenVerifiedReports;
        }

        uint256 len = payloads.length;
        verifiedReports = new bytes[](len);

        for (uint256 i = 0; i < len; ++i) {
            // Call verify() for each entry
            verifiedReports[i] = verify(payloads[i], parameterPayload);
        }
    }

    /// @inheritdoc IAdrastiaVerifierProxy
    function s_feeManager() external view override returns (address) {
        return _feeManager;
    }

    /// @notice Set the fee manager
    function setFeeManager(address newFeeManager) external {
        _feeManager = newFeeManager;
    }

    function stubOverrideVerifyBulk(bool _overrideVerifyBulk, bytes[] memory _overriddenVerifiedReports) external {
        overrideVerifyBulk = _overrideVerifyBulk;
        overriddenVerifiedReports = _overriddenVerifiedReports;
    }
}
