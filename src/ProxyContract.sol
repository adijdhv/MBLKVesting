// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;




import './AutoTransfer.sol';


interface StakingPoolInterface {
    function setFixedReward(uint256 _fixedReward) external;
    function setDynamicReward(uint256 _dynamicReward) external;
}


interface AutoTransferInterface {
    function TransferFixedReleasableAmount(address _beneficiaryAddress,) public ;
    function TransferDynamicAmount(address _beneficiaryAddress,uint256 _amount) public;
    function TransferFixedReleasableAmount(address _beneficiaryAddress,uint256 _index) public;
    function computeReleasableAmount(bytes32 vestingScheduleId)externalviewonlyIfVestingScheduleNotRevoked(vestingScheduleId)returns (uint256);
    function computeVestingScheduleIdForAddressAndIndex(address holder,uint256 index ) public pure returns (bytes32) ;
    }



contract Proxy {
    address public owner;
 

    AutoTransferInterface public AutoTransfer;

    StakingPoolInterface public StakingPool;
 

    mapping(address => bool) public isAdmin;  

    uint256 FixedRewardAmountReleased;
    uint256 DynamicAmountReleased;
     
    constructor(address _StakingPoolContract, address _Vesting) {
        owner = msg.sender;
        StakingPool = StakingPoolInterface(_StakingPoolContract);
        AutoTransfer = AutoTransferInterface(_Vesting);
        
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

  

  
    

    function setStakingPoolContractAddress(address _newImpl) public onlyOwner {
        StakingPoolContract = _newImpl;
    }

    function setVestingContractAddress(address _newImpl) public onlyOwner {
        VestingContract = _newImpl;
    }

     function setTotalRewards() public onlyAdmin {
        

          StakingPool.setFixedReward(FixedRewardAmountReleased);

          StakingPool.setDynamicReward(DynamicAmountReleased);
         

    }

     
    
    function ReleaseFunds( uint256 _dynamicRewardAmount, uint256 _index) public onlyAdmin {
 
        
        bytes32 vestingScheduleId = AutoTransfer.computeVestingScheduleIdForAddressAndIndex(StakingPoolContract, _index);

        FixedRewardAmountReleased = AutoTransfer.computeReleasableAmount(vestingScheduleId);
  
        FixedRewardAmountReleased = computeReleasableAmount(vestingScheduleId);

        AutoTransfer.TransferFixedReleasableAmount(StakingPoolContract, _index);

        DynamicAmountReleased = _dynamicRewardAmount;

        AutoTransfer.TransferDynamicAmount(StakingPoolContract, _dynamicRewardAmount);

 
    }

    function addAdmin(address _newAdmin) public onlyOwner {
        isAdmin[_newAdmin] = true;
        //emit adminAdded( _newAdmin);
    }

     function removeAdmin(address _adminAddress) public onlyOwner {
        isAdmin[_adminAddress] = false;
       // emit adminRemoved( _adminAddress);
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admins can call this function");
        _;
}
    
    
}
