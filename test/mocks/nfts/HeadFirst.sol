// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../../../lib/ERC721A/contracts/ERC721A.sol";
import "../../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../../lib/operator-filter-registry-main/src/DefaultOperatorFilterer.sol";
import "../../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract HeadFirst  is ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;

	uint256 public maxSupply = 2222;
    uint256 public maxFreeSupply = 2222;
    uint256 public cost = 0.001 ether;
    uint256 public freeAmount = 3;
    uint256 public maxPerWallet = 23;

    bool public isRevealed = true;
	bool public pause = true;

    string private baseURL = "";
    string public hiddenMetadataUrl = "reveal";

    mapping(address => uint256) public userBalance;

	constructor(
        string memory _baseMetadataUrl
	)
	ERC721A("Head First", "HEF") {
        setBaseUri(_baseMetadataUrl);
    }

	function _baseURI() internal view override returns (string memory) {
		return baseURL;
	}

    function setBaseUri(string memory _baseURL) public onlyOwner {
	    baseURL = _baseURL;
	}

    function mint(uint256 mintAmount) external payable {
		require(!pause, "The sale is paused");
        if(userBalance[msg.sender] >= freeAmount) require(msg.value >= cost * mintAmount, "Insufficient funds");
        else{
            if(totalSupply() + mintAmount <= maxFreeSupply) require(msg.value >= cost * (mintAmount - (freeAmount - userBalance[msg.sender])), "Insufficient funds");
            else require(msg.value >= cost * mintAmount, "Insufficient funds");
        }
        require(_totalMinted() + mintAmount <= maxSupply,"Exceeds max supply");
        require(userBalance[msg.sender] + mintAmount <= maxPerWallet, "Exceeds max per wallet");
        _safeMint(msg.sender, mintAmount);
        userBalance[msg.sender] = userBalance[msg.sender] + mintAmount;
	}

    function airdrop(address to, uint256 mintAmount) external onlyOwner {
		require(
			_totalMinted() + mintAmount <= maxSupply,
			"Exceeds max supply"
		);
		_safeMint(to, mintAmount);
        
	}

    function sethiddenMetadataUrl(string memory _hiddenMetadataUrl) public onlyOwner {
	    hiddenMetadataUrl = _hiddenMetadataUrl;
	}

    function reveal(bool _state) external onlyOwner {
	    isRevealed = _state;
	}

	function _startTokenId() internal view virtual override returns (uint256) {
    	return 1;
  	}

	function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
		maxSupply = newMaxSupply;
	}

    function setMaxFreeSupply(uint256 newMaxFreeSupply) external onlyOwner {
		maxFreeSupply = newMaxFreeSupply;
	}

	function tokenURI(uint256 tokenId)
		public
		view
		override
		returns (string memory)
	{
        require(_exists(tokenId), "That token doesn't exist");
        if(isRevealed == false) {
            return hiddenMetadataUrl;
        }
        else return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : "";
	}

	function setCost(uint256 _newCost) public onlyOwner{
		cost = _newCost;
	}

	function setPause(bool _state) public onlyOwner{
		pause = _state;
	}

    function setFreeAmount(uint256 _newAmt) public onlyOwner{
        require(_newAmt < maxPerWallet, "Not possible");
        freeAmount = _newAmt;
    }

    function setMaxPerWallet(uint256 _newAmt) public  onlyOwner{
        require(_newAmt > freeAmount, "Not possible");
        maxPerWallet = _newAmt;
    }

	function withdraw() external onlyOwner {
		(bool success, ) = payable(owner()).call{
            value: address(this).balance
        }("");
        require(success);
	}
}