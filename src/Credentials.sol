//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC721 } from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import { ERC721URIStorage } from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { ERC721Burnable } from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { Ownable } from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract ExtendedCredentialContract is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {

    uint256 private _tokenIdCounter;

    mapping(uint256 => string) private _credentialURIs;
    mapping(uint256 => address) private _issuers;
    mapping(address => uint256[]) private _issuedCredentials;
    mapping(address => uint256[]) private _ownedCredentials;

    event CredentialIssued(uint256 indexed tokenId, address indexed recipient, string credentialURI);
    event CredentialRevoked(uint256 indexed tokenId, address indexed issuer);
    event CredentialTransferred(uint256 indexed tokenId, address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) ERC721("Decentralised Credential Network", "DCN") Ownable(initialOwner) {}

    function issueCredential(address recipient, string memory credentialURI) public onlyOwner {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, credentialURI);
        _credentialURIs[tokenId] = credentialURI;
        _issuers[tokenId] = msg.sender;
        _issuedCredentials[msg.sender].push(tokenId);
        _ownedCredentials[recipient].push(tokenId);

        emit CredentialIssued(tokenId, recipient, credentialURI);
    }

    function revokeCredential(uint256 tokenId) public {
        require(_issuers[tokenId] == msg.sender, "Only the issuer can revoke this credential");
        burn(tokenId);
        delete _credentialURIs[tokenId];
        delete _issuers[tokenId];
        _removeFromIssuedCredentials(msg.sender, tokenId);
        _removeFromOwnedCredentials(ownerOf(tokenId), tokenId);

        emit CredentialRevoked(tokenId, msg.sender);
    }

    function transferCredential(uint256 tokenId, address newRecipient) public {
        require(_issuers[tokenId] == msg.sender, "Only the issuer can transfer this credential");
        address previousOwner = ownerOf(tokenId);
        safeTransferFrom(previousOwner, newRecipient, tokenId);
        _removeFromOwnedCredentials(previousOwner, tokenId);
        _ownedCredentials[newRecipient].push(tokenId);

        emit CredentialTransferred(tokenId, previousOwner, newRecipient);
    }

    function getCredentialURI(uint256 tokenId) public view returns (string memory) {
        return _credentialURIs[tokenId];
    }

    function getCredentialIssuer(uint256 tokenId) public view returns (address) {
        return _issuers[tokenId];
    }

    function getIssuedCredentials(address issuer) public view returns (uint256[] memory) {
        return _issuedCredentials[issuer];
    }

    function getOwnedCredentials(address owner) public view returns (uint256[] memory) {
        return _ownedCredentials[owner];
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _removeFromIssuedCredentials(address issuer, uint256 tokenId) private {
        uint256[] storage issuedCredentials = _issuedCredentials[issuer];
        for (uint256 i = 0; i < issuedCredentials.length; i++) {
            if (issuedCredentials[i] == tokenId) {
                issuedCredentials[i] = issuedCredentials[issuedCredentials.length - 1];
                issuedCredentials.pop();
                break;
            }
        }
    }

    function _removeFromOwnedCredentials(address owner, uint256 tokenId) private {
        uint256[] storage ownedCredentials = _ownedCredentials[owner];
        for (uint256 i = 0; i < ownedCredentials.length; i++) {
            if (ownedCredentials[i] == tokenId) {
                ownedCredentials[i] = ownedCredentials[ownedCredentials.length - 1];
                ownedCredentials.pop();
                break;
            }
        }
    }
}