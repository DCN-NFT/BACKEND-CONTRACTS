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
        // Add role definitions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SCHOOL_ROLE = keccak256("SCHOOL_ROLE");
    bytes32 public constant STUDENT_ROLE = keccak256("STUDENT_ROLE");

    struct Credential {
        string courseName;
        string grade;
        uint256 issueDate;
        bool claimed;
        address student;
    }

    uint256 private _tokenIdCounter;

    mapping(bytes32 => uint256) private _hashToTokenId;
    

    mapping(uint256 => string) private _credentialURIs;
    mapping(uint256 => address) private _issuers;
    mapping(address => uint256[]) private _issuedCredentials;
    mapping(address => uint256[]) private _ownedCredentials;
    mapping(uint256 => bytes32) private _tokenIdToHash;

        // New mappings
    mapping(uint256 => Credential) private _credentials;
    mapping(address => uint256[]) private _pendingCredentials;

    event CredentialIssued(uint256 indexed tokenId, address indexed recipient, string credentialURI);
    event CredentialRevoked(uint256 indexed tokenId, address indexed issuer);
    event CredentialTransferred(uint256 indexed tokenId, address indexed previousOwner, address indexed newOwner);
    event CredentialClaimed(uint256 indexed tokenId, address indexed student);

    event CredentialCreated(
        uint256 indexed tokenId,
        address indexed school,
        address indexed student,
        string courseName,
        string grade
    );

constructor(
    address initialOwner,
    address _schoolContract,
    address _studentContract
) ERC721("Decentralised Credential Network", "DCN") {
    _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
    _grantRole(ADMIN_ROLE, initialOwner);
    
    // Fix: Correct the contract initialization syntax
    schoolContract = SchoolContract(_schoolContract);
    studentContract = StudentContract(_studentContract);
}

function autoGrantSchoolRole(address school) external {
    // Only allow calls from the school contract
    require(msg.sender == address(schoolContract), "Only school contract can grant school role");
    if (!hasRole(SCHOOL_ROLE, school)) {
        _grantRole(SCHOOL_ROLE, school);
    }
}

function autoGrantStudentRole(address student) external {
    // Only allow calls from the student contract
    require(msg.sender == address(studentContract), "Only student contract can grant student role");
    if (!hasRole(STUDENT_ROLE, student)) {
        _grantRole(STUDENT_ROLE, student);
    }
}


    function createCredential(
    address student,
    string memory courseName,
    string memory grade,
    string memory credentialURI
) public returns (bytes32) {
    require(student != address(0), "Invalid student address");

    uint256 tokenId = _tokenIdCounter;
    _tokenIdCounter++;

    // Generate unique hash from credential details
    bytes32 credentialHash = keccak256(
        abi.encodePacked(
            student,
            courseName,
            grade,
            block.timestamp,
            msg.sender
        )
    );
    
    // Ensure hash is unique
    require(_hashToTokenId[credentialHash] == 0, "Credential hash already exists");
    
    _credentials[tokenId] = Credential({
        courseName: courseName,
        grade: grade,
        issueDate: block.timestamp,
        claimed: false,
        student: student
    });

    _credentialURIs[tokenId] = credentialURI;
    _issuers[tokenId] = msg.sender;
    _issuedCredentials[msg.sender].push(tokenId);
    _pendingCredentials[student].push(tokenId);
    _hashToTokenId[credentialHash] = tokenId;
    _tokenIdToHash[tokenId] = credentialHash;  

    emit CredentialCreated(tokenId, msg.sender, student, courseName, grade);
    return credentialHash; // Return hash instead of tokenId
}
function getHashFromTokenId(uint256 tokenId) external view returns (bytes32) {
    require(tokenId < _tokenIdCounter, "Invalid token ID");
    return _tokenIdToHash[tokenId];
}
  function _removeFromPendingCredentials(address student, uint256 tokenId) private {
        uint256[] storage pendingCredentials = _pendingCredentials[student];
        for (uint256 i = 0; i < pendingCredentials.length; i++) {
            if (pendingCredentials[i] == tokenId) {
                pendingCredentials[i] = pendingCredentials[pendingCredentials.length - 1];
                pendingCredentials.pop();
                break;
            }
        }
    }

    function getCredentialDetails(bytes32 credentialHash) external view returns (string memory, string memory, uint256) {
    uint256 tokenId = _hashToTokenId[credentialHash];
    require(tokenId != 0, "Invalid credential hash");
    Credential memory cred = _credentials[tokenId];
    return (cred.courseName, cred.grade, cred.issueDate);
}

function claimCredential(bytes32 credentialHash) public {
    uint256 tokenId = _hashToTokenId[credentialHash];
    require(tokenId != 0, "Invalid credential hash");
    require(_credentials[tokenId].student == msg.sender, "Not the intended recipient");
    require(!_credentials[tokenId].claimed, "Credential already claimed");
    
    _credentials[tokenId].claimed = true;
    _safeMint(msg.sender, tokenId);
    _ownedCredentials[msg.sender].push(tokenId);
    
    // Remove from pending credentials
    _removeFromPendingCredentials(msg.sender, tokenId);
    
    emit CredentialClaimed(tokenId, msg.sender);
}

function getCredentialHash(
    address student,
    string memory courseName,
    string memory grade
) public view returns (bytes32) {
    return keccak256(
        abi.encodePacked(
            student,
            courseName,
            grade,
            block.timestamp,
            msg.sender
        )
    );
 
}
  function revokeCredential(bytes32 credentialHash) public {
    uint256 tokenId = _hashToTokenId[credentialHash];
    require(tokenId != 0, "Invalid credential hash");
    require(_issuers[tokenId] == msg.sender, "Only the issuer can revoke this credential");
    
    address owner = ownerOf(tokenId);
    burn(tokenId);
    delete _credentialURIs[tokenId];
    delete _issuers[tokenId];
    delete _hashToTokenId[credentialHash];
    _removeFromIssuedCredentials(msg.sender, credentialHash);
    _removeFromOwnedCredentials(owner, credentialHash);

    emit CredentialRevoked(tokenId, msg.sender);
}

    function transferCredential(bytes32 credentialHash, address newRecipient) public {
    uint256 tokenId = _hashToTokenId[credentialHash];
    require(tokenId != 0, "Invalid credential hash");
    require(ownerOf(tokenId) == msg.sender, "Only the credential owner can transfer");
    require(newRecipient != address(0), "Invalid recipient address");
    
    address previousOwner = msg.sender;
    safeTransferFrom(previousOwner, newRecipient, tokenId);
    _removeFromOwnedCredentials(previousOwner, credentialHash);
    _ownedCredentials[newRecipient].push(tokenId);

    emit CredentialTransferred(tokenId, previousOwner, newRecipient);
}

    function getCredentialURI(bytes32 credentialHash) public view returns (string memory) {
        uint256 tokenId = _hashToTokenId[credentialHash];
        require(tokenId != 0, "Invalid credential hash");
        return _credentialURIs[tokenId];
    }

   function getCredentialIssuer(bytes32 credentialHash) public view returns (address) {
    uint256 tokenId = _hashToTokenId[credentialHash];
    require(tokenId != 0, "Invalid credential hash");
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

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _removeFromIssuedCredentials(address issuer, bytes32 credentialHash) private {
        uint256 tokenId = _hashToTokenId[credentialHash];
        require(tokenId != 0, "Invalid credential hash");
        uint256[] storage issuedCredentials = _issuedCredentials[issuer];
        for (uint256 i = 0; i < issuedCredentials.length; i++) {
            if (issuedCredentials[i] == tokenId) {
                issuedCredentials[i] = issuedCredentials[issuedCredentials.length - 1];
                issuedCredentials.pop();
                break;
            }
        }
    }

    function _removeFromOwnedCredentials(address owner, bytes32 credentialHash) private {
        uint256 tokenId = _hashToTokenId[credentialHash];
        require(tokenId != 0, "Invalid credential hash");
        uint256[] storage ownedCredentials = _ownedCredentials[owner];
        for (uint256 i = 0; i < ownedCredentials.length; i++) {
            if (ownedCredentials[i] == tokenId) {
                ownedCredentials[i] = ownedCredentials[ownedCredentials.length - 1];
                ownedCredentials.pop();
                break;
            }
        }
    }

    function getCourseName(bytes32 credentialHash) public view returns (string memory) {
        uint256 tokenId = _hashToTokenId[credentialHash];
        require(tokenId != 0, "Invalid credential hash");
        return _credentials[tokenId].courseName;
    }

    function getGrade(bytes32 credentialHash) public view returns (string memory) {
        uint256 tokenId = _hashToTokenId[credentialHash];
        require(tokenId != 0, "Invalid credential hash");
        return _credentials[tokenId].grade;
    }

    function getIssueDate(bytes32 credentialHash) public view returns (uint256) {
        uint256 tokenId = _hashToTokenId[credentialHash];
        require(tokenId != 0, "Invalid credential hash");
        return _credentials[tokenId].issueDate;
    }
}