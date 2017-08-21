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

	mapping (address => bool) public frozenAccount;
	mapping (bytes32 => Job) internal jobs;
	mapping (bytes32 => SolutionManager) internal solutions;
	JobManager m;

	uint OpenJobs = 0;

	/* This generates a public event on the blockchain that will notify clients */
	event FrozenFunds(address target, bool frozen);
	event JobCreated(bytes32 id, address creator);


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
		bool active;
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
	
	/*
		Calculate the cost of a job //TODO
	*/	
	function cost(uint size) internal returns (uint) {
		return size * 2;
	}


	/*
		Returns work for the miner to do
	*/
	function GetWork() {
		// here is where we update the state of the JobManager to move jobs from the queue to the active pool. jobs should be grabbed from the active pool at random, jobs can only be cashed once per instance.
	}	

	/*
		Create a job using the data provided. Data should be in numpy matrix form. 
	        Op values: conv
	*/
	function CreateJob(string data1, string data2, string op) external returns (bool success) {
		Job memory j;
		j.cost = cost(bytes(data1).length + bytes(data2).length);
		if(balanceOf[msg.sender] < j.cost) return false;
		if(balanceOf[msg.sender] - j.cost > balanceOf[msg.sender]) return false;
		/* when we create the job id, we only use the data and operation. by doing this, identical problems will have identical ids */
		j.id = keccak256(data1, data2, op);
		j.owner = msg.sender;
		j.time = block.timestamp;
		j.data1 = data1;
		j.data2 = data2;
		j.op = op;
		balanceOf[msg.sender] -= j.cost;
		jobs[j.id] = j;
		push(m, j.id);
		SolutionManager memory sm;
		sm.solves = 0;
		sm.max = 32;
		solutions[j.id] = sm;
		JobCreated(j.id, msg.sender);
		return true;
	}
	
	/*
		Submit a solution to a job. 
	       	
		id - target job id
	       	solution - numpy string representing resulting matrix
	       	pow - a hash proving the submitter did work on thr problem.
	*/
	function SolveJob(bytes32 id, string solution, bytes32 pow) external returns (bool success){
		if(!solutions[id].active) return false; // the solution manager is not accepting solutions
		
		/* all we care is that that the address that submitted the solution did work. if the same work is submitted multiple time and this miner has seen it before, who cares that they did the work in the way past. 
		*/
		bytes32 hash = keccak256(id, msg.sender, solution); // calculate job hash

		require(hash == pow); // proof of work was not correct
		SolutionManager storage sm = solutions[id];
		Solution memory s;
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
		require(balanceOf[msg.sender] > _value);           // Check if the sender has enough
		require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
		require(!frozenAccount[msg.sender]);                // Check if frozen
		balanceOf[msg.sender] -= _value;                     // Subtract from the sender
		balanceOf[_to] += _value;                            // Add the same to the recipient
		Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
	}

	/* A contract attempts to get the coins */
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
		require(!frozenAccount[_from]);                        // Check if frozen            
		require(balanceOf[_from] > _value);                 // Check if the sender has enough
		require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
		require(_value < allowance[_from][msg.sender]);   // Check allowance
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
		require(!frozenAccount[_target]);
		require(balanceOf[_target] + _value > balanceOf[_target]);
		totalSupply += _value;
		balanceOf[_target] += _value;
		Mint(_target, _value);
		return true;
	}



}
