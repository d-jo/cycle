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

contract utility {
	


}
