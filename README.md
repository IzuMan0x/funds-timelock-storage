## Smart Contract for depositing and withdrawing funds at a certain time period only

## The functionality is as follows:

    1. Users will able to deposit Ethereum (the blockchain native currency) only during a certain period.
       1. Initially the time period will be set in the constructor arguments.
       2. The time period can be changed by the owner of the contract (which is the deployer by default)
    2. User will only be able to withdraw the funds they have deposited after a certain amount of time has elapsed.
       1. Each user will only be able to withdraw what they have deposited.
    3. This contract is "ownable" and the ownership can be transfer by using the "transferOwnershipOfFundsStorageContract" function and passing the address of the desired new owner.

## This contract has some known bugs

    1. The contract's time is measured in seconds and cannot account for leap years, leap days, and daylight savings in some places in the world.
       1. To fix this we could add an outside time oracle, but that is beyond the scope of this project.
