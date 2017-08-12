pragma solidity ^0.4.13;

import "ds-test/test.sol";

import "./Cycle.sol";

contract BackendTest is DSTest {
    Backend backend;

    function setUp() {
        backend = new Backend();
    }

    function testFail_basic_sanity() {
        assert(false);
    }

    function test_basic_sanity() {
        assert(true);
    }
}
