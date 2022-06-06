// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StephenResume is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.05 ether;
  uint256 public constant MAX_SUPPLY = 1000;
  uint256 public constant MAX_MINT_AMOUNT = 21; // Set to one higher than actual, to save gas on lte/gte checks.
  Counters.Counter private currentTokenId;
  bool public paused = false;
  mapping(address => bool) public whitelisted;

  modifier enoughSupply(uint256 _mintAmount) {
    require(
      _mintAmount > 0 && _mintAmount < MAX_MINT_AMOUNT,
        "Invalid mint amount"
      );
    require(
      totalSupply() + _mintAmount <= MAX_SUPPLY,
        "Max supply exceeded"
      );
    _;
  }

  function totalSupply() public view returns (uint256) {
    return currentTokenId.current();
  }

  constructor() ERC721("Stephen Resume", "SR") {}

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount)
    public
    payable
    enoughSupply(_mintAmount)
  {
    require(!paused);

    if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {
          require(msg.value >= cost * _mintAmount);
        }
    }

    _mintLoop(_to, _mintAmount);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      currentTokenId.increment();
      _safeMint(_receiver, currentTokenId.current());
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentIndex = 1;
    uint256 ownedTokenIndex = 0;

    while (
        ownedTokenIndex < ownerTokenCount && currentIndex <= MAX_SUPPLY
    ) {
        address currentTokenOwner = ownerOf(currentIndex);

        if (currentTokenOwner == _owner) {
            ownedTokenIds[ownedTokenIndex] = currentIndex;
            ownedTokenIndex++;
        }

        currentIndex++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  // only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}