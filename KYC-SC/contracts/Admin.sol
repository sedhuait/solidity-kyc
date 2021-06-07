pragma solidity 0.8.0;
// SPDX-License-Identifier: MIT

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

    modifier onlyOwner {
        require(msg.sender == owner, "UnAuthorised Trasaction. Admin Only");
        _;
    }

    modifier onlyBank {
        require(banks[msg.sender].ethAddress != address(0), "UnAuthorised Transaction. Bank Only");
        _;
    }

    modifier activeBank {
        Bank memory _detail = banks[msg.sender];
        require(_detail.ethAddress != address(0) && _detail.isAllowedToVote, "UnAuthorised Transaction. Active Bank Only");
        _;
    }


    function getBankComplaints(address  _bankAddress) public view returns(uint256){
        Bank storage detail = banks[_bankAddress];
        require(detail.ethAddress != address(0), "Bank doesn't exist");
        return detail.complaintsReported;
    }

    function viewBankDetails(address _bankAddress) public view returns(Bank memory){
        Bank storage detail = banks[_bankAddress];
        require(detail.ethAddress != address(0), "Bank doesn't exist");
        return detail;
    }

    function reportBank(address  _bankAddress) public activeBank {
        Bank storage detail = banks[_bankAddress];
        require(detail.ethAddress != address(0), "Bank doesn't exist");
        detail.complaintsReported++;
        if(detail.complaintsReported * 3 > activeBanksCount){ // if 1/3 of the banks have reported a bank then revoke the rights
            _changeVotingRights(_bankAddress, false);
        }

    }

    function addBank(string calldata _name, address _bankAddress, string calldata _registrationNumber) external onlyOwner {
        Bank storage detail = banks[_bankAddress];
        require(detail.ethAddress == address(0), "Bank exist already");
        banks[_bankAddress] = Bank(_name,_bankAddress,0,0,true,_registrationNumber);
        activeBanksCount++;
    }

    function _changeVotingRights(address _bankAddress, bool _isAllowedToVote) private {
        Bank storage detail = banks[_bankAddress];
        require(detail.ethAddress != address(0), "Bank doesn't exist");
        detail.isAllowedToVote = _isAllowedToVote;
        if(!_isAllowedToVote){
            activeBanksCount--;
        }
    }

    function toggleVote(address _bankAddress, bool _isAllowedToVote) external onlyOwner {
        _changeVotingRights(_bankAddress,_isAllowedToVote);
    }

    function removeBank(address _bankAddress) external onlyOwner {
        Bank storage detail = banks[_bankAddress];
        require(detail.ethAddress != address(0), "Bank doesn't exist");
        delete(banks[_bankAddress]);
        activeBanksCount--;
    }
}
