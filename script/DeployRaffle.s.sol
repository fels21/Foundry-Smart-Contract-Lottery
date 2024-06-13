// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    /*
            uint entranceFee,
        uint256 interval,
        address vrfCordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    */
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            uint entranceFee,
            uint256 interval,
            address vrfCordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimi,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            subscriptionId = createSub.createSubscription(vrfCordinator,deployerKey);

            FundSubscription fSubsc = new FundSubscription();
            fSubsc.fundSubscription(vrfCordinator, subscriptionId, link,deployerKey);
        }

        //vm.startBroadcast();
        Raffle raffle = new Raffle(
            entranceFee,
            interval,
            vrfCordinator,
            gasLane,
            subscriptionId,
            callbackGasLimi
        );
        //vm.startBroadcast();

        AddConsumer addC = new AddConsumer();
        addC.addConsumer(address(raffle),vrfCordinator,subscriptionId,deployerKey);

        return (raffle, helperConfig);
    }
}
