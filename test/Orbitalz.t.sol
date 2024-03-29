// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";
import {
    Orbitalz, BigBangNotStarted, UniverseExpansionLimit, RobotzCantMint, BlackHoleError
} from "../src/Orbitalz.sol";

contract OrbitalzTest is Test {
    Orbitalz orbitalz;

    function setUp() public {
        orbitalz = new Orbitalz("placeholder/");
    }

    function testName() public {
        assertEq(orbitalz.name(), "Orbitalz");
    }

    function testSymbol() public {
        assertEq(orbitalz.symbol(), "ORBITALZ");
    }

    function testOwner() public {
        assertEq(orbitalz.owner(), address(this));
    }

    function testWalletLimit() public {
        assertEq(orbitalz.WALLET_LIMIT(), 3);
    }

    function testTotalSupply() public {
        assertEq(orbitalz.TOTAL_SUPPLY(), 10_000);
    }

    function testAfterBigBang() public {
        assertEq(orbitalz.afterBigBang(), false);
    }

    function testbaseURI() public {
        orbitalz = new Orbitalz("placeholder/");
        assertEq(orbitalz.baseURI(), "placeholder/");
    }

    function testTokenURI() public {
        orbitalz.setAfterBigBang(true);
        address minter = vm.addr(1);
        vm.prank(minter, minter);
        orbitalz.bigBang();

        assertEq(orbitalz.tokenURI(0), "placeholder/0");
    }

    function testBigBang() public {
        orbitalz.setAfterBigBang(true);
        address minter = vm.addr(1);
        vm.prank(minter, minter);

        orbitalz.bigBang();
        assertEq(orbitalz.balanceOf(minter), 3);
    }

    function testCannotBigBangWithoutAfterBigBang() public {
        vm.expectRevert(BigBangNotStarted.selector);
        orbitalz.bigBang();
    }

    function testCannotBigBangIfMintLimit() public {
        orbitalz.setAfterBigBang(true);

        // mint 10_000 orbitalz
        for (uint256 i = 0; i < 3_334; i++) {
            // Force msg.sender == tx.origin
            vm.prank(vm.addr(i + 1), vm.addr(i + 1));
            orbitalz.bigBang();
        }

        assertEq(orbitalz.totalSupply(), 10_000);
        assertEq(orbitalz.balanceOf(vm.addr(3_334)), 1);

        // Force msg.sender == tx.origin
        vm.prank(vm.addr(3_335), vm.addr(3_335));
        vm.expectRevert(UniverseExpansionLimit.selector);
        orbitalz.bigBang();
        assertEq(orbitalz.balanceOf(vm.addr(3_335)), 0);
        assertEq(orbitalz.totalSupply(), 10_000);
    }

    function testCannotBigBangIfContractMinted() public {
        orbitalz.setAfterBigBang(true);
        // msg.sender != tx.origin
        vm.prank(vm.addr(12345), vm.addr(67890));

        vm.expectRevert(RobotzCantMint.selector);
        orbitalz.bigBang();
    }

    function testCannotBigBangMoreThanOncePerWallet() public {
        orbitalz.setAfterBigBang(true);
        // Force msg.sender == tx.origin
        vm.startPrank(vm.addr(12345), vm.addr(12345));

        orbitalz.bigBang();
        vm.expectRevert(BlackHoleError.selector);
        orbitalz.bigBang();
        vm.stopPrank();
    }

    function testGodBigBang() public {
        address mintTo = vm.addr(1);
        vm.prank(orbitalz.owner());

        orbitalz.godBigBang(mintTo, 1000);
        assertEq(orbitalz.balanceOf(mintTo), 1000);
    }

    function testCannotGodBigBangIfNotOwner() public {
        address minter = vm.addr(1);
        vm.prank(minter);
        vm.expectRevert("UNAUTHORIZED");
        orbitalz.godBigBang(minter, 1000);
        assertEq(orbitalz.balanceOf(minter), 0);
    }

    function testCannotGodBigBangMoreThanMaxSupply() public {
        address minter = vm.addr(1);
        vm.prank(orbitalz.owner(), orbitalz.owner());
        vm.expectRevert(UniverseExpansionLimit.selector);
        orbitalz.godBigBang(minter, 10_001);
        assertEq(orbitalz.balanceOf(orbitalz.owner()), 0);
    }

    function testOnlyOwnerCanOpenMinting() public {
        vm.prank(vm.addr(1));

        vm.expectRevert("UNAUTHORIZED");
        orbitalz.setAfterBigBang(true);

        assertEq(orbitalz.afterBigBang(), false);
    }

    function testHarvestStardust() public {
        address owner = vm.addr(1);
        orbitalz.setOwner(owner);

        vm.deal(owner, 0);
        vm.deal(address(orbitalz), 1);

        vm.prank(orbitalz.owner());
        orbitalz.harvestStarDust();

        assertEq(orbitalz.owner().balance, 1);
    }

    function testOnlyOwnerCanHarvestStardust() public {
        address notOwner = vm.addr(1);
        vm.deal(address(orbitalz), 1);

        vm.prank(notOwner);
        vm.expectRevert("UNAUTHORIZED");
        orbitalz.harvestStarDust();

        assertEq(notOwner.balance, 0);
        assertEq(address(orbitalz).balance, 1);
    }
}
