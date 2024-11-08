//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { ERC721 } from "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import { ERC721URIStorage } from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { ERC721Burnable } from "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {AccessControl} from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import "./Student.sol";
import "./School.sol";

contract CredentialContract is ERC721, ERC721URIStorage, ERC721Burnable, AccessControl {
    StudentContract public studentContract;
    SchoolContract public schoolContract;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SCHOOL_ROLE = keccak256("SCHOOL_ROLE");
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");

    uint256 private _tokenIdCounter;
    
    mapping(uint256 => string) private _tokenURIs;
    
    event CredentialIssued(uint256 indexed tokenId, address indexed recipient);
    event CredentialRevoked(uint256 indexed tokenId, address indexed issuer);
    event CredentialTransferred(uint256 indexed tokenId, address indexed from, address to);

    constructor(
        address initialOwner,
        address _schoolContract,
        address _studentContract
    ) ERC721("Decentralised Credential Network", "DCN") {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(ADMIN_ROLE, initialOwner);
        
        schoolContract = SchoolContract(_schoolContract);
        studentContract = StudentContract(_studentContract);
    }

    function autoGrantSchoolRole(address school) external {
        require(msg.sender == address(schoolContract), "Only school contract can grant school role");
        if (!hasRole(SCHOOL_ROLE, school)) {
            _grantRole(SCHOOL_ROLE, school);
        }
    }

    function autoGrantStudentRole(address student) external {
        require(msg.sender == address(studentContract), "Only student contract can grant student role");
        if (!hasRole(STUDENT_ROLE, student)) {
            _grantRole(STUDENT_ROLE, student);
        }
    }

    function issueCredential(address student, string memory uri) external {
        require(hasRole(SCHOOL_ROLE, msg.sender), "Only schools can issue credentials");
        require(student != address(0), "Invalid student address");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(student, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenURIs[tokenId] = uri;

        emit CredentialIssued(tokenId, student);
    }

    function revokeCredential(uint256 tokenId) external {
        require(hasRole(SCHOOL_ROLE, msg.sender), "Only schools can revoke credentials");
        require(_exists(tokenId), "Token does not exist");

        address owner = ERC721.ownerOf(tokenId);
        _burn(tokenId);
        delete _tokenURIs[tokenId];

        emit CredentialRevoked(tokenId, msg.sender);
    }

    function transferCredential(uint256 tokenId, address to) external {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the token owner");
        require(to != address(0), "Invalid recipient address");

        address from = msg.sender;
        safeTransferFrom(from, to, tokenId);

        emit CredentialTransferred(tokenId, from, to);
    }

    function getCurrentTokenId() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenURIs[tokenId];
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}