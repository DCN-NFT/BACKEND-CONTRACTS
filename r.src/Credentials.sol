
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


/**
 * @title Credentials
 * @dev Contract for managing academic credentials as NFTs
 */
contract Credentials is ERC721Enumerable, ERC721URIStorage {
    
    // Current token ID tracker
    uint256 private _currentTokenId;
    
    // Mapping from token ID to credential status (active/revoked)
    mapping(uint256 => bool) private _credentialStatus;
    
    // Events
    event CredentialIssued(uint256  tokenId, address indexed recipient, string tokenURI);
    event CredentialRevoked(uint256 indexed tokenId, address indexed revokedFrom);
    event CredentialReactivated(uint256 indexed tokenId);
    
    constructor() ERC721("Academic Credentials", "ACAD") {
        _currentTokenId = 0;
    }

    function issueCredential(
    address recipient,
    string memory _tokenURI
) external virtual returns (uint256) {
    require(recipient != address(0), "Invalid recipient");
    require(bytes(_tokenURI).length != 0, "The token id cant be zero");

    uint256 tokenId =++ _currentTokenId;
    _mint(recipient, tokenId);
    _setTokenURI(tokenId, _tokenURI);
    emit CredentialIssued(tokenId, recipient, tokenURI(tokenId));

    return tokenId;
}
    function getCredential(uint256 tokenId) 
        external 
        view 
        virtual
        returns (
            address owner,
            string memory uri
        ) 
    {
        require(ownerOf(tokenId) != address(0), "Credential does not exist");
        
        owner = ownerOf(tokenId);
        uri = tokenURI(tokenId);
    }

    

    function getCredentialsByOwner(address owner) 
        external 
        view 
        virtual
        returns (uint256[] memory) 
    {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);
        
        for (uint256 i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        
        return tokens;
    }

    /**
     * @dev Returns the current token ID
     */
    function getCurrentTokenId() external view returns (uint256) {
        return _currentTokenId;
    }

// 
// 
// 

    // Required overrides for multiple inheritance
    function _increaseBalance(address account, uint128 value) 
        internal 
        virtual 
        override(ERC721, ERC721Enumerable) 
    {
        super._increaseBalance(account, value);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }


    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override( ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}


