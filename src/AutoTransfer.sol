pragma solidity ^0.8.19;

import "./MBLKTokenVesting.sol";

contract AutoTransfer is MBLKVesting {
    uint256 FixedRewards;
    uint256 DynamicRewards;

    constructor(address _mblkTokenAddress) MBLKVesting(_mblkTokenAddress) {
        isAdmin[msg.sender] = true;
    }

    mapping(address => bool) public isAdmin;

    function TransferFixedReleasableAmount(
        _beneficiaryAddress,
        _index
    ) public onlyAdmin {
        bytes32 vestingScheduleId = getVestingScheduleByAddressAndIndex(
            _beneficiaryAddress,
            _index
        );

        VestingSchedule storage vestingSchedule = vestingSchedules[
            vestingScheduleId
        ];

        bool isReleasor = (msg.sender == Admin);

        require(
            isReleasor,
            "TokenVesting: only admins can release vested tokens"
        );

        uint256 releasableAmount = _computeReleasableAmount(vestingScheduleId);

        vestingSchedule.released = vestingSchedule.released + releasableAmount;

        address payable beneficiaryPayable = payable(
            vestingSchedule.beneficiary
        );

        //FixedRewards = FixedRewards - vestedAmount;
        SafeTransferLib.safeTransfer(
            _token,
            beneficiaryPayable,
            releasableAmount
        );
        FixedRewards -= releasableAmount;
    }

    function TransferDynamicReleaseableAmount(
        _beneficiaryAddress,
        _amount
    ) public onlyAdmin {
        bool isReleasor = (msg.sender == Admin);
        require(
            isReleasor,
            "TokenVesting: only Admins can release vested tokens"
        );
        SafeTransferLib.safeTransfer(_token, beneficiaryPayable, _amount);
        DynamicRewards -= _amount;
    }

    function DepositTokensInFixedRewardPool(uint256 _amount) public onlyOwner {
        SafeTransferLib.safeTransfer(_token, address(this), _amount);
        FixedRewards += _amount;
    }

    function DepositTokensInDynamicRewardPool(
        uint256 _amount
    ) public onlyOwner {
        SafeTransferLib.safeTransfer(_token, address(this), _amount);
        DynamicRewards += _amount;
    }

    function addAdmin(address _newAdmin) public onlyOwner {
        isAdmin[_newAdmin] = true;
        //emit adminAdded( _newAdmin);
    }
}
