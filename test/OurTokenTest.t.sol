// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;
    uint256 public constant STARTING_BALANCE = 100 ether;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                                TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function testBobBalance() external {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testDirectTransfer() external {
        uint256 amount = 10 ether;

        vm.prank(bob);
        ourToken.transfer(alice, amount);

        assertEq(ourToken.balanceOf(alice), amount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - amount);
    }

    function testTransferFailsIfInsufficientBalance() external {
        uint256 amount = STARTING_BALANCE + 1 ether;

        vm.prank(bob);
        vm.expectRevert();
        ourToken.transfer(alice, amount);
    }

    function testTransferToZeroAddressShouldRevert() external {
        vm.prank(bob);
        vm.expectRevert();
        ourToken.transfer(address(0), 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                            ALLOWANCE TESTS
    //////////////////////////////////////////////////////////////*/

    function testApproveAndTransferFrom() external {
        uint256 allowanceAmount = 100 ether;
        uint256 transferAmount = 40 ether;

        vm.prank(bob);
        ourToken.approve(alice, allowanceAmount);

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(ourToken.allowance(bob, alice), allowanceAmount - transferAmount);
    }

    function testCannotTransferFromWithoutApproval() external {
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(bob, alice, 1 ether);
    }

    function testCannotTransferFromMoreThanApproved() external {
        vm.prank(bob);
        ourToken.approve(alice, 1 ether);

        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(bob, alice, 2 ether);
    }

    function testApproveToZeroAddressShouldRevert() external {
        vm.prank(bob);
        vm.expectRevert();
        ourToken.approve(address(0), 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                              TOTAL SUPPLY
    //////////////////////////////////////////////////////////////*/

    function testTotalSupplyConstant() external {
        uint256 expectedTotal = ourToken.totalSupply();
        assertEq(expectedTotal, ourToken.balanceOf(msg.sender) + ourToken.balanceOf(bob));
    }

    /*//////////////////////////////////////////////////////////////
                               EDGE CASES
    //////////////////////////////////////////////////////////////*/

    function testZeroTransferDoesNothing() external {
        vm.prank(bob);
        ourToken.transfer(alice, 0);
        assertEq(ourToken.balanceOf(alice), 0);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
    }

    function testApproveOverrides() external {
        vm.prank(bob);
        ourToken.approve(alice, 2 ether);

        vm.prank(bob);
        ourToken.approve(alice, 5 ether); // overrides previous

        assertEq(ourToken.allowance(bob, alice), 5 ether);
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    function testApproveEmitsEvent() external {
        uint256 amount = 42 ether;

        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit Approval(bob, alice, amount);

        ourToken.approve(alice, amount);
    }

    function testTransferEmitsEvent() external {
        uint256 amount = 1 ether;

        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit Transfer(bob, alice, amount);
        ourToken.transfer(alice, amount);
    }
}
