// SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FundsStorage is ReentrancyGuard, Ownable {
    ////////////////////
    //Errors          //
    ////////////////////
    error FundsStorage__DepositMustBeMoreThanZero();
    error FundsStorage__UserDoesNotHaveAnyFundsDeposited();
    error FundsStorage__DepositIntervalCannotBeZero();
    error FundsStorage__WithdrawIntervalCannotBeZero();
    error FundsStorage__ActionWindowCannotBeZero();
    error FundsStorage__DepositWindowNotOpen();
    error FundsStorage__WithdrawWindowNotOpen();

    ////////////////////
    // State Variables //
    ////////////////////
    mapping(address user => uint256 deposits) private s_userDeposits;
    uint256 s_startTime;
    uint256 s_depositInterval;
    uint256 s_withdrawInterval;
    uint256 s_actionWindow;

    ////////////////////
    // Events         //
    ////////////////////
    event FundsDeposited(address indexed user, uint256 indexed amount);
    event FundsWithdrawn(address indexed user, uint256 indexed amount);
    event TimeIntervalsUpdated(
        uint256 indexed newDepositInterval,
        uint256 indexed newWithdrawInterval,
        uint256 indexed newActionWindow,
        uint256 newStartTime
    );

    ////////////////////
    // Modifiers      //
    ////////////////////

    //Note this method block.timestamp of getting the current time is not very accurate and can be off by ~900seconds since it has to-
    // wait for the next block to be mined verified by the blockchain. Also, the timestamp can be manipulated but over long time periods it accurate
    modifier depositTimeLock() {
        uint256 elapsedTime = block.timestamp - s_startTime;

        if (elapsedTime < s_depositInterval) {
            revert FundsStorage__DepositWindowNotOpen();
        }

        uint256 modulusOfTime = elapsedTime % s_depositInterval;
        if (modulusOfTime >= s_actionWindow) {
            revert FundsStorage__DepositWindowNotOpen();
        }
        _;
    }

    modifier withdrawTimeLock() {
        uint256 elapsedTime = block.timestamp - s_startTime;
        //This will only be used for the first withdrawal cycle
        //This can removed if you want to allow deposits during the first actionWindow time when the contract is initially deployed
        if (elapsedTime < s_withdrawInterval) {
            revert FundsStorage__WithdrawWindowNotOpen();
        }
        uint256 modulusOfTime = elapsedTime % s_withdrawInterval;
        if (modulusOfTime >= s_actionWindow) {
            revert FundsStorage__WithdrawWindowNotOpen();
        }
        _;
    }

    ////////////////////
    // Functions  🥸   //
    ////////////////////

    /// @notice Constructor where we set all the initial parameters for the contract
    /// @dev Everything is in seconds
    /// @dev s_startTime is the start time taken from the block.timestamp when the contract is deployed
    /// @param depositInterval is the interval in SECONDS you want allow the user to deposit funds into the contract
    /// @param withdrawInterval is the interval in SECONDS you want allow the user to withdraw funds out of the contract
    /// @param actionWindow is the interval in SECONDS where you will allow the user to interact with the contract deposit/withdraw etc.

    constructor(uint256 depositInterval, uint256 withdrawInterval, uint256 actionWindow) {
        if (depositInterval == 0) {
            revert FundsStorage__DepositIntervalCannotBeZero();
        }
        if (withdrawInterval == 0) {
            revert FundsStorage__WithdrawIntervalCannotBeZero();
        }
        if (actionWindow == 0) {
            revert FundsStorage__ActionWindowCannotBeZero();
        }
        s_startTime = block.timestamp;
        s_depositInterval = depositInterval;
        s_withdrawInterval = withdrawInterval;
        s_actionWindow = actionWindow;
    }

    /////////////////////////////////////
    // Public and External Functions //
    ////////////////////////////////////
    function transferOwnershipOfFundsStorageContract(address newOwner) public virtual onlyOwner {
        transferOwnership(newOwner);
    }

    function depositFunds() external payable depositTimeLock nonReentrant {
        //Here we check to see if they sent any money if it is zero we revert with an error
        if (msg.value == 0) {
            revert FundsStorage__DepositMustBeMoreThanZero();
        }

        s_userDeposits[msg.sender] += msg.value;

        emit FundsDeposited(msg.sender, msg.value);
    }

    //This will withdraw all the funds deposited for a specific user
    //Follow CEI: Checks, Effects, Interactions
    function withdrawFunds() external nonReentrant withdrawTimeLock {
        //Checking to see if the user has anything deposited
        if (s_userDeposits[msg.sender] == 0) {
            revert FundsStorage__UserDoesNotHaveAnyFundsDeposited();
        }
        //Reseting the user deposits
        uint256 withdrawalAmount = s_userDeposits[msg.sender];
        s_userDeposits[msg.sender] = 0;
        //Sending the funds to the user
        (bool callSuccess,) = payable(msg.sender).call{value: withdrawalAmount}("");
        //Requiring the transfer to be successful or the whole transaction will revert
        require(callSuccess);
        emit FundsWithdrawn(msg.sender, s_userDeposits[msg.sender]);
    }

    function setTimeIntervals(uint256 newDepositInterval, uint256 newWithdrawInterval, uint256 newActionWindow)
        external
        onlyOwner
        nonReentrant
    {
        s_depositInterval = newDepositInterval;
        s_withdrawInterval = newWithdrawInterval;
        s_actionWindow = newActionWindow;
        s_startTime = block.timestamp;
        emit TimeIntervalsUpdated(s_depositInterval, s_withdrawInterval, s_actionWindow, s_startTime);
    }

    /////////////////////////////////////
    // Private and Internal Functions //
    ////////////////////////////////////

    function _activeWindowTime() private view returns (uint256 activeWindowTime) {
        //may have to add another variable to track the window for deposit/withdraw window
    }

    /////////////////////////////////////
    // View and Pure Functions         //
    ////////////////////////////////////

    function getDepositTimeInterval() external view returns (uint256 depositTimeInterval) {
        depositTimeInterval = s_depositInterval;
    }

    function getWithdrawTimeInterval() external view returns (uint256 withdrawTimeInterval) {
        withdrawTimeInterval = s_withdrawInterval;
    }

    function getActionTimeInterval() external view returns (uint256 actionWindow) {
        actionWindow = s_actionWindow;
    }

    function getUserBalance(address userAddress) external view returns (uint256 userBalance) {
        userBalance = s_userDeposits[userAddress];
    }

    function getTimeUntilDepositWindow() external view returns (uint256 timeUntilDepositOpen) {
        timeUntilDepositOpen = (block.timestamp - s_startTime) % s_depositInterval;
    }

    function getTimeUntilWithdrawWindow() external view returns (uint256 timeUntilWithdrawOpen) {
        timeUntilWithdrawOpen = (block.timestamp - s_startTime) % s_withdrawInterval;
    }
}
