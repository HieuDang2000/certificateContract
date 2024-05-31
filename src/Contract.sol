// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CertificateManagementContract {
    address public owner;
    mapping(address => bool) public subAdmins;

    address[] public subAdminAddresses;
    uint public subAdminAddressesLength = 0;

    event SubAdminAdded(address indexed newSubAdmin);
    event SubAdminRemoved(address indexed oldSubAdmin);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not a owner");
        _;
    }
    modifier onlySubAdminOrOwner() {
        require(
            subAdmins[msg.sender] || owner == msg.sender,
            "Caller is not a sub-admin or owner"
        );
        _;
    }

    function addSubAdmin(address _newSubAdmin) public onlyOwner {
        require(!subAdmins[_newSubAdmin], "Address is already a sub-admin");
        subAdmins[_newSubAdmin] = true;

        subAdminAddresses.push(_newSubAdmin);
        subAdminAddressesLength++;
        emit SubAdminAdded(_newSubAdmin);
    }

    function removeSubAdmin(address _oldSubAdmin) public onlyOwner {
        require(subAdmins[_oldSubAdmin], "Address is not a sub-admin");
        subAdmins[_oldSubAdmin] = false;

        for (uint i = 0; i < subAdminAddresses.length; i++) {
            if (subAdminAddresses[i] == _oldSubAdmin) {
                subAdminAddresses[i] = subAdminAddresses[
                    subAdminAddresses.length - 1
                ];
                subAdminAddresses.pop();
                subAdminAddressesLength--;

                break;
            }
        }
        emit SubAdminRemoved(_oldSubAdmin);
    }

    struct CertificateType {
        string certType;
        string infos;
    }

    mapping(uint256 => CertificateType) public certificateTypes;
    uint256 public certTypeCount = 0;

    event CertificateTypeAdded(string certType, string[] info);

    function addCertificateType(
        string memory certType,
        string[] memory info
    ) public onlySubAdminOrOwner returns (uint256) {
        require(info.length > 0, "Certificate info cannot be empty");
        string memory infos = join(info, ",");
        certificateTypes[certTypeCount] = CertificateType(certType, infos);
        emit CertificateTypeAdded(certType, info);

        certTypeCount++;
        return certTypeCount;
    }

    struct Certificate {
        uint256 certTypeID;
        string email;
        string infos;
        bool isActive;
    }

    mapping(uint256 => Certificate) public certificates;
    uint256 public certCount = 0;

    mapping(string => uint256[]) public emailToCerts;
    mapping(string => uint256) public emailCertiCount;

    event CertificateAdded(uint256 certTypeID, string email);
    event CertificateDisabled(uint256 certID);

    function addCertificate(
        uint256 certTypeID,
        string memory email,
        string[] memory info
    ) public onlySubAdminOrOwner returns (uint256) {
        require(certTypeID < certTypeCount, "Invalid certificate type ID");

        string memory infos = join(info, ",");

        certificates[certCount] = Certificate(certTypeID, email, infos, true);
        emailToCerts[email].push(certCount);
        emailCertiCount[email] = emailToCerts[email].length;
        emit CertificateAdded(certCount, email);

        certCount++;
        return certCount;
    }

    function addCertificates(
        uint256[] memory certTypeIDs,
        string[] memory emails,
        string[][] memory infos
    ) public onlySubAdminOrOwner {
        for (uint256 i = 0; i < certTypeIDs.length; i++) {
            addCertificate(certTypeIDs[i], emails[i], infos[i]);
        }
    }

    function disableCertificate(uint256 certId) public onlySubAdminOrOwner {
        require(certId < certCount, "Invalid certificate ID");
        require(
            certificates[certId].isActive,
            "Certificate is already disabled"
        );

        certificates[certId].isActive = false;
        emit CertificateDisabled(certId);
    }

    function join(
        string[] memory parts,
        string memory delimiter
    ) private pure returns (string memory) {
        bytes memory result = "";
        for (uint i = 0; i < parts.length; i++) {
            result = abi.encodePacked(result, parts[i]);
            if (i < parts.length - 1) {
                result = abi.encodePacked(result, delimiter);
            }
        }
        return string(result);
    }
}
