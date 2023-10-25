// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;




import './AutoTransfer.sol';


interface StakingPoolInterface {
    function setFixedReward(uint256 _fixedReward) external;
    function setDynamicReward(uint256 _dynamicReward) external;
}


interface MBLKVesting {
    function TransferFixedReleasableAmount(address _beneficiaryAddress,) public ;
    function TransferDynamicAmount(address _beneficiaryAddress,uint256 _amount) public;
    function TransferFixedReleasableAmount(address _beneficiaryAddress,uint256 _index) public;
  function computeReleasableAmount(bytes32 vestingScheduleId)externalviewonlyIfVestingScheduleNotRevoked(vestingScheduleId)returns (uint256);
 function computeVestingScheduleIdForAddressAndIndex(address holder,uint256 index ) public pure returns (bytes32) ;
    }



contract Proxy {
    address public owner;
    address public StakingPoolContract;
    address public VestingContract;

    AutoTransfer public autoTransfer;

    Condition public currentCondition;

    enum Condition { UseStakingPool, UseVestingContract }

    mapping(address => bool) public isAdmin;  

    uint256 FixedRewardAmountReleased;
    uint256 DynamicAmountReleased;
    address _target;

    constructor(address _StakingPoolContract, address _Vesting) {
        owner = msg.sender;
        StakingPoolContract = _StakingPoolContract;
        VestingContract = _Vesting;
        currentCondition = Condition.UseVestingContract;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function toggleCondition() internal {
        currentCondition = (currentCondition == Condition.UseStakingPool) ? Condition.UseVestingContract : Condition.UseStakingPool;
    }

    fallback() external payable {
        //   if (currentCondition == Condition.UseStakingPool) {
        //     _target = StakingPoolContract;
        // } else {
        //     _target = VestingContract;
        // }

        _target = ( currentCondition == Condition.UseStakingPool ) ? StakingPoolContract:  VestingContract;


        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _target, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    function setStakingPoolContractAddress(address _newImpl) public onlyOwner {
        StakingPoolContract = _newImpl;
    }

    function setVestingContractAddress(address _newImpl) public onlyOwner {
        VestingContract = _newImpl;
    }

     function setTotalRewards() public onlyAdmin {
        require(currentCondition == Condition.UseStakingPool);

          StakingPoolInterface(StakingPoolContract).setFixedReward(FixedRewardAmountReleased);

          StakingPoolInterface(StakingPoolContract).setDynamicReward(DynamicAmountReleased);
          toggleCondition();

    }

     
    
    function ReleaseFunds( uint256 _dynamicRewardAmount, uint256 _index) public onlyAdmin {

        require(currentCondition == Condition.UseVestingContract);
        
        bytes32 vestingScheduleId = MBLKVesting(VestingContract).computeVestingScheduleIdForAddressAndIndex(StakingPoolContract, _index);

        FixedRewardAmountReleased = MBLKVesting(VestingContract).computeReleasableAmount(vestingScheduleId);
  
        MBLKVesting(VestingContract).TransferFixedReleasableAmount(StakingPoolContract, _index);

        DynamicAmountReleased = _dynamicRewardAmount;

        MBLKVesting(VestingContract).TransferDynamicAmount(StakingPoolContract, _dynamicRewardAmount);

        toggleCondition();

    }

    function addAdmin(address _newAdmin) public onlyOwner {
        isAdmin[_newAdmin] = true;
        emit adminAdded( _newAdmin);
    }

     function removeAdmin(address _adminAddress) public onlyOwner {
        isAdmin[_adminAddress] = false;
        emit adminRemoved( _adminAddress);
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admins can call this function");
        _;
}
    
    
}
