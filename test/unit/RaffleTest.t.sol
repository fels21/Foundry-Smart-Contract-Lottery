// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Test, console} from "forge-std/Test.sol";

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts//src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee; //ok
    uint256 interval; //ok
    address vrfCordinator;
    bytes32 gasLane; //ok
    uint64 subscriptionId; //ok
    uint32 callbackGasLimi; //ok
    address link; //ok

    //uint256 automationUpdateInterval;

    address public PLAYER = makeAddr("player"); //ok
    uint256 public constant STARTING_BALANCE = 10 ether;

    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed player);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        (
            entranceFee,
            interval,
            vrfCordinator,
            gasLane,
            subscriptionId,
            callbackGasLimi,
            link,

        ) = helperConfig.activeNetworkConfig();

        vm.deal(PLAYER, 1 ether);
    }

    
    /*═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━*/
    /*                            Raffle                                */
    /*═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━*/


    function testRaffleInitWithOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleReverNotEnoughtEth() public {
        // Arrange
        vm.prank(PLAYER);
        // Assert
        vm.expectRevert(Raffle.Raffle_NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleIsRegisteringPlayers() public {
        // Arrange
        vm.prank(PLAYER);

        // Act
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayerAtIndex(0);

        // Assert
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        // Arrange
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);

        // Act/Assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenIsCalculating() public {
        //arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }


    /*═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━*/
    /*                            checkUpkeep                           */
    /*═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━*/

    function testCheckUpkeeperBalanceFalse() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(!upkeepNeeded);
    }

    function testUpkeeperFalseIfRaffleIsNotOppen() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(!upkeepNeeded);
    }

    // Upkeep returns false if enought time hasnt pased

    function testUpekeeperFalesIfNoTimePased() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(!upkeepNeeded);
    }

    // Upkeeper returns true
    function testUpkeeperReturnsTrueIfAllIsOK() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(upkeepNeeded);
    }

    /*═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━*/
    /*                          performUpKeep                           */
    /*═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━*/
    function testPerformUpkeepCanOnlyRunIfCheckIsTrue() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertIfUpkeepIsNotNeeded() public {
        //Arrange
        uint256 currBalance = 0;
        uint256 numPlayers = 0;
        uint256 raffleState = 0;

        //Act
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Rafffle_UpkeepNotNeeded.selector,
                currBalance,
                numPlayers,
                raffleState
            )
        );

        raffle.performUpkeep("");
    }

    modifier raffleEnteredAndTimePast() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    //How to test events
    function testPerformUpkeepUpdStateAndEmitEvent()
        public
        raffleEnteredAndTimePast
    {
        vm.recordLogs();
        raffle.performUpkeep(""); //Emit Event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        Raffle.RaffleState rState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }



    /*═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━*/
    /*                          fulfillRandomWords                      */
    /*═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━═━*/
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testFullfillRandWordsCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEnteredAndTimePast skipFork {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testFullfillRandomNumberAndPickTheWinner()
        public
        raffleEnteredAndTimePast
        skipFork
    {
        //Arrange
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;

        for (
            uint256 i = startingIndex;
            i < (startingIndex + additionalEntrants);
            i++
        ) {
            address nPlayer = address(uint160(i));
            hoax(nPlayer, STARTING_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 prize = entranceFee * (additionalEntrants + 1);

        vm.recordLogs();
        raffle.performUpkeep(""); //Emit Event
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        uint256 prevTimeStamp = raffle.getLastTimeStamp();

        VRFCoordinatorV2Mock(vrfCordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        //assert

        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getLastWinner() != address(0));
        assert(raffle.getPlayersLenght() == 0);
        assert(raffle.getLastTimeStamp() > prevTimeStamp);
        assert(
            raffle.getLastWinner().balance ==
                STARTING_BALANCE + prize - entranceFee
        );
    }
}
