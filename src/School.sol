// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;
import "./Credentials.sol";
import "./TimeManagement.sol";
contract SchoolContract {
    
    TimeManagement.TimeManagerStorage private timeManager;
    // Custom Errors
    error EmptySchoolHash();
    error SchoolNotLoggedIn();
    error SchoolAlreadyLoggedIn();
    error InvalidTimeStamp();
    error NotAuthorized();
    error AdminAlreadyExists();
    error AdminNotFound();
    error InvalidAddress();
    error EmptyAdminName();
    error EmptyCredentialHash();
    error InvalidStudent();


     //Adding credential contract instannce
    CredentialContract private credentialContract;
    
    //Adding consructor to initialize the credentiALContract.
    constructor(address _credentialContractAddress) {
        credentialContract = CredentialContract(_credentialContractAddress);
    }
    
    struct SchoolStruct {
        string schoolHash;
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

 

    function updateSchoolDetails(string memory _schoolHash) 
    external 
    onlyLoggedInSchool 
    returns (bool) 
{
    // Ensure the new school hash is not empty
    if (bytes(_schoolHash).length == 0) revert EmptySchoolHash();

    // Update the schoolHash
    schools[msg.sender].schoolHash = _schoolHash;

    return true;
}


    // Login/Logout Functions
    function loginSchool() 
        external 
        notLoggedInSchool 
        returns (bool) 
    {
        if (block.timestamp <= schools[msg.sender].lastLogoutTime) revert InvalidTimeStamp();

        schools[msg.sender].isLoggedIn = true;
        schools[msg.sender].lastLoginTime = block.timestamp;

        credentialContract.autoGrantSchoolRole(msg.sender);
        
        emit SchoolLoggedIn(msg.sender, block.timestamp);
        return true;
    }

    function logoutSchool() 
        external 
        onlyLoggedInSchool 
        returns (bool) 
    {
        schools[msg.sender].isLoggedIn = false;
        schools[msg.sender].lastLogoutTime = block.timestamp;
        
        emit SchoolLoggedOut(msg.sender, block.timestamp);
        return true;
    }

    // School Admin Management Functions
    function addSchoolAdmin(address _adminAddress, string memory _adminName) 
        external 
        onlyLoggedInSchool
        validAddress(_adminAddress) 
    {
        if (bytes(_adminName).length == 0) revert EmptyAdminName();
        if (schools[_adminAddress].wallet ==msg.sender) revert ("schools cant be msg.sender");
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
    
      function issueCredentialsToStudents(
        string memory _credentialHash,
        address student,
        bytes memory data
    ) external onlyLoggedInSchool returns (string memory) {
        // Validate inputs
        if (bytes(_credentialHash).length == 0) revert EmptyCredentialHash();
        if (student == address(0)) revert InvalidStudent();
        
        // Call the credential contract to issue the credential
        // Assuming the CredentialContract has an issueCredential function
        bool success = credentialContract.issueCredential(
            _credentialHash,
            student 
        );
        
        require(success, "Failed to issue credential");
    
        return "Successfully Issued Credential";
    }
    }

  