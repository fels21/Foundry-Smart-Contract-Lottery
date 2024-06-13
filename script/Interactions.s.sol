// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts//src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address vrfCordinator, , , , , uint256 deployerKey) = helperConfig
            .activeNetworkConfig();
        return createSubscription(vrfCordinator, deployerKey);
    }

    function createSubscription(
        address vrfCordinator,
        uint256 deployerKey
    ) public returns (uint64) {
        console.log("Creating Subscription on ChaainID: ", block.chainid);

        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(vrfCordinator).createSubscription();
        vm.stopBroadcast();

        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 0.1 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig hConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCordinator,
            ,
            uint64 subId,
            ,
            address link,
            uint256 deployerKey
        ) = hConfig.activeNetworkConfig();
        fundSubscription(vrfCordinator, subId, link,deployerKey);
    }

    function fundSubscription(
        address vrfCord,
        uint64 subId,
        address link,
        uint256 deployerKey
    ) public {
        console.log("Funding subid: ", subId);
        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCord).fundSubscription(subId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                vrfCord,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumer(
        address raffle,
        address vrfCordinator,
        uint64 subId,
        uint256 deployerKey
    ) public {
        console.log("Adding consumer contact", raffle);
        console.log("On Chain Id", block.chainid);

        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig hConfig = new HelperConfig();
        (
            ,
            ,
            address vrfCordinator,
            ,
            uint64 subId,
            ,
            ,
            uint256 deployerKey
        ) = hConfig.activeNetworkConfig();

        addConsumer(raffle, vrfCordinator, subId, deployerKey);
    }

    function run() external {
        address raffles = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffles);
    }
}
