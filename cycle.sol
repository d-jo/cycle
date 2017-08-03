pragma solidity ^0.4.2;

contract owned {
    address public owner;
    address public manager;

    function owned() {
      owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    modifier onlyManager {
	if (msg.sender != ownder) throw;
	if (msg.sender != manager) throw;
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
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {    
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
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

contract Cyc is owned, token {

    uint8 VERSION = 1;
    uint8 COST_PER_BYTE = 1;
    

    mapping (address => bool) public frozenAccount;

    mapping (bytes32 => bytes) storage public jobs;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    event JobCompleted(bytes32 indexed job, address[] indexed solvers, uint256 reward);
    

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Cyc(
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

    function cost(uint numOfBytes) returns (uint cost) {
	return numOfBytes * COST_PER_BYTE;
    }

    function submitJob(bytes4 memory _operation, bytes memory _mat1, _mat2, uint _extraReward) returns (bool success) {
	if (frozenAccount[msg.sender]) throw;
	uint memory size = 196 + _mat1.length + _mat2.length;
	if (balanceOf[msg.sender] < cost(size) + _extraReward) throw;
	
	bytes32 memory jobid = keccak256(msg.sender, jobs.length, VERSION, block.timestamp, _operation, _mat1, _mat2);
	bytes memory fulljob = new bytes(size);
	uint memory size1 = _mat1.length;
	uint memory size2 = _mat2.length;
	uint memory offset = 0;
	
	assembly {
		// --------------------------
		// the goal of this block is to construct the full job.
		// it is done in assembly to speed up the process for more
		// fine tuned control. All it does copy data, move offset by 
		// the size of data, then repeat. 
		// --------------------------
		// OPERATION    ------- BYTES
		// STORE SENDER 	(32b)
		mstore(add(fulljob, add(mload(offset), 32)), msg.sender)
		// MOVE OFFSET 		(32)
		mstore(add(offset, 32), add(mload(offset), 32))
		// STORE VERSION 	(32b)
		mstore(add(fulljob, add(mload(offset), 32)), VERSION)
		// MOVE OFFSET 		(32)
		mstore(add(offset, 32), add(mload(offset), 32))
		// STORE TIMESTAMP 	(32b)
		mstore(add(fulljob, add(mload(offset), 32)), block.timestamp)
		// MOVE OFFSET 		(32)
		mstore(add(offset, 32), add(mload(offset), 32))
		// STORE OPERATION 	(4b)
		mstore(add(fulljob, add(mload(offset), 4)), _operation)
		// MOVE OFFSET 		(4)
		mstore(add(offset, 32), add(mload(offset), 4))
		// STORE SIZE1 		(32b)
		mstore(add(fulljob, add(mload(offset), 32)), size1)
		// MOVE OFFSET 		(32)
		mstore(add(offset, 32), add(mload(offset), 32))
		// STORE SIZE2 		(32b)
		mstore(add(fulljob, add(mload(offset), 32)), size2)
		// MOVE OFFSET 		(32)
		mstore(add(offset, 32), add(mload(offset), 32))
		// STORE DATA1		(size1b)
		mstore(add(fulljob, add(mload(offset), mload(size1))), _mat1)
		// MOVE OFFSET 		(size1)
		mstore(add(offset, 32), add(mload(offset), mload(size1)))
		// STORE DATA2		(size2b)
		mstore(add(fulljob, add(mload(offset), mload(size2))), _mat2)
		// MOVE OFFSET 		(size2)
		mstore(add(offset, 32), add(mload(offset), mload(size2)))
		// STORE JOBID		(32b)
		mstore(add(fulljob, add(mload(offset), 32)), jobid)
	}
	
	jobs[jobid] = fulljob;
	
	return true;
    }

    function getJob() external returns (bytes32 jobid, bytes jobdata) {
	
    }

    function mint(address _target, uint256 _value) onlyManager returns (bool success) {
	if (frozenAccount[_target]) throw;
	if (balanceOf[_target] + _value < balanceOf[_target]) throw;
	totalSupply += _value;
	balanceOf[_target] += _value;
	Mint(_target, _value)
	return true;
    }


}
