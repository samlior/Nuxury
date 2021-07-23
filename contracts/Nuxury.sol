// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

enum Edition {Unlimited, Limited1, Limited2, Limited3, Limited4}

contract Nuxury is ERC721 {
    using SafeMath for uint256;

    uint256 public deployNumber;

    uint256 public unlimitedEditionCount = 0;
    uint256 public limited1EditionCount = 1;
    uint256 public limited2EditionCount = 2;
    uint256 public limited3EditionCount = 3;
    uint256 public limited4EditionCount = 4;

    mapping(uint256 => uint8) public maxCirculationOf;
    mapping(uint256 => uint8) public circulationOf;

    mapping(uint256 => uint256) public mintedNumberOf;
    mapping(uint256 => uint256) public valueOf;

    mapping(uint256 => bool) public isLocked;

    event Locked(address indexed sender, uint256 indexed tokenId);
    event Mint(address indexed from, uint256 indexed tokenId, uint256 value);
    event Burn(
        address indexed from,
        uint256 indexed tokenId,
        uint256 value,
        uint256 burnValue
    );

    constructor() public ERC721("Nuxury", "NX") {
        deployNumber = block.number;
    }

    function getEdition(uint256 number) public pure returns (Edition) {
        if (number % 11107800 >= 11101629) {
            return Edition.Limited4;
        } else if (number % 2221560 >= 2215389) {
            return Edition.Limited3;
        } else if (number % 555390 >= 549219) {
            return Edition.Limited2;
        } else if (number % 185130 >= 178959) {
            return Edition.Limited1;
        }
        return Edition.Unlimited;
    }

    function getLimitedEditionId(uint256 number) public pure returns (uint256) {
        return number.div(185130);
    }

    function getMaxCirculation(Edition edition) public pure returns (uint8) {
        require(edition != Edition.Unlimited, "Nuxury: invalid edition");
        if (edition == Edition.Limited1) {
            return uint8(6000);
        } else if (edition == Edition.Limited2) {
            return uint8(2000);
        } else if (edition == Edition.Limited3) {
            return uint8(500);
        }
        return uint8(100);
    }

    function calcMaxCirculation(
        uint256 number,
        uint256 id,
        Edition edition
    ) public view returns (uint8) {
        return
            uint8(
                uint256(keccak256(abi.encodePacked(blockhash(number), id))) %
                    getMaxCirculation(edition)
            ) + 1;
    }

    function getLimitedEditionTokenId(uint256 number, Edition edition)
        private
        returns (uint256 tokenId)
    {
        uint256 id = getLimitedEditionId(number);
        uint8 current;
        if (maxCirculationOf[id] == 0) {
            current = calcMaxCirculation(block.number, id, edition);
            maxCirculationOf[id] = current;
        } else {
            current = circulationOf[id];
            require(current > 0, "Nuxury: reach max circulation");
        }
        current = current - 1;
        circulationOf[id] = current;

        if (edition == Edition.Limited1) {
            tokenId = limited1EditionCount;
            limited1EditionCount = limited1EditionCount.add(5);
        } else if (edition == Edition.Limited2) {
            tokenId = limited2EditionCount;
            limited2EditionCount = limited2EditionCount.add(5);
        } else if (edition == Edition.Limited3) {
            tokenId = limited3EditionCount;
            limited3EditionCount = limited3EditionCount.add(5);
        } else {
            tokenId = limited4EditionCount;
            limited4EditionCount = limited4EditionCount.add(5);
        }
    }

    function getUnlimitedEditionTokenId() private returns (uint256 tokenId) {
        tokenId = unlimitedEditionCount;
        unlimitedEditionCount = unlimitedEditionCount.add(5);
    }

    function mint(address to, string calldata description)
        external
        payable
        returns (uint256 tokenId)
    {
        require(msg.value > 0, "Nuxury: value is zero");
        uint256 number = block.number.sub(deployNumber);
        Edition edition = getEdition(number);
        tokenId;
        if (edition == Edition.Unlimited) {
            tokenId = getUnlimitedEditionTokenId();
        } else {
            tokenId = getLimitedEditionTokenId(number, edition);
        }
        _mint(to, tokenId);
        _setTokenURI(tokenId, description);
        valueOf[tokenId] = msg.value;
        mintedNumberOf[tokenId] = number;

        emit Mint(msg.sender, tokenId, msg.value);
    }

    function burn(uint256 tokenId, address payable to) external {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Nuxury: caller is not owner nor approved"
        );
        require(!isLocked[tokenId], "Nuxury: token has been locked");
        require(to != address(0), "Nuxury: receiver address is zero");
        _burn(tokenId);
        delete mintedNumberOf[tokenId];
        uint256 value = valueOf[tokenId];
        delete valueOf[tokenId];
        uint256 burnValue = value.div(10);
        if (burnValue > 0) {
            value = value.sub(burnValue);
            address(0).transfer(burnValue);
        }
        to.transfer(value);

        emit Burn(msg.sender, tokenId, value, burnValue);
    }

    function lock(uint256 tokenId) external {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Nuxury: caller is not owner nor approved"
        );
        require(!isLocked[tokenId], "Nuxury: token has been locked");
        isLocked[tokenId] = true;
        emit Locked(msg.sender, tokenId);
    }
}
