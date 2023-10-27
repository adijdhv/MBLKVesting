// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.19;

import "./VESTING.sol";
 

contract AutoTransfer is MBLKVesting {
    uint256 FixedRewards;
    uint256 DynamicRewards;
    ERC20 public  mblkToken;
     bool isReleasor;

    constructor(address _mblkTokenAddress) MBLKVesting(_mblkTokenAddress) {
        mblkToken = ERC20(_mblkTokenAddress);
        isAdmin[msg.sender] = true;
    }

    mapping(address => bool) public isAdmin;

 

    function TransferFixedReleasableAmount(address _beneficiaryAddress, uint256 _indexNumber ) public onlyAdmin{
        bytes32 vestingScheduleId = computeVestingScheduleIdForAddressAndIndex( _beneficiaryAddress,_indexNumber );
        
        MBLKVesting.getVestingSchedule(vestingScheduleId);

        VestingSchedule memory vestingSchedule = MBLKVesting.getVestingSchedule(vestingScheduleId);

        if(isAdmin[msg.sender]){
            isReleasor = true;
        }else{
            isReleasor = false;
        }
          

        require(
            isReleasor,
            "TokenVesting: only admins can release vested tokens"
        );


         uint256 releasableAmount =  _computeReleasableAmount(vestingSchedule); 


        vestingSchedule.released = vestingSchedule.released + releasableAmount;
 

        //FixedRewards = FixedRewards - vestedAmount;
        // mblkToken.Transfer(
        //     beneficiaryPayable,
        //     releasableAmount
        // );
        mblkToken.transfer(  _beneficiaryAddress, releasableAmount);

        FixedRewards -= releasableAmount;
    }

    function TransferDynamicReleaseableAmount(
        address _beneficiaryAddress,
        uint256 _amount
    ) public onlyAdmin {
         if(isAdmin[msg.sender]){
            isReleasor = true;
        }else{
            isReleasor = false;
        }
        require(
            isReleasor,
            "TokenVesting: only Admins can release vested tokens"
        );
        mblkToken.transfer(  _beneficiaryAddress, _amount);
        DynamicRewards -= _amount;
    }

    function DepositTokensInFixedRewardPool(uint256 _amount) public onlyOwner {
        mblkToken.transfer(  address(this), _amount);
        FixedRewards += _amount;
    }

    function DepositTokensInDynamicRewardPool(
        uint256 _amount
    ) public onlyOwner {
       mblkToken.transfer(address(this), _amount);
        DynamicRewards += _amount;
    }

    function addAdmin(address _newAdmin) public onlyOwner {
        isAdmin[_newAdmin] = true;
        //emit adminAdded( _newAdmin);
    }
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admins can call this function");
        _;
}
}
