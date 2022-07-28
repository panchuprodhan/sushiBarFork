// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// SushiBar is the coolest bar in town. You come in with some Sushi, and leave with more! The longer you stay, the more Sushi you get.
//
// This contract handles swapping to and from xSushi, SushiSwap's staking token.
contract SushiBar is ERC20("SushiBar", "xSUSHI") {
    using SafeMath for uint256;
    IERC20 public sushi;

    struct Stake {
        uint amount;
        address user;
        uint stakedOn;
        // uint unstakableAmount;
    }
    Stake stake;
    mapping(address => uint) internal stakes;
    mapping(address => Stake) internal stakeCheck;
    address[] public stake_result;

    uint public tax;
    
    // Define the Sushi token contract
    constructor(IERC20 _sushi) public {
        sushi = _sushi;
    }

    // Enter the bar. Pay some SUSHIs. Earn some shares.
    // Locks Sushi and mints xSushi
    function enter(uint256 _amount) public {
        // Gets the amount of Sushi locked in the contract
        uint256 totalSushi = sushi.balanceOf(address(this));
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply();
        // If no xSushi exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalSushi == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xSushi the Sushi is worth. The ratio will change overtime, as xSushi is burned/minted and Sushi deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalSushi);
            _mint(msg.sender, what);
        }
        // Lock the Sushi in the contract
        sushi.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your SUSHIs.
    // Unlocks the staked + gained Sushi and burns xSushi
    function leave(uint256 _share) public {
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Sushi the xSushi is worth
        uint256 what = _share.mul(sushi.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        sushi.transfer(msg.sender, what);
    }

    function stakedAmount(uint _amount) public {
        stake.amount = _amount;
        stake.user = msg.sender;
        stake.stakedOn = block.timestamp;
        stakes[msg.sender] = stakes[msg.sender].add(_amount);
        stake_result.push(msg.sender);
    }

    function unstakeDetails(uint _amount) public {
        uint stakeDay = stake.stakedOn;
        uint unstakeDay = block.timestamp;
        require(stakes[msg.sender] >= _amount, "Please enter a valid amount to be unstaked");
        uint unstakableAmount;
        uint withdrawableAmount;
        if (unstakeDay > (stakeDay + 8 days)) {
            unstakableAmount = stakes[msg.sender];
            withdrawableAmount = unstakableAmount - (unstakableAmount - _amount);
            tax = _amount * 0;
            transfer(msg.sender, unstakableAmount - tax);
            transfer(address(this), tax);
        }
        else if ((unstakeDay <= (stakeDay + 8 days)) && (unstakeDay > (stakeDay + 6 days))) {
            unstakableAmount = stakes[msg.sender] * 75 / 100;
            require(_amount <= unstakableAmount, "Amount withdraw unavailable");
            withdrawableAmount = unstakableAmount - (unstakableAmount - _amount);
            tax = _amount * 25 / 100;
            transfer(msg.sender, unstakableAmount - tax);
            transfer(address(this), tax);
        }
        else if ((unstakeDay <= (stakeDay + 6 days)) && (unstakeDay > (stakeDay + 4 days))) {
            unstakableAmount = stakes[msg.sender] * 50 / 100;
            require(_amount <= unstakableAmount, "Amount withdraw unavailable");
            withdrawableAmount = unstakableAmount - (unstakableAmount - _amount);
            tax = _amount * 50 / 100;
            transfer(msg.sender, unstakableAmount - tax);
            transfer(address(this), tax);
        }
        else if ((unstakeDay <= (stakeDay + 4 days)) && (unstakeDay > (stakeDay + 2 days))) {
            unstakableAmount = stakes[msg.sender] * 25 / 100;
            require(_amount <= unstakableAmount, "Amount withdraw unavailable");
            withdrawableAmount = unstakableAmount - (unstakableAmount - _amount);
            tax = _amount * 75 / 100;
            transfer(msg.sender, unstakableAmount - tax);
            transfer(address(this), tax);
        }
        else if (unstakeDay <= (stakeDay + 2 days)) {
            unstakableAmount = stakes[msg.sender] * 0;
            require(_amount <= unstakableAmount, "Amount withdraw unavailable");
            withdrawableAmount = unstakableAmount - (unstakableAmount - _amount);
            transfer(msg.sender, unstakableAmount - tax);
            transfer(address(this), tax);
        }
    }

    function stakeOf() public view returns(address[] memory) {
        return stake_result;
    }

}
