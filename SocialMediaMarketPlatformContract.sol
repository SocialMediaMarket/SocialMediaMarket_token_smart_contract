pragma solidity ^0.4.24;

import "./tokens\social.sol";

contract MyToken is SocialMediaToken {}


contract SocialMediaMarket {

    MyToken private _token;

    address public owner;
    address public platform;
    uint8 public decimals;
    uint8 public percent;

    struct Item {
        uint256 amount;
        address adv_address;
        address inf_address;
        int8 status;
    }

    mapping(uint64 => Item) public items;

    event InitiatedEscrow(uint64 indexed id, uint256 _amount, address adv_address, address inf_address, uint256 _time);
    event Withdraw(uint64 indexed id, uint256 _amount, address _person, address _platform, uint8 _percent, uint256 _time);
    event Payback(uint64 indexed id, uint256 _amount, address _person, uint256 _time);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(address tokenAddress, address platformAddress, uint8 percentPayout) public {
        owner = msg.sender;
        platform = platformAddress;
        percent = percentPayout;

        _token = MyToken(tokenAddress);
        decimals = _token.decimals();
    }

    function initiateEscrow(uint64 id, uint256 amount, address adv_address, address inf_address) onlyOwner public returns (bool success) {
        if (items[id].amount > 0) {
            return false;
        }
        if (_token.allowance(adv_address, address(this)) < amount) {
            return false;
        }
        require(_token.transferFrom(adv_address, address(this), amount));

        items[id] = Item(amount, adv_address, inf_address, 0);

        emit InitiatedEscrow(id, amount, adv_address, inf_address, block.timestamp);
        return true;
    }

    function withdraw(uint64 id) onlyOwner public returns (bool success) {
        if (items[id].amount > 0) {
            if (items[id].status == 0) {
                require(_token.transfer(items[id].inf_address, items[id].amount * (100 - percent) / 100));
                require(_token.transfer(platform, items[id].amount * percent / 100));
                items[id].status = 1;

                emit Withdraw(id, items[id].amount, items[id].inf_address, platform, percent, block.timestamp);
                return true;
            }
        }

        return false;
    }

    function payback(uint64 id) onlyOwner public returns (bool success) {
        if (items[id].amount > 0) {
            if (items[id].status == 0) {
                require(_token.transfer(items[id].adv_address, items[id].amount));
                items[id].status = - 1;

                emit Payback(id, items[id].amount, items[id].adv_address, block.timestamp);
                return true;
            }
        }
        return false;
    }

    function changePlatform(address platformAddress) onlyOwner public returns (bool success) {
        if (platformAddress == platform) {
            return false;
        }
        else if (platformAddress != 0x0) {
            return false;
        }
        platform = platformAddress;
        return true;
    }

}