// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;
import "./Credentials.sol";
import "./TimeManagement.sol";

contract StudentContract {

    using TimeManagement for TimeManagement.TimeManagerStorage;

    //Adding credential contract instannce
    CredentialContract private credentialContract;
    
    //Adding consructor to initialize the credentiALContract.
    constructor(address _credentialContractAddress) {
        credentialContract = CredentialContract(_credentialContractAddress);
    }
    
    TimeManagement.TimeManagerStorage private timeManager;

    struct CredentialInfo {
    bytes32 credentialHash;
    string courseName;
    string grade;
    uint256 issueDate;
    address issuer;
    string credentialURI;
}

    struct StudentStruct{
        string  ipfsHash;
        address addedWallet;
    }
    mapping(address=>StudentStruct) internal student;

     error NotLoggedIn();

         modifier onlyLoggedIn() {
        if (!timeManager.isUserLoggedIn(msg.sender)) revert NotLoggedIn();
        _;
    }
    
    function studentLogin() public returns (string memory) {
        return timeManager.logIn();
    }
    
    function studentLogout() public returns (string memory) {
        return timeManager.logOut();
    }
    
    function updateProfile(
        string  memory _ipfsHash,
        address _addedWallet
        ) external onlyLoggedIn returns(string memory){    
            student[msg.sender] = StudentStruct({
              ipfsHash : _ipfsHash,
              addedWallet :  _addedWallet 
            });
            return "Success";    
        }

        function verifyCredential(uint256  _credentialId, address _issuer) external view returns(bool){
            return credentialContract.ownerOf(_credentialId) == _issuer;
        }

        function claimCredential(bytes32 _credentialHash) public onlyLoggedIn returns(string memory){

            credentialContract.claimCredential(_credentialHash);

            return "Successfully claimed the credential";
        }

    function getMyCredentials() external view onlyLoggedIn returns (CredentialInfo[] memory) {
    uint256[] memory tokenIds = credentialContract.getOwnedCredentials(msg.sender);
    CredentialInfo[] memory credentials = new CredentialInfo[](tokenIds.length);
    
    for (uint256 i = 0; i < tokenIds.length; i++) {
        bytes32 hash = credentialContract.getHashFromTokenId(tokenIds[i]);
        string memory courseName = credentialContract.getCourseName(hash);
        string memory grade = credentialContract.getGrade(hash);
        uint256 issueDate = credentialContract.getIssueDate(hash);
        address issuer = credentialContract.getCredentialIssuer(hash);
        string memory uri = credentialContract.getCredentialURI(hash);
        
        credentials[i] = CredentialInfo({
            credentialHash: hash,
            courseName: courseName,
            grade: grade,
            issueDate: issueDate,
            issuer: issuer,
            credentialURI: uri
        });
    }
    
    return credentials;
}
}