// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {DeployFundsStorage} from "../../script/DeployFundsStorage.s.sol";
import {FundsStorage} from "../../src/FundsStorage.sol";

contract FundsStorageTest is Test {
    DeployFundsStorage deployer;
    FundsStorage fundsStorage;

    uint256 public constant NEW_DEPOSIT_INTERVAL = 10 days;
    uint256 public constant NEW_WITHDRAW_INTERVAL = 30 days;
    uint256 public constant NEW_ACTION_WINDOW = 10 hours;

    //This may be a little unclear
    uint256 public constant TIME_TO_REACH_DEPOSIT_WINDOW = 31 days;
    uint256 public constant TIME_TO_PASS_WINDOW = 3 days;
    uint256 public constant TIME_TO_REACH_WITHDRAW_WINDOW = 335 days;

    function setUp() public {
        deployer = new DeployFundsStorage();
        fundsStorage = deployer.run();
    }

    ////////////////////////
    // Constructor Tests  //
    ////////////////////////
    //Bad parametervalues
    uint256 public badDepositInterval = 0;
    uint256 public badWithdrawInterval = 0;
    uint256 public badActionWindow = 0;
    //Good parameter values
    uint256 public goodDepositInterval = 30 days;
    uint256 public goodWithdrawInterval = 365 days;
    uint256 public goodActionWindow = 24 hours;

    function testRevertIfConstructorIsGivenZeroDepositInterval() public {
        vm.expectRevert(FundsStorage.FundsStorage__DepositIntervalCannotBeZero.selector);
        new FundsStorage(badDepositInterval,goodWithdrawInterval,goodActionWindow);
    }

    ////////////////////////
    // depositFunds      ///
    ////////////////////////
    /// @notice The following functions will test the depositFunds function in the smart contract
    /// @dev For the first actionWindow time designated in the constructor the contract will be open to deposit and withdraw

    function testRevertsIfTheDepositIntervalIsNotReached() public {
        //skip(TIME_TO_PASS_WINDOW);
        vm.expectRevert(FundsStorage.FundsStorage__DepositWindowNotOpen.selector);
        fundsStorage.depositFunds{value: 0.1 ether}();
    }

    function testRevertsIfTheWithdrawIntervalIsNotReached() public {
        //We need to deposit fund or the user wont have anything to withdraw
        console.log("The curent timestamp is: ", block.timestamp);
        skip(TIME_TO_REACH_DEPOSIT_WINDOW);
        fundsStorage.depositFunds{value: 0.1 ether}();
        vm.expectRevert(FundsStorage.FundsStorage__WithdrawWindowNotOpen.selector);
        fundsStorage.withdrawFunds();
    }
}
