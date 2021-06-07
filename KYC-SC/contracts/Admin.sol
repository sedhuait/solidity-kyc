pragma solidity 0.8.0;
// SPDX-License-Identifier: MIT

/// @title Admin
/// @notice to handle the ADMIN Workflows
/// @dev
/// @author sedhu
contract Admin {
    address private owner;

    struct Bank{
        string name;
        address ethAddress; //  unique Ethereum address of the bank/organisation
        uint256  complaintsReported; // number of complaints against this bank done by other banks in the network.
        uint256 kycCount; // number of KYC requests initiated by the bank/organisation.
        bool isAllowedToVote;
        string regNumber; //   registration number for the bank.
    }

    uint256 internal activeBanksCount = 0;

    mapping(address => Bank) internal banks;

    constructor() {
        owner = msg.sender;
    }

    /// @dev onwer of contract only
    modifier onlyOwner {
        require(msg.sender == owner, "UnAuthorised Trasaction. Admin Only");
        _;
    }

    /// @dev only bank can access
    modifier onlyBank {
        require(banks[msg.sender].ethAddress != address(0), "UnAuthorised Transaction. Bank Only");
        _;
    }

    /// @dev only bank with voting rights can access
    modifier activeBank {
        Bank memory _detail = banks[msg.sender];
        require(_detail.ethAddress != address(0) && _detail.isAllowedToVote, "UnAuthorised Transaction. Active Bank Only");
        _;
    }


    /// @notice gets bank complaints count
    /// @dev
    /// @param _bankAddress ethAddress of the bank
    /// @return [uint] no of complaints
    function getBankComplaints(address  _bankAddress) public view returns(uint256){
        Bank storage detail = banks[_bankAddress];
        require(detail.ethAddress != address(0), "Bank doesn't exist");
        return detail.complaintsReported;
    }

    /// @notice to get the bank details
    /// @dev
    /// @param _bankAddress ethAddress of the bank
    /// @return [Bank] object
    function viewBankDetails(address _bankAddress) public view returns(Bank memory){
        Bank storage detail = banks[_bankAddress];
        require(detail.ethAddress != address(0), "Bank doesn't exist");
        return detail;
    }

    /// @notice repoting suspicios banks
    /// @dev
    /// @param _bankAddress ethAddress of the bank
    function reportBank(address  _bankAddress) public activeBank {
        Bank storage detail = banks[_bankAddress];
        require(detail.ethAddress != address(0), "Bank doesn't exist");
        detail.complaintsReported++;
        if(detail.complaintsReported * 3 > activeBanksCount){ // if 1/3 of the banks have reported a bank then revoke the rights
            _changeVotingRights(_bankAddress, false);
        }

    }

    /// @notice
    /// @dev
    /// @param _name bank name
    /// @param _bankAddress ethAddress of the bank
    /// @param _registrationNumber bank registration number
    function addBank(string calldata _name, address _bankAddress, string calldata _registrationNumber) external onlyOwner {
        Bank storage detail = banks[_bankAddress];
        require(detail.ethAddress == address(0), "Bank exist already");
        banks[_bankAddress] = Bank(_name,_bankAddress,0,0,true,_registrationNumber);
        activeBanksCount++;
    }

    /// @notice
    /// @dev
    /// @param _bankAddress ethAddress of the bank
    /// @param _isAllowedToVote toggle voting rights
    function _changeVotingRights(address _bankAddress, bool _isAllowedToVote) private {
        Bank storage detail = banks[_bankAddress];
        require(detail.ethAddress != address(0), "Bank doesn't exist");
        detail.isAllowedToVote = _isAllowedToVote;
        if(!_isAllowedToVote){
            activeBanksCount--;
        }
    }

    /// @notice
    /// @dev
    /// @param _bankAddress ethAddress of the bank
    /// @param _isAllowedToVote toggle voting rights of the bank
    function toggleVote(address _bankAddress, bool _isAllowedToVote) external onlyOwner {
        _changeVotingRights(_bankAddress,_isAllowedToVote);
    }

    /// @notice
    /// @dev
    /// @param _bankAddress ethAddress of the bank
    function removeBank(address _bankAddress) external onlyOwner {
        Bank storage detail = banks[_bankAddress];
        require(detail.ethAddress != address(0), "Bank doesn't exist");
        delete(banks[_bankAddress]);
        activeBanksCount--;
    }
}
