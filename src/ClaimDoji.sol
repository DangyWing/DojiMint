// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';

// ERC721
interface IERC721 {
  /// @notice Approve spend for all
  function setApprovalForAll(address operator, bool approved) external;

  /// @notice Transfer NFT
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

interface IMAYC is IERC721 {
  function transferFrom(
    address,
    address,
    uint256
  ) external;
}

interface DojiCrew is IERC721 {
  /// @dev claimDoji is the mint function
  function claimDoji(uint256) external payable;

  /// @notice get total minted Doji
  function totalSupply() external returns (uint256);

  function transferFrom(
    address,
    address,
    uint256
  ) external;
}

interface DojiClaim is IERC721 {
  /// @notice claim the MAYC from the Doji
  function claimOneNFTPending(
    uint256 _tokenID,
    address _nftContract,
    uint256 _nftId
  ) external;
}

contract mintAndClaimDoji is Ownable {
  address internal immutable OWNER;

  /// @dev DojiCrew contract
  DojiCrew internal immutable CREW;

  /// @dev DojiClaim Contract
  DojiClaim internal immutable CLAIM;

  // Setup MAYC Address
  IMAYC internal immutable MAYC;

  constructor(
    address _CREW,
    address _DOJI_CLAIM,
    address _MAYC // address _MAYC_TRANSFER_MANAGER, // address _LOOKSRARE
  ) {
    // Setup contract owner
    OWNER = msg.sender;

    // Setup DojiCrew contract
    CREW = DojiCrew(_CREW);

    // Setup Doji Claim contract
    CLAIM = DojiClaim(_DOJI_CLAIM);

    // Setup MAYC Contract
    MAYC = IMAYC(_MAYC);
  }

  /// @notice mint Doji function with logic
  function mintDoji(
    uint256 _targetId,
    uint256 _nftId,
    uint256 _dojiToMint
  ) external payable onlyOwner {
    /// There is a 50 id offset in this collection
    uint256 dojiCount = CREW.totalSupply() + 50;

    // Check if ID is out of range
    bool idOutOfRange = _targetId > dojiCount + 50;
    if (idOutOfRange) revert('Too Early');

    bool idAlreadyMinted = _targetId <= dojiCount;
    if (idAlreadyMinted) revert('Too Late');

    // Mint Dojis to and including the target ID
    CREW.claimDoji{ value: msg.value }(_dojiToMint);

    /// Claim the MAYC from the Doji
    CLAIM.claimOneNFTPending(_targetId, address(MAYC), _nftId);

    // Send MAYC to contract owner
    MAYC.transferFrom(address(this), OWNER, _nftId);

    // Bribe flashbot miner
    block.coinbase.transfer(.25 ether);
  }

  /// @notice claim the MAYC from the Doji
  function claimMAYC(uint256 _targetId, uint256 _nftId) external onlyOwner {
    CLAIM.claimOneNFTPending(_targetId, address(MAYC), _nftId);
  }

  /// @notice Send MAYC to contract owner
  function sendMAYCToOwner(uint256 _nftId) external onlyOwner {
    MAYC.transferFrom(address(this), OWNER, _nftId);
  }

  /// @notice Withdraws contract ETH balance to owner address
  function withdrawBalance() external {
    (bool sent, ) = OWNER.call{ value: address(this).balance }('');
    if (!sent) revert('Could not withdraw balance!');
  }

  /// @notice Accept ERC721 tokens
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  ) external pure returns (bytes4) {
    return 0x150b7a02;
  }

  /// @notice Allows receiving ETH
  receive() external payable {}
}
