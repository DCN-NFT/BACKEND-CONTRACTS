// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Credentials} from "./Credentials.sol";
import "./TimeManagement.sol";

contract SchoolContract {
    using TimeManagement for TimeManagement.TimeManagerStorage;
    TimeManagement.TimeManagerStorage private timeManager;

    // Custom Errors
    error SchoolNotLoggedIn();
    error SchoolAlreadyLoggedIn();
    error InvalidTimeStamp();
    error NotAuthorized();
    error AdminAlreadyExists();
    error AdminNotFound();
    error InvalidAddress();
    error EmptyAdminName();
    error InvalidStudent();

    // Adding credential contract instance
    Credentials private credentialContract;

    // Adding constructor to initialize the credentialContract
    constructor(address _credentialContractAddress) {
        credentialContract = Credentials(_credentialContractAddress);
    }

    struct SchoolStruct {
        address wallet;
        bool isRegistered;
        bool isLoggedIn;
        uint256 lastLoginTime;
        uint256 lastLogoutTime;
    }

    struct SchoolAdmin {
        string adminName;
        address adminAddress;
        bool isActive;
        uint256 addedAt;
    }

    // Mappings
    mapping(address => SchoolStruct) public schools;
    mapping(address => mapping(address => SchoolAdmin)) internal schoolAdmins;
    mapping(address => mapping(address => bool)) internal isSchoolAdmin;
    mapping(address => address[]) private schoolAdminList;

    // Events
    event SchoolLoggedIn(address indexed schoolAddress, uint256 timestamp);
    event SchoolLoggedOut(address indexed schoolAddress, uint256 timestamp);
    event SchoolAdminAdded(address indexed schoolAddress, address indexed adminAddress, string adminName, uint256 timestamp);
    event SchoolAdminRemoved(address indexed schoolAddress, address indexed adminAddress, uint256 timestamp);
    event SchoolAdminStatusUpdated(address indexed schoolAddress, address indexed adminAddress, bool isActive, uint256 timestamp);
    event CredentialIssued(address indexed schoolAddress, address indexed student, uint256 tokenId, string tokenURI, uint256 timestamp);

    modifier onlyLoggedInSchool() {
        if (!schools[msg.sender].isLoggedIn) revert SchoolNotLoggedIn();
        _;
    }

    modifier notLoggedInSchool() {
        if (schools[msg.sender].isLoggedIn) revert SchoolAlreadyLoggedIn();
        _;
    }

    modifier onlySchoolOrAdmin(address _schoolAddress) {
        if (msg.sender != _schoolAddress && !isSchoolAdmin[_schoolAddress][msg.sender])
            revert NotAuthorized();
        _;
    }

    modifier validAddress(address _address) {
        if (_address == address(0)) revert InvalidAddress();
        _;
    }

    modifier onlyActiveAdmin(address _schoolAddress, address _adminAddress) {
        if (!isSchoolAdmin[_schoolAddress][_adminAddress] || !schoolAdmins[_schoolAddress][_adminAddress].isActive)
            revert NotAuthorized();
        _;
    }

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

    // School Admin Management Functions
    function addSchoolAdmin(address _adminAddress, string memory _adminName)
        external
        onlyLoggedInSchool
        validAddress(_adminAddress)
    {
        if (bytes(_adminName).length == 0) revert EmptyAdminName();
        if (schools[_adminAddress].wallet == msg.sender) revert ("schools cant be msg.sender");
        if (isSchoolAdmin[msg.sender][_adminAddress]) revert AdminAlreadyExists();

        SchoolAdmin memory newAdmin = SchoolAdmin({
            adminName: _adminName,
            adminAddress: _adminAddress,
            isActive: true,
            addedAt: block.timestamp
        });

        schoolAdmins[msg.sender][_adminAddress] = newAdmin;
        isSchoolAdmin[msg.sender][_adminAddress] = true;
        schoolAdminList[msg.sender].push(_adminAddress);

        emit SchoolAdminAdded(msg.sender, _adminAddress, _adminName, block.timestamp);
    }

    function removeSchoolAdmin(address _adminAddress)
        external
        onlyLoggedInSchool
        validAddress(_adminAddress)
    {
        if (!isSchoolAdmin[msg.sender][_adminAddress]) revert AdminNotFound();

        isSchoolAdmin[msg.sender][_adminAddress] = false;
        schoolAdmins[msg.sender][_adminAddress].isActive = false;

        emit SchoolAdminRemoved(msg.sender, _adminAddress, block.timestamp);
    }

    function toggleSchoolAdminStatus(address _adminAddress)
        external
        onlyLoggedInSchool
        validAddress(_adminAddress)
    {
        if (!isSchoolAdmin[msg.sender][_adminAddress]) revert AdminNotFound();

        bool newStatus = !schoolAdmins[msg.sender][_adminAddress].isActive;
        schoolAdmins[msg.sender][_adminAddress].isActive = newStatus;

        emit SchoolAdminStatusUpdated(msg.sender, _adminAddress, newStatus, block.timestamp);
    }

    // Getter Functions
    function getMySchoolDetails()
        external
        view
        returns (SchoolStruct memory)
    {
        return schools[msg.sender];
    }

    function getMySchoolAdmins()
        external
        view
        returns (SchoolAdmin[] memory)
    {
        address[] memory adminAddresses = schoolAdminList[msg.sender];
        SchoolAdmin[] memory admins = new SchoolAdmin[](adminAddresses.length);

        for (uint i = 0; i < adminAddresses.length; i++) {
            admins[i] = schoolAdmins[msg.sender][adminAddresses[i]];
        }

        return admins;
    }

    // Credential Management Functions
    function issueCredential(
        address student,
        uint256 tokenId,
        string memory tokenURI
    ) external onlyLoggedInSchool returns (uint256) {
        // Validate inputs
        if (student == address(0)) revert InvalidStudent();

        // Issue the credential
        uint256 newTokenId = credentialContract.issueCredential(student, tokenId, tokenURI);

        emit CredentialIssued(msg.sender, student, newTokenId, tokenURI, block.timestamp);

        return newTokenId;
    }

    function issueCredentialByAdmin(
        address _schoolAddress,
        address student,
        uint256 tokenId,
        string memory tokenURI
    ) external onlyActiveAdmin(_schoolAddress, msg.sender) returns (uint256) {
        // Validate inputs
        if (student == address(0)) revert InvalidStudent();

        // Issue the credential
        uint256 newTokenId = credentialContract.issueCredential(student, tokenId, tokenURI);

        emit CredentialIssued(_schoolAddress, student, newTokenId, tokenURI, block.timestamp);

        return newTokenId;
    }

    function getCredential(uint256 tokenId)
        external
        view
        onlyLoggedInSchool
        returns (
            address owner,
            string memory uri,
            bool isActive
        )
    {
        return credentialContract.getCredential(tokenId);
    }

    function getCredentialsByOwner(address owner)
        external
        view
        onlyLoggedInSchool
        returns (uint256[] memory)
    {
        return credentialContract.getCredentialsByOwner(owner);
    }

    function revokeCredential(uint256 tokenId)
        external
        onlyLoggedInSchool
    {
        credentialContract.revokeCredential(tokenId);
    }

    function reactivateCredential(uint256 tokenId)
        external
        onlyLoggedInSchool
    {
        credentialContract.reactivateCredential(tokenId);
    }

    function isCredentialActive(uint256 tokenId)
        external
        view
        onlyLoggedInSchool
        returns (bool)
    {
        return credentialContract.isCredentialActive(tokenId);
    }
}