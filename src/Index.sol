// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract DCN {

    // Define enums for NamingService and SchoolType
    enum NamingService {
        Claimed,
        NotClaimed
    }

    enum SchoolType {
        Private,
        Public,
        Online
    }

    // Define the structure for a School
    struct SchoolStruct {
        string name;
        string description;
        uint256 id;
        SchoolType schooltype;
        NamingService namingservice;
        string naming; // Store the actual naming service (e.g., harvard.arb)
    }

    // Mapping to store schools with their unique ID
    mapping(uint256 => SchoolStruct) public Schools;

    uint256 public schoolCount;

    // Helper function to check if a string ends with '.arb'
    function endsWithArb(string memory str) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory suffix = bytes(".arb");
        if (strBytes.length < suffix.length) {
            return false;
        }
        for (uint i = 0; i < suffix.length; i++) {
            if (strBytes[strBytes.length - suffix.length + i] != suffix[i]) {
                return false;
            }
        }
        return true;
    }

    // Function to register a new school
    function registerSchool(
        string memory _name, 
        string memory _description, 
        uint256 _id, 
        SchoolType _schooltype, 
        NamingService _namingservice,
        string memory _naming // The actual naming service (e.g., harvard.arb)
    ) external returns (string memory) {
        // Check if the school with the provided ID has already been registered
        require(Schools[_id].id == 0, "The school with this ID has already been registered");

        // Ensure that a NamingService has been claimed before proceeding
        require(_namingservice == NamingService.Claimed, "Naming service must be claimed before registration. Please claim and try again.");
        require(Schools[_id].namingservice != 0,"The name exist");

        // Check if the naming service ends with '.arb'
        require(endsWithArb(_naming), "The naming service must end with '.arb'.");

        // Create a new school and store it in the Schools mapping
        Schools[_id] = SchoolStruct({
            name: _name,
            description: _description,
            id: _id,
            schooltype: _schooltype,
            namingservice: _namingservice,
            naming: _naming
        });

        // Increment the school count after successful registration
        schoolCount++;

        // Return success message
        return "Congrats! The school has been registered with the naming service claimed.";
    }
}
