// SPDX-License-Identifier: MIT
 pragma solidity 0.8.28;

// import "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
// import {SchoolContract} from "./School.sol";
// import {StudentsContract} from "./Student.sol";
// import {CredentialContract} from "./Credentials.sol";

// contract DCNcontract is AccessControl, SchoolContract, StudentsContract, CredentialContract {

//     SchoolContract public schoolcontract;
//     StudentsContract public studentcontract;
//     CredentialContract public credentialcontract;

//     constructor(address initialOwner) 
//         CredentialContract(initialOwner) // Pass initialOwner to CredentialContract constructor
//     {
//         // Constructor logic here if needed
//     }

//     // Override supportsInterface to resolve the conflict between AccessControl and CredentialContract
//     function supportsInterface(bytes4 interfaceId)
//         public
//         view
//         virtual
//         override(AccessControl, CredentialContract)
//         returns (bool)
//     {
//         return super.supportsInterface(interfaceId);
//     }
// }