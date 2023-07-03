// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../../../lib/ERC721A/contracts/ERC721A.sol";
import "../../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../../../lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "../../../lib/operator-filter-registry-main/src/DefaultOperatorFilterer.sol";

contract BlockTurtles is ERC721A, Ownable, ERC2981, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;
 
  string public _baseTokenURI;
  string public hiddenMetadataUri;
 
  uint256 public cost = 0.000 ether;
  uint256 public maxSupply = 3333;
  uint256 public freeSupply = 1333;
  uint256 public maxMintAmountPerTx = 5;
 
  bool public paused;
  bool public revealed = false;
 
  constructor(string memory _hiddenMetadataUri) ERC721A("Block Turtles", "BT") {
     setHiddenMetadataUri(_hiddenMetadataUri);
     _setDefaultRoyalty(0x70668bf9f0854Cd2DaBf68a60431fDfA256f5EAa, 500);
  }
 
  function mint(uint256 _mintAmount) public payable nonReentrant {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    if (totalSupply() >= freeSupply) {
          require(msg.value > 0, "Max free supply exceeded!");
      }
 
    _safeMint(_msgSender(), _mintAmount);
  }
 
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }
 
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
 
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }
 
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }
 
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }
 
  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setFreeSupply(uint256 _freeSupply) public onlyOwner {
    freeSupply = _freeSupply;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
 
  // METADATA HANDLING
 
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }
 
  function setBaseURI(string calldata baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }
 
  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }
 
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId), "URI does not exist!");
 
      if (revealed) {
          return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"));
      } else {
          return hiddenMetadataUri;
      }
  }

  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function deleteDefaultRoyalty() external onlyOwner {
    _deleteDefaultRoyalty();
  }

  //override
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, ERC2981) returns (bool) {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return 
        ERC721A.supportsInterface(interfaceId) || 
        ERC2981.supportsInterface(interfaceId);
  }
}