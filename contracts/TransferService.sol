//SPDX-License-Identifier: Unlicense
pragma solidity ^0.5.10;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract TransferService is Ownable{
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    Fee[] fees;
    address treasure;
    event Transfer(
        address token,
        address sender,
        address recipient,
        uint256 amount,
        uint256 fee
    );

    event AddFee(
        uint256 from,
        uint256 to,
        uint8 value
    );

    struct Fee{
        uint256 from;
        uint256 to;
        uint8 value;
    }

    constructor(address _treasure) public{
        setupTreasure(_treasure);
        _addFee(0, 100, 1);
        _addFee(100, 1000, 2);
        _addFee(1000, 0, 3);
    }

    function createTransfer(address _token, address _from, address _recipient, uint256 _amount) external {
        uint256 _feeRate = getFee(_amount);
        uint256 _fee = _amount.mul(_feeRate).div(100);
        uint256 _amountAfterFee = _amount.sub(_fee);
        IERC20(_token).safeTransferFrom(_from, _recipient, _amountAfterFee);
        if(_fee > 0)
            IERC20(_token).safeTransferFrom(_from, treasure, _fee);
        emit Transfer(_token, _from, _recipient, _amount, _fee);
    }

    function getFee(uint256 _amount) public view returns(uint8){
        for (uint i=0; i<fees.length; i++) {
            Fee memory _fee = fees[i];
            if(_amount >= _fee.from && (_fee.to == 0 || _amount < _fee.to)){
                return _fee.value;
            }
        }
        return 0;
    }

    function _addFee(uint256 _from, uint256 _to, uint8 _fee) internal {
        fees.push(Fee(_from, _to, _fee));
        emit AddFee(_from, _to, _fee);
    }

    function getBalances(address _account, address[] calldata _tokens) external view returns (uint256[] memory){
        uint[] memory _balances = new uint[](_tokens.length);
        for (uint i=0; i<fees.length; i++) {
            _balances[i] = IERC20(_tokens[i]).balanceOf(_account);
        }
        return _balances;
    }

    function setupTreasure(address _treasure) public onlyOwner{
        treasure = _treasure;
    }
}
