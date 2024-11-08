// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Credentials} from "./Credentials.sol";
import "./TimeManagement.sol";

contract SchoolContract is Credentials {
    
    using TimeManagement for TimeManagement.TimeManagerStorage;
    TimeManagement.TimeManagerStorage private timeManager;

    // Custom Errors
    error SchoolNotLoggedIn();
    error SchoolAlreadyLoggedIn();
    error InvalidTimeStamp();
    error NotAuthorized();
    error InvalidStudent();

    // Adding credential contract instance
    Credentials private credentialContract;

    // Adding constructor to initialize the credentialContract
    constructor(address _credentialContractAddress) {
        credentialContract = Credentials(_credentialContractAddress);
    }

    // Events
    event SchoolLoggedIn(address indexed schoolAddress, uint256 timestamp);
    event SchoolLoggedOut(address indexed schoolAddress, uint256 timestamp);
    event CredentialIssued(address indexed schoolAddress, address indexed student, uint256 tokenId, string tokenURI, uint256 timestamp);


    // Login/Logout Functions
    function schoolLogin() public returns (string memory) {
        string memory result = timeManager.logIn();

        // Add this line to notify the credential contract
        // credentialContract.autoGrantSchoolRole(msg.sender);

        return result;
    }

    function schoolLogout() public returns (string memory) {
        return timeManager.logOut();
    }


    // Credential Management Functions
    function issueCredential(
        address student,
        string memory tokenURI
    ) external virtual override returns  (uint256) {
        // Validate inputs
        if (student == address(0)) revert InvalidStudent();

        // Issue the credential
        uint256 newTokenId = credentialContract.issueCredential(student, tokenURI);

        emit CredentialIssued(msg.sender, student, newTokenId, tokenURI, block.timestamp);

        return newTokenId;
    }

    function getCredential(uint256 tokenId)
        external
        view
        virtual
        override
        returns (
            address owner,
            string memory uri
        )
    {
        return credentialContract.getCredential(tokenId);
    }

    function getCredentialsByOwner(address owner)
        external
        view
        override
        virtual
        returns (uint256[] memory)
    {
        return credentialContract.getCredentialsByOwner(owner);
    }

    
}