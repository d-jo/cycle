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


contract token {
	/* Public variables of the token */
	string public standard = 'ERC20';
	string public constant name = 'codename cycle';
	string public constant symbol = 'ccy';
	uint8 public constant decimals = 18;
	uint256 public totalSupply;

	/* This creates an array with all balances */
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

	/* This generates a public event on the blockchain that will notify clients */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function token(uint256 initialSupply) {
		balanceOf[msg.sender] = initialSupply;	// Give the creator all initial tokens
		totalSupply = initialSupply;		// Update total supply
	}

	/* Send coins */
	function transfer(address _to, uint256 _value) {
		require(balanceOf[msg.sender] > _value);           // Check if the sender has enough
		require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
		balanceOf[msg.sender] -= _value;                     // Subtract from the sender
		balanceOf[_to] += _value;                            // Add the same to the recipient
		Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
	}


	/* A contract attempts to get the coins */
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
		require(balanceOf[_from] > _value);                 // Check if the sender has enough
		require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
		require(_value <= allowance[_from][msg.sender]);   // Check allowance
		balanceOf[_from] -= _value;                          // Subtract from the sender
		balanceOf[_to] += _value;                            // Add the same to the recipient
		allowance[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;
	}

	/* This unnamed function is called whenever someone tries to send ether to it */
	function () {
		revert();     // Prevents accidental sending of ether
	}
}

contract Cycle is owned, token {

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function Cycle(uint256 initialSupply) token (initialSupply) {

	}

	/* Send coins */
	function transfer(address _to, uint256 _value) {
		require(balanceOf[msg.sender] > _value);           // Check if the sender has enough
		require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
		balanceOf[msg.sender] -= _value;                     // Subtract from the sender
		balanceOf[_to] += _value;                            // Add the same to the recipient
		Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
	}

	/* A contract attempts to get the coins */
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
		require(balanceOf[_from] > _value);                 // Check if the sender has enough
		require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
		require(_value < allowance[_from][msg.sender]);   // Check allowance
		balanceOf[_from] -= _value;                          // Subtract from the sender
		balanceOf[_to] += _value;                            // Add the same to the recipient
		allowance[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;
	}




}
