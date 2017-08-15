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
	mapping (bytes32 => Job) internal jobs;
	mapping (bytes32 => SolutionManager) internal solutions;
	JobManager m;

	uint OpenJobs = 0;

	/* This generates a public event on the blockchain that will notify clients */
	event FrozenFunds(address target, bool frozen);


	/* Initializes contract with initial supply tokens to the creator of the contract */
	function Cycle(
		uint256 initialSupply,
		string tokenName,
		uint8 decimalUnits,
		string tokenSymbol
	) token (initialSupply, tokenName, decimalUnits, tokenSymbol) {
		m.data.length = 10000;
	}

	struct JobManager {
		bytes32[] data;
		uint front;
		uint back;
		bytes32[] activeJobs;
	}
	
	struct SolutionManager {
		Solution[] allSolutions;
		uint solves;
		uint max;
	}

	struct Solution {
		bytes32 hash;
		address submitter;
		string data;
		bool exists;
	}

	struct Job {
		bytes32 id;
		address owner;
		uint cost;
		uint time;
		string data1;
		string data2;
		string op;
		
	}
	
	function cost(uint size) internal returns (uint) {
		return size * 2;
	}

	function CreateJob(string data1, string data2, string op) external returns (bool success) {
		Job j;
		j.cost = cost(bytes(data1).length + bytes(data2).length);
		if(balanceOf[msg.sender] < j.cost) return false;
		if(balanceOf[msg.sender] - j.cost > balanceOf[msg.sender]) return false;
		j.id = keccak256(data1, data2, op);
		j.owner = msg.sender;
		j.time = block.timestamp;
		j.data1 = data1;
		j.data2 = data2;
		j.op = op;
		balanceOf[msg.sender] -= j.cost;
		jobs[j.id] = j;
		push(m, j.id);
		SolutionManager sm;
		sm.allSolutions.length = 32;
		sm.solves = 0;
		sm.max = 32;
		solutions[j.id] = sm;
		return true;
	}

	function SolveJob(bytes32 id, string solution, bytes32 pow) external returns (bool success){
		bytes32 hash = keccak256(id, msg.sender, solution);
		if(hash != pow) throw; // proof of work was not correct
		SolutionManager sm = solutions[id];
		Solution s;
		s.hash = hash;
		s.submitter = msg.sender;
		s.data = solution;
		s.exists = true;
		sm.allSolutions.push(s);
		
		if(sm.solves == sm.max) {
			//job is done
		}
	}

	function push(JobManager storage q, bytes32 data) internal {
		if ((q.back + 1) % q.data.length == q.front)
			return; // throw;
		q.data[q.back] = data;
		q.back = (q.back + 1) % q.data.length;
	}

	function pop(JobManager storage q) internal returns (bytes32 r) {
		if (q.back == q.front)
			return; // throw;
		r = q.data[q.front];
		delete q.data[q.front];
		q.front = (q.front + 1) % q.data.length;
	}

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
