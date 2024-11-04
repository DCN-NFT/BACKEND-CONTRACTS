// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

library TimeManagement {
    // Events
    event UserLoggedIn(address indexed wallet, uint256 timestamp);
    event UserLoggedOut(address indexed wallet, uint256 timestamp);
    
    struct LogStruct {
        address wallet;
        bool isLoggedIn;
        uint256 timestamp;
        uint256 lastLoginTime;
        uint256 totalTimeLoggedIn;
    }
    
    // Storage for time management data
    struct TimeManagerStorage {
        mapping(address => LogStruct) logs;
        address[] activeUsers;
    }
    
    // Log in a user
    function logIn(TimeManagerStorage storage self) public returns (string memory) {
        LogStruct storage userLog = self.logs[msg.sender];
        
        require(!userLog.isLoggedIn, "User is already logged in");
        
        // Initialize first time users
        if (userLog.wallet == address(0)) {
            userLog.wallet = msg.sender;
            self.activeUsers.push(msg.sender);
        }
        
        userLog.isLoggedIn = true;
        userLog.lastLoginTime = block.timestamp;
        userLog.timestamp = block.timestamp;
        
        emit UserLoggedIn(msg.sender, block.timestamp);
        return "Successfully logged in";
    }
    
    // Log out a user
    function logOut(TimeManagerStorage storage self) public returns (string memory) {
        LogStruct storage userLog = self.logs[msg.sender];
        
        require(userLog.isLoggedIn, "User is not logged in");
        
        userLog.isLoggedIn = false;
        userLog.totalTimeLoggedIn += block.timestamp - userLog.lastLoginTime;
        
        emit UserLoggedOut(msg.sender, block.timestamp);
        return "Successfully logged out";
    }
    
    // Get user's login status
    function isUserLoggedIn(TimeManagerStorage storage self, address user) public view returns (bool) {
        return self.logs[user].isLoggedIn;
    }
    
    // Get user's total time logged in
    function getTotalTimeLoggedIn(TimeManagerStorage storage self, address user) public view returns (uint256) {
        LogStruct storage userLog = self.logs[user];
        
        if (userLog.isLoggedIn) {
            return userLog.totalTimeLoggedIn + (block.timestamp - userLog.lastLoginTime);
        }
        return userLog.totalTimeLoggedIn;
    }
    
    // Get last login time
    function getLastLoginTime(TimeManagerStorage storage self, address user) public view returns (uint256) {
        return self.logs[user].lastLoginTime;
    }
    
    // Get all active users
    function getActiveUsers(TimeManagerStorage storage self) public view returns (address[] memory) {
        return self.activeUsers;
    }
}
