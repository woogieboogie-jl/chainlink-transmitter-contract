// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {DataStreamsFeed} from "../src/feed/DataStreamsFeed.sol"; // Import the main contract

/**
 * @title Deployment Script for the original DataStreamsFeed
 * @dev Deploys a non-upgradeable instance of the DataStreamsFeed contract.
 * This script is for the contract version that uses local interfaces to discover the Fee Manager.
 */
contract DeployDataStreamsFeed is Script {
    function run() external returns (address deployedAddress) {
        // =================================================================
        // │                  CONFIGURATION PARAMETERS                     │
        // =================================================================

        // The official Chainlink Verifier Proxy address for your target chain.
        address verifierProxyAddress = 0x2ff010DEbC1297f19579B4246cad07bd24F2488A; // <-- TODO: Replace with official address

        // The unique ID for the Data Stream you want to track (e.g., ETH/USD).
        bytes32 feedId = 0x000359843a543ee2fe414dc14c7e7920ef10f4372990b79d6361cdc0dd1ba782; // <-- TODO: Replace with the desired feed ID

        // The number of decimals for the price data.
        uint8 decimals = 18;

        // A human-readable description for the feed.
        string memory description = "My Custom ETH / USD Feed";
        
        // =================================================================
        // │                        DEPLOYMENT LOGIC                       │
        // =================================================================
        
        // Start the broadcast. The next call will be a sent transaction.
        vm.startBroadcast();

        // Deploy the DataStreamsFeed contract in a single transaction.
        // We do NOT pass the feeManagerAddress, as the contract finds it itself.
        console.log("Deploying DataStreamsFeed (Community Driven)...");
        DataStreamsFeed feed = new DataStreamsFeed(
            verifierProxyAddress,
            feedId,
            decimals,
            description
        );
        
        deployedAddress = address(feed);
        console.log("DataStreamsFeed deployed at:", deployedAddress);

        // Stop the broadcast.
        vm.stopBroadcast();

        return deployedAddress;
    }
}
