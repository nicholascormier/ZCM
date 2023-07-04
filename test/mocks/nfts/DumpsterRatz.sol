// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../../lib/ERC721A/contracts/ERC721A.sol";
import "../../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../../lib/operator-filter-registry-main/src/DefaultOperatorFilterer.sol";

contract DumpsterRatz is ERC721A, DefaultOperatorFilterer, Ownable {
    using Strings for uint256;

    string private uriPrefix;
    string private uriSuffix = ".json";
    string public hiddenURL;

    uint256 public cost = 0.003 ether;
    uint16 public maxSupply = 8000;
    uint8 public maxMintAmountPerTx = 10;
    uint8 public maxFreeMintAmountPerWallet = 1;
    uint8 public maxPerWallet = 50; 

    bool public paused = true;
    bool public reveal = false;

    mapping(address => uint8) public nftPerPublicAddress;

    constructor() ERC721A("DumpsterRatz", "DRATZ") {}

    function mint(uint8 _mintAmount) external payable {
        uint16 totalSupply = uint16(totalSupply());
        uint8 nft = nftPerPublicAddress[msg.sender];
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        require(_mintAmount <= maxMintAmountPerTx, "Exceeds max per transaction.");
        require(!paused, "The contract is paused!");

        if (nft >= maxFreeMintAmountPerWallet) {
            require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        } else {
            uint8 costAmount = _mintAmount + nft;
            if (costAmount > maxFreeMintAmountPerWallet) {
                costAmount = costAmount - maxFreeMintAmountPerWallet;
                require(msg.value >= cost * costAmount, "Insufficient funds!");
            }
        }

        require(nft + _mintAmount <= maxPerWallet, "Exceeds max per wallet."); // Check max per wallet limit

        _safeMint(msg.sender, _mintAmount);

        nftPerPublicAddress[msg.sender] = _mintAmount + nft;
        delete totalSupply;
        delete _mintAmount;
    }
  
  function Reserve(uint16 _mintAmount, address _receiver) external onlyOwner {
     uint16 totalSupply = uint16(totalSupply());
    require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
     _safeMint(_receiver , _mintAmount);
     delete _mintAmount;
     delete _receiver;
     delete totalSupply;
  }

  function  Airdrop(uint8 _amountPerAddress, address[] calldata addresses) external onlyOwner {
     uint16 totalSupply = uint16(totalSupply());
     uint totalAmount =   _amountPerAddress * addresses.length;
    require(totalSupply + totalAmount <= maxSupply, "Exceeds max supply.");
     for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], _amountPerAddress);
        }

     delete _amountPerAddress;
     delete totalSupply;
  }

 

  function setMaxSupply(uint16 _maxSupply) external onlyOwner {
      maxSupply = _maxSupply;
  }



   
  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
  
if ( reveal == false)
{
    return hiddenURL;
}
    

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString() ,uriSuffix))
        : "";
  }
 
 


 function setFreeMaxLimitPerAddress(uint8 _limit) external onlyOwner{
    maxFreeMintAmountPerWallet = _limit;
   delete _limit;

}

    
  

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }
   function setHiddenUri(string memory _uriPrefix) external onlyOwner {
    hiddenURL = _uriPrefix;
  }


  function setPaused() external onlyOwner {
    paused = !paused;
   
  }

  function setCost(uint _cost) external onlyOwner{
      cost = _cost;

  }

 function setRevealed() external onlyOwner{
     reveal = !reveal;
 }

  function setMaxMintAmountPerTx(uint8 _maxtx) external onlyOwner{
      maxMintAmountPerTx = _maxtx;

  }

 

  function withdraw() external onlyOwner {
  uint _balance = address(this).balance;
     payable(msg.sender).transfer(_balance ); 
       
  }


  function _baseURI() internal view  override returns (string memory) {
    return uriPrefix;
  }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from) payable 
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}