# Provably Random Raffle Contract

## About

This project is based on the [Foundry Smart Contract Lottery](https://github.com/Cyfrin/foundry-smart-contract-lottery-f23), part of the full Foundry course. For more details, you can visit the [Foundry Full Course](https://github.com/Cyfrin/foundry-full-course-f23).

Alternatively, you can check the project website to learn more at:
[Updraft by Cyfrin](https://updraft.cyfrin.io/)

## What We Want to Do

1. Users can enter by paying for a ticket.
    - The ticket fees are awarded to the winner during the draw.
2. After a set period, the lottery will automatically draw a winner.
    - This process will be done programmatically.
3. Utilizing Chainlink VRF & Chainlink Automation:
    - <strong>Chainlink VRF</strong>: Provides randomness.
    - <strong>Chainlink Automation</strong>: Manages time-based scripts.

## Personal Notes, Observations, and Learning

### Install Chainlink Brownie Contracts

````
forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit
````

[Chainlink Brownie Contracts Repository](https://github.com/smartcontractkit/chainlink-brownie-contracts)

Add remappings to `foundry.toml`:

````
remappings = ["@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/"]
````

### Install Solmate

````
forge install transmissions11/solmate --no-commit
````

Add remappings:

````
"@solmate=lib/solmate/src/"
````

### DevOps

[Foundry DevOps Repository](https://github.com/Cyfrin/foundry-devops)

````
forge install Cyfrin/foundry-devops --no-commit
````

### Testing Notes

In test files, the function names to test should start with "testSomething":
- `testRaffleRevertNotEnoughEth` -> OK
- `raffleRevertNotEnoughEth` -> KO

In previous versions of Forge (video), to choose a specific test function it appears like:
````
forge test -m $test_function_name
````

In the current Forge version (0.2.0) it should be:
````
forge test --mt $test_function_name
````

## Solidity Contract Layout Standards

### Layout of Contract

1. Version
2. Imports
3. Errors
4. Interfaces, Libraries, Contracts
5. Type Declarations
6. State Variables
7. Events
8. Modifiers
9. Functions

### Layout of Functions

1. Constructor
2. Receive function (if exists)
3. Fallback function (if exists)
4. External
5. Public
6. Internal
7. Private
8. View & Pure functions

## Flows

- For functions -> CEI: Checks, Effects, Interaction
- For tests -> Arrange, Act, Assert
