// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface StakingPoolInterface {
    function setFixedReward(uint256 _fixedReward) external;
    function setDynamicReward(uint256 _dynamicReward) external;
}


interface AutoTransferInterface {

    function TransferFixedReleasableAmount(address _beneficiaryAddress, uint256 _indexNumber) external;

    function TransferDynamicReleaseableAmount(address _beneficiaryAddress, uint256 _amount) external;

    function DepositTokensInFixedRewardPool(uint256 _amount) external;

    function DepositTokensInDynamicRewardPool(uint256 _amount) external;
    
    function computeReleasableAmount(bytes32 vestingScheduleId) external view returns (uint256);
    function computeVestingScheduleIdForAddressAndIndex(address holder, uint256 index) external pure returns (bytes32);

    function addAdmin(address _newAdmin) external;
}

 

contract Proxy  {
    address public owner;
 

    AutoTransferInterface public AutoTransfer;

    StakingPoolInterface public StakingPoolContract;
 

    mapping(address => bool) public isAdmin;  

    //uint256 FixedRewardAmountReleased;
    //uint256 DynamicAmountReleased;
    address stakingPoolContractAddress;
     
    constructor(address _StakingPoolContract, address _Vesting) {
        owner = msg.sender;
        isAdmin[msg.sender] = true;
        StakingPoolContract = StakingPoolInterface(_StakingPoolContract);
        AutoTransfer = AutoTransferInterface(_Vesting);
        
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }


    function setStakingPoolContractAddress(address _newImpl) public onlyOwner {
        StakingPoolContract = StakingPoolInterface(_newImpl);
        stakingPoolContractAddress = _newImpl;
    }

    function setAutoTransferAddress(address _newImpl) public onlyOwner {
        
         AutoTransfer = AutoTransferInterface(_newImpl);

    }



     
    
    function ReleaseFunds( uint256 _dynamicRewardAmount, uint256 _index) public onlyAdmin {
        
        bytes32 vestingScheduleId = AutoTransfer.computeVestingScheduleIdForAddressAndIndex(stakingPoolContractAddress,_index);

        uint256 FixedRewardAmountReleased = AutoTransfer.computeReleasableAmount(vestingScheduleId); 

        AutoTransfer.TransferFixedReleasableAmount(stakingPoolContractAddress, _index);

        StakingPoolContract.setFixedReward(FixedRewardAmountReleased);

        uint256 DynamicAmountReleased = _dynamicRewardAmount;

        AutoTransfer.TransferDynamicReleaseableAmount(stakingPoolContractAddress, _dynamicRewardAmount);

        StakingPoolContract.setDynamicReward(DynamicAmountReleased); 
 
    }

    function addAdmin(address _newAdmin) public onlyOwner {
        isAdmin[_newAdmin] = true;
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
