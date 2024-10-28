// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract StudentsContract {
    // Custom errors
    error AlreadyRegisteredStudent();
    error NotRegisteredStudent();
    error InvalidStudentID();
    error InvalidAddress();
    error EmptyIPFSHash();
    error StudentNotLoggedIn();
    error StudentAlreadyLoggedIn();

    struct Student {
        uint256 studentID;
        address wallet;
        bool isRegistered;
        uint256 registrationTime;
        string ipfsHash; // IPFS hash for student details
        bool isLoggedIn;  // Track if the student is logged in
    }

    // Mappings
    mapping(address => Student) internal students;
    mapping(uint256 => address) internal studentIDs;

    // Events
    event StudentRegistered(address indexed studentAddress, uint256 studentID, string ipfsHash, uint256 timestamp);
    event StudentProfileUpdated(address indexed studentAddress, uint256 studentID, string newIpfsHash, uint256 timestamp);
    event StudentLoggedIn(address indexed studentAddress, uint256 timestamp);
    event StudentLoggedOut(address indexed studentAddress, uint256 timestamp);

    // Modifiers
    modifier onlyUnregisteredStudent() {
        if (students[msg.sender].isRegistered) revert AlreadyRegisteredStudent();
        _;
    }

    modifier onlyRegisteredStudent() {
        if (!students[msg.sender].isRegistered) revert NotRegisteredStudent();
        _;
    }

    modifier onlyLoggedInStudent() {
        if (!students[msg.sender].isLoggedIn) revert StudentNotLoggedIn();
        _;
    }

    modifier validStudentID(uint256 _studentID) {
        if (_studentID == 0) revert InvalidStudentID();
        _;
    }

    // Student Registration with IPFS Hash
    function registerStudent(uint256 _studentID, string memory _ipfsHash) 
        external 
        onlyUnregisteredStudent 
        validStudentID(_studentID)
        returns (bool) 
    {
        if (bytes(_ipfsHash).length == 0) revert EmptyIPFSHash();
        if (studentIDs[_studentID] != address(0)) revert InvalidStudentID(); // Ensures ID is unique

        students[msg.sender] = Student({
            studentID: _studentID,
            wallet: msg.sender,
            isRegistered: true,
            registrationTime: block.timestamp,
            ipfsHash: _ipfsHash,
            isLoggedIn: true // Automatically log in upon registration
        });

        studentIDs[_studentID] = msg.sender;

        emit StudentRegistered(msg.sender, _studentID, _ipfsHash, block.timestamp);
        emit StudentLoggedIn(msg.sender, block.timestamp); // Emit login event on registration
        return true;
    }

    // Update student profile with new IPFS hash
    function updateStudentProfile(string memory _newIpfsHash) 
        external 
        onlyRegisteredStudent 
        onlyLoggedInStudent 
        returns (bool) 
    {
        if (bytes(_newIpfsHash).length == 0) revert EmptyIPFSHash();
        
        students[msg.sender].ipfsHash = _newIpfsHash;

        emit StudentProfileUpdated(msg.sender, students[msg.sender].studentID, _newIpfsHash, block.timestamp);
        return true;
    }

    // Student Login
    function loginStudent() 
        external 
        onlyRegisteredStudent 
    {
        if (students[msg.sender].isLoggedIn) revert StudentAlreadyLoggedIn();

        students[msg.sender].isLoggedIn = true;
        emit StudentLoggedIn(msg.sender, block.timestamp);
    }

    // Student Logout
    function logoutStudent() 
        external 
        onlyRegisteredStudent 
        onlyLoggedInStudent 
    {
        students[msg.sender].isLoggedIn = false;
        emit StudentLoggedOut(msg.sender, block.timestamp);
    }

    // Additional Functions for Management, Querying, etc.
    function getStudentDetails(address _studentAddress) 
        external 
        view 
        onlyRegisteredStudent 
        onlyLoggedInStudent 
        returns (Student memory) 
    {
        return students[_studentAddress];
    }
}
