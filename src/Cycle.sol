pragma solidity ^0.4.2;

contract owned {
	address public owner;

	function owned() {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner {
		owner = newOwner;
	}
}

/*

*/
contract ERC20Interface {
	function totalSupply() constant returns (uint256 totalSupply);
	function balanceOf(address _owner) constant returns (uint256 balance);
	function transfer(address _to, uint256 _value) returns (bool success);
	function transferFrom(address _from, address _to, uint256 _amount) returns (bool success);
	function approve(address _spender, uint256 _value) returns (bool success);
	function allowance(address _owner, address _spender) constant returns (uint remaining);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract AIToken is owned, ERC20Interface {
	// ================================================
	// CONSTANTS
	// ================================================
	string public standard = 'ERC20';
	string public constant name = 'codename cycle';
	string public constant symbol = 'ccy';
	uint8 public constant decimals = 18;
	uint256 _totalSupply = 0xffffffff;

	
	// ================================================
	// ERC20 Variables
	// ================================================
	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowed;

	function AIToken() {
		balances[msg.sender] = _totalSupply;
	}

	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balances[_owner];
	}

	function transfer(address _to, uint256 _value) returns (bool success) {
		if((balances[msg.sender] > _value) && (balances[_to] + _value > balances[_to])) {
			balances[msg.sender] -= _value;
			balances[_to] += _value;
			Transfer(msg.sender, _to, _value);
			return true;
		}

		return false;
	}


	function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
		if(
			(balances[_from] > _amount) && 
			(balances[_to] + _amount > balances[_to]) && 
			(_amount<= allowed[_from][msg.sender])
		) {
			balances[_from] -= _amount;                          // Subtract from the sender
			balances[_to] += _amount;                            // Add the same to the recipient
			allowed[_from][msg.sender] -= _amount;
			Transfer(_from, _to, _amount);
			return true;
		}
		return false;
	}

	function approve(address _spender, uint256 _amount) returns (bool success) {
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
	}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function () {
		revert();     // Prevents accidental sending of ether
	}
}
