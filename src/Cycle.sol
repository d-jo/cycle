pragma solidity ^0.4.2;

contract owned {
	address public owner;

	function owned() {
		owner = msg.sender;
	}

	modifier onlyOwner {
		if (msg.sender != owner) throw;
		_;
	}

	function transferOwnership(address newOwner) onlyOwner {
		owner = newOwner;
	}
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract token {
	/* Public variables of the token */
	string public standard = 'cyc 0.1';
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;

	/* This creates an array with all balances */
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

	/* This generates a public event on the blockchain that will notify clients */
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Mint(address indexed to, uint256 value);

	/* Initializes contract with initial supply tokens to the creator of the contract */
	function token(
		uint256 initialSupply,
		string tokenName,
		uint8 decimalUnits,
		string tokenSymbol
	) {
		balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
		totalSupply = initialSupply;                        // Update total supply
		name = tokenName;                                   // Set the name for display purposes
		symbol = tokenSymbol;                               // Set the symbol for display purposes
		decimals = decimalUnits;                            // Amount of decimals for display purposes
	}

	/* Send coins */
	function transfer(address _to, uint256 _value) {
		if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
		if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
		balanceOf[msg.sender] -= _value;                     // Subtract from the sender
		balanceOf[_to] += _value;                            // Add the same to the recipient
		Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
	}

	/* Allow another contract to spend some tokens in your behalf */
	function approve(address _spender, uint256 _value) returns (bool success) {
		return true;
	}



	/* A contract attempts to get the coins */
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
		if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
		if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
		if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
		balanceOf[_from] -= _value;                          // Subtract from the sender
		balanceOf[_to] += _value;                            // Add the same to the recipient
		allowance[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;
	}

	/* This unnamed function is called whenever someone tries to send ether to it */
	function () {
		throw;     // Prevents accidental sending of ether
	}
}

contract Cycle is owned, token {

	mapping (address => bool) public frozenAccount;


	/* This generates a public event on the blockchain that will notify clients */
	event FrozenFunds(address target, bool frozen);


	/* Initializes contract with initial supply tokens to the creator of the contract */
	function Cycle(
		uint256 initialSupply,
		string tokenName,
		uint8 decimalUnits,
		string tokenSymbol
	) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

	/* Send coins */
	function transfer(address _to, uint256 _value) {
		if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
		if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
		if (frozenAccount[msg.sender]) throw;                // Check if frozen
		balanceOf[msg.sender] -= _value;                     // Subtract from the sender
		balanceOf[_to] += _value;                            // Add the same to the recipient
		Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
	}

	/* A contract attempts to get the coins */
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
		if (frozenAccount[_from]) throw;                        // Check if frozen            
		if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
		if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
		if (_value > allowance[_from][msg.sender]) throw;   // Check allowance
		balanceOf[_from] -= _value;                          // Subtract from the sender
		balanceOf[_to] += _value;                            // Add the same to the recipient
		allowance[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;
	}

	function freezeAccount(address _target, bool _freeze) onlyOwner {
		frozenAccount[_target] = _freeze;
		FrozenFunds(_target, _freeze);
	}

	function mint(address _target, uint256 _value) onlyOwner returns (bool success) {
		if (frozenAccount[_target]) throw;
		if (balanceOf[_target] + _value < balanceOf[_target]) throw;
		totalSupply += _value;
		balanceOf[_target] += _value;
		Mint(_target, _value);
		return true;
	}



}
