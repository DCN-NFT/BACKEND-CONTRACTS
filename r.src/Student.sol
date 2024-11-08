// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./Credentials.sol";
import "./TimeManagement.sol";

contract StudentContract {
    using TimeManagement for TimeManagement.TimeManagerStorage;

    // State variables
    Credentials private credentialContract;
    TimeManagement.TimeManagerStorage private timeManager;

    // Events
    event CredentialTransferred(uint256 tokenId, address from, address to);
    
    // Custom errors
    error NotLoggedIn();
    error InvalidAddress();
    error TransferFailed();

    constructor(address _credentialContractAddress) {
        credentialContract = Credentials(_credentialContractAddress);
    }

    modifier onlyLoggedIn() {
        if (!timeManager.isUserLoggedIn(msg.sender)) revert NotLoggedIn();
        _;
    }

    function studentLogin() public returns (string memory) {
        string memory result = timeManager.logIn();
        return result;
    }
    
    function studentLogout() public returns (string memory) {
        return timeManager.logOut();
    }

    function verifyCredential(uint256 _currentTokenId) external view returns(address) {
        return credentialContract.ownerOf(_currentTokenId);
    }

    /**
     * @dev Transfer a credential to another address
     */
    function transferCredential(address to, uint256 tokenId) external onlyLoggedIn {
        require(to != address(0), "Invalid recipient address");
        require(credentialContract.ownerOf(tokenId) == msg.sender, "Not the owner of credential");
        
        credentialContract.transferFrom(msg.sender, to, tokenId);
        emit CredentialTransferred(tokenId, msg.sender, to);
    }

    /**
     * @dev Get all credentials owned by the caller
     */
    function getMyCredentials() external view onlyLoggedIn returns (uint256[] memory) {
        return credentialContract.getCredentialsByOwner(msg.sender);
    }

    /**
     * @dev Retrieve credential details
     */
    function retrieveCredential(uint256 tokenId) 
        external 
        view 
        onlyLoggedIn 
        returns (address owner, string memory uri) 
    {
        return credentialContract.getCredential(tokenId);
    }
}