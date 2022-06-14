// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Vm.sol';
import 'forge-std/Test.sol';
import '../src/ClaimDoji.sol';
import 'forge-std/console.sol';

interface iMAYC is IERC721 {
  function ownerOf(uint256 owner) external returns (address);
}

interface iDoji {
  function claimDoji(uint256) external payable;

  function totalSupply() external returns (uint256);
}

contract DojiClaimTest is Test {
  // ==== Storage =====
  Vm public VM;
  /// @notice Wrapped Ether contract
  // IWETH public WETH;
  mintAndClaimDoji private CLAIMDOJI;

  // using stdStorage for StdStorage;

  iMAYC internal MAYC;
  iDoji internal DOJI;

  function setUp() public {
    VM = Vm(HEVM_ADDRESS);

    address bob = address(0x1337);
    vm.label(bob, 'Bob');

    // Setup WETH
    // WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // address _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address _CREW = 0x5e9dC633830Af18AA43dDB7B042646AADEDCCe81;
    address _DOJI_CLAIM = 0xaEC5f0D463fE18c9380115deA6CAddBC0EA69648;
    address _MAYC = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;
    address MAYC_ADDRESS = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;

    MAYC = iMAYC(MAYC_ADDRESS);
    DOJI = iDoji(_CREW);

    CLAIMDOJI = new mintAndClaimDoji(_CREW, _DOJI_CLAIM, _MAYC);

    hoax(bob, 100 ether);

    DOJI.claimDoji{ value: 2.2 ether }(50);
    DOJI.claimDoji{ value: 2.2 ether }(50);
    DOJI.claimDoji{ value: 2.2 ether }(50);
    DOJI.claimDoji{ value: 2.2 ether }(50);
    DOJI.claimDoji{ value: 2.2 ether }(50);
    DOJI.claimDoji{ value: 2.2 ether }(50);
    DOJI.claimDoji{ value: 2.2 ether }(50);
    DOJI.claimDoji{ value: 2.2 ether }(50);

    vm.stopPrank();
  }

  /// @notice Test claiming excess ETH
  function testClaimExcessETH() public {
    // Enforce contract starts with 0 balance
    VM.deal(address(CLAIMDOJI), 0);

    // Collect balance before
    uint256 balanceBefore = address(this).balance;

    // // Send 5 ETH to contract
    payable(address(CLAIMDOJI)).transfer(5 ether);

    // Assert balance now 5 less
    assertEq(address(this).balance, balanceBefore - 5 ether);

    // Withdraw 5 ETH
    CLAIMDOJI.withdrawBalance();

    // // Collect balance after
    uint256 balanceAfter = address(this).balance;

    // Assert balance matches
    assertEq(balanceAfter, balanceBefore);
  }

  function testClaimDojiTooLate() public {
    // Expect too late
    uint256 _targetId = 6266;
    uint256 _nftId = 6266;
    uint256 _dojiToMint = 2;
    vm.expectRevert(bytes('Too Late'));
    CLAIMDOJI.mintDoji(_targetId, _nftId, _dojiToMint);
  }

  function testClaimDojiTooEarly() public {
    // Expect too early
    uint256 _targetId = 9000;
    uint256 _nftId = 9000;
    uint256 _dojiToMint = 2;
    vm.expectRevert(bytes('Too Early'));
    CLAIMDOJI.mintDoji(_targetId, _nftId, _dojiToMint);
  }

  function testClaimDoji() public {
    uint256 _targetId = 7293;
    uint256 _nftId = 7293;

    // Assume on time

    emit log_uint(DOJI.totalSupply());

    uint256 _mostRecentId = DOJI.totalSupply() + 50;

    uint256 _dojiToMint = _targetId - _mostRecentId;

    emit log_uint(_dojiToMint);

    uint256 dojiPrice = 44000000000000000 * _dojiToMint;

    CLAIMDOJI.mintDoji{ value: dojiPrice }(_targetId, _nftId, _dojiToMint);

    emit log_uint(DOJI.totalSupply());

    emit log_address(MAYC.ownerOf(7293));
    emit log_address(address(this));

    assertEq(MAYC.ownerOf(_nftId), address(this));
  }

  /// @notice Allows receiving ETH
  receive() external payable {}
}
