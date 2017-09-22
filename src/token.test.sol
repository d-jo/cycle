pragma solidity ^0.4.2;

import "ds-test/test.sol";
import "src/token.sol";

contract TokenActor {
	
	AIToken token;

	function TokenActor(AIToken token_) {
		token = token_;
	}

	function doTransfer(address to, uint256 amount) returns (bool) {
		return token.transfer(to, amount);
	}

	function doBalance(address owner) returns (uint) {
		return token.balanceOf(owner);
	}

}


contract TestContract is DSTest {
	
	AIToken token;
	TokenActor actor;
	TokenActor actor2;
	
	function setUp() {
		token = new AIToken();
		actor = new TokenActor(token);
		actor2 = new TokenActor(token);
		token.transfer(actor2, 1337);
	}
	
	function testTotalSupply() {
		assertEq(token.totalSupply(), 0xffffffff);
	}

	function testBalanceOf() {
		assertEq(token.balanceOf(actor), 0);
		assertEq(token.balanceOf(actor2), 1337);
	}

	function testTransfer() {
		uint256 prebalance = actor.doBalance(this);
		assert(token.transfer(actor, 100));
		assertEq(actor.doBalance(this), prebalance - 100);
		assertEq(token.balanceOf(actor), 100);
		assert(actor.doTransfer(token, 50));
		assertEq(token.balanceOf(actor), 50);
	}

	function testFailBadTransfer() {
		assert(actor.doTransfer(actor2, 0));
	}

	
	
	

}
