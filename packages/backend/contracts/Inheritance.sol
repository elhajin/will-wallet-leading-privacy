// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Inheritance {
    address public owner;
    uint256 public lockDuration;
    uint256 public totalShares;
    uint256 public lastActive;

    struct Beneficiary {
        address beneficiary;
        uint256 shares;
    }

    mapping(address => Beneficiary) public beneficiariesMap;
    address[] public beneficiaryAddresses;

    event FundsClaimed(address indexed beneficiary, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this method.");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
        lastActive = block.timestamp;
    }

    function addOrUpdateBeneficiary(address _beneficiary, uint256 _shares) external onlyOwner {
        require(_shares > 0, "Shares must be greater than 0");
        require(_shares <= 100, "Shares must be less than or equal to 100");

        if (beneficiariesMap[_beneficiary].beneficiary == address(0)) {
            beneficiaryAddresses.push(_beneficiary);
        } else {
            totalShares -= beneficiariesMap[_beneficiary].shares;
        }

        beneficiariesMap[_beneficiary] = Beneficiary(_beneficiary, _shares);
        totalShares += _shares;

        require(totalShares <= 100, "Total shares must be less than or equal to 100");
    }

    function removeBeneficiary(address _beneficiary) external onlyOwner {
        require(beneficiariesMap[_beneficiary].beneficiary != address(0), "Beneficiary not found");

        totalShares -= beneficiariesMap[_beneficiary].shares;
        delete beneficiariesMap[_beneficiary];

        for (uint256 i = 0; i < beneficiaryAddresses.length; i++) {
            if (beneficiaryAddresses[i] == _beneficiary) {
                beneficiaryAddresses[i] = beneficiaryAddresses[beneficiaryAddresses.length - 1];
                beneficiaryAddresses.pop();
                break;
            }
        }
    }

    function updateLastActive() external onlyOwner {
        lastActive = block.timestamp;
    }

    function claimFunds(address _token) external {
        require(block.timestamp >= lastActive + lockDuration, "Account is still active");
        require(beneficiariesMap[msg.sender].beneficiary != address(0), "Sender is not a beneficiary");

        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        uint256 shareAmount = (tokenBalance * beneficiariesMap[msg.sender].shares) / totalShares;

        IERC20(_token).transfer(msg.sender, shareAmount);
        emit FundsClaimed(msg.sender, shareAmount);
    }

    function changeLockDuration(uint256 _newLockDuration) external onlyOwner {
        lockDuration = _newLockDuration;
    }

    function getBeneficiaries() external view returns (Beneficiary[] memory) {
        Beneficiary[] memory beneficiariesList = new Beneficiary[](beneficiaryAddresses.length);

        for (uint256 i = 0; i < beneficiaryAddresses.length; i++) {
            beneficiariesList[i] = beneficiariesMap[beneficiaryAddresses[i]];
        }

        return beneficiariesList;
    }
}
