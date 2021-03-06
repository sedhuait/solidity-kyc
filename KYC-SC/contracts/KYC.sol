pragma solidity 0.8.0;
// SPDX-License-Identifier: MIT
import "./Admin.sol";

/// @title KYC
/// @notice To handle KYC Workflows
/// @dev
/// @author sedhu
contract KYC is Admin {
    struct Customer{
        string username; // unique username , primary identifier
        string data; // idenities of the customer
        bool kycStatus; // If the number of upvotes/downvotes meet the required conditions, set kycStatus to true; otherwise, set it to false.
        uint256 downVotes;
        uint256 upVotes;
        address bank; // validated bank
    }

    struct KYCRequest{
        string username;
        address bankAddress;
        string customerData;
    }

    mapping(string => Customer) private customers;

    mapping(string => uint256) private customerKYCCountMap;

    mapping(address => mapping(string => KYCRequest)) private bankCustomerKYCRequestsMap;

    mapping(address => mapping (string => bool)) private bankCustomerVotingMap; // Bank To Customer Downvote mapping

    modifier hasVotedAlready(string memory _customerName) {
        Customer memory _detail = customers[_customerName];
        require(
            !bankCustomerVotingMap[msg.sender][string(abi.encodePacked(_customerName, _detail.data))],
            "Already voted for the given customer");
        _;
    }

    modifier kycExists(string memory _customerName) {
        Customer memory _detail = customers[_customerName];
        require(_detail.bank != address(0), "Customer doesn't exist");
        require(customerKYCCountMap[_customerName] > 0, "No KYC Request exist for the given customer");
        _;
    }

    function _recordVoting(string memory _customerName) private {
        Customer storage _detail = customers[_customerName];
        bankCustomerVotingMap[msg.sender][string(abi.encodePacked(_customerName, _detail.data))] = true;
    }

    /// @notice Add customer api call
    /// @dev
    /// @param _customerName name of the customer
    /// @param _customerData datahash of the customer
    function addCustomer(string memory _customerName, string memory _customerData) public activeBank {
        require(customers[_customerName].bank == address(0), "Customer exist already");
        customers[_customerName] = Customer(_customerName, _customerData,false,0,0, msg.sender);

    }

    /// @notice Modify customer data API
    /// @dev Resets customer votes and kyc status
    /// @param _customerName name of the customer
    /// @param _customerData datahash of the customer
    function modifyCustomer(string memory _customerName, string memory _customerData) public activeBank {
        Customer storage detail = customers[_customerName];
        require(detail.bank != address(0), "Customer doesn't exist");
        detail.data = _customerData;
        detail.kycStatus = false;
        detail.downVotes = 0;
        detail.upVotes = 0;
    }

    /// @notice to view the customer data
    /// @dev
    /// @param _customerName name of the customer
    /// @return data customer data hash
    /// @return kycStats KYC Status of the customer
    /// @return downVotes no of downVotes
    /// @return upVotes no of upvotes
    /// @return bank address of the bank which created the customr in the system
    function viewCustomer(string memory _customerName) public view onlyBank returns( string memory,
        string memory,
        bool,
        uint256,
        uint256,
        address)
    {
        Customer memory detail = customers[_customerName];
        require(detail.bank != address(0), "Customer doesn't exist");
        return (detail.username, detail.data, detail.kycStatus, detail.downVotes, detail.upVotes, detail.bank);
    }

    /// @notice
    /// @dev
    /// @param _customer customer object to check
    function _checkCustomerKYCConditions(Customer storage _customer) private activeBank {
        _customer.kycStatus = _customer.upVotes > _customer.downVotes && (_customer.downVotes * 3 < activeBanksCount);
    }

    /// @notice To Approve Customer KYC
    /// @dev
    /// @param _customerName unique name of the customer
    function upvoteCustomer(string memory _customerName) public activeBank kycExists(_customerName) hasVotedAlready(_customerName) {
        Customer storage detail = customers[_customerName];
        require(detail.bank != address(0), "Customer doesn't exist");
        detail.upVotes++;
        _checkCustomerKYCConditions(detail);
        _recordVoting(_customerName);
    }

    /// @notice To decline customer KYC
    /// @dev
    /// @param _customerName unique name of the customer
    function downvoteCustomer(string memory _customerName) public activeBank kycExists(_customerName) hasVotedAlready(_customerName) {
        Customer storage detail = customers[_customerName];
        require(detail.bank != address(0), "Customer doesn't exist");
        detail.downVotes++;
        _checkCustomerKYCConditions(detail);
        _recordVoting(_customerName);
    }

    /// @notice To initiate the KYC request. If customer is not present then it will be addded. Also if there is request already for the customer then error will be thrown
    /// @dev
    /// @param _customerName unique name of the customer
    /// @param _dataHash data of the customer
    function addRequest(string calldata _customerName, string calldata _dataHash) external activeBank {
        Customer storage detail = customers[_customerName];
        if(detail.bank == address(0)){ // Customer not present, so add to the system b4 initiating the KYC
            addCustomer(_customerName, _dataHash);
        }
        require(bankCustomerKYCRequestsMap[msg.sender][_customerName].bankAddress == address(0),"KYC Request Exist Already");
        bankCustomerKYCRequestsMap[msg.sender][_customerName] = KYCRequest(_customerName,msg.sender,_dataHash);
        if(customerKYCCountMap[_customerName]>0){
            customerKYCCountMap[_customerName]++;
        }else{
            customerKYCCountMap[_customerName] = 1;
        }

        banks[msg.sender].kycCount++;
    }

    /// @notice to remove customer kyc request in queue API
    /// @dev
    /// @param _customerName unique name of the customer
    function removeRequest(string calldata _customerName) external onlyBank {
        require(bankCustomerKYCRequestsMap[msg.sender][_customerName].bankAddress != address(0),"KYC Request doesn't exist");
        require(bankCustomerKYCRequestsMap[msg.sender][_customerName].bankAddress == msg.sender,"KYC was added by a different bank");
        delete(bankCustomerKYCRequestsMap[msg.sender][_customerName]);
        customerKYCCountMap[_customerName]--;
    }

}
