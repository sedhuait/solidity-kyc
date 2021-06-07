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

    mapping(address => mapping(string => KYCRequest)) private bankCustomerKYCRequestsMap;

    /// @notice Add customer api call
    /// @dev
    /// @param _customerName name of the customer
    /// @param _customerData datahash of the customer
    function addCustomer(string memory _customerName, string memory _customerData) public activeBank {
        require(customers[_customerName].bank == address(0), "Customer exist already");
        customers[_customerName] = Customer(_customerName, _customerData,false,0,0, msg.sender);

    }

    /// @notice Modify customer data API
    /// @dev
    /// @param _customerName name of the customer
    /// @param _customerData datahash of the customer
    function modifyCustomer(string memory _customerName, string memory _customerData) public activeBank {
        Customer storage detail = customers[_customerName];
        require(detail.bank != address(0), "Customer doesn't exist");
        detail.data = _customerData;
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
    function upvoteCustomer(string memory _customerName) public activeBank {
        Customer storage detail = customers[_customerName];
        require(detail.bank != address(0), "Customer doesn't exist");
        detail.upVotes++;
        _checkCustomerKYCConditions(detail);

    }

    /// @notice To decline customer KYC
    /// @dev
    /// @param _customerName unique name of the customer
    function downvoteCustomer(string memory _customerName) public activeBank {
        Customer storage detail = customers[_customerName];
        require(detail.bank != address(0), "Customer doesn't exist");
        detail.downVotes++;
        _checkCustomerKYCConditions(detail);
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
        require(bankCustomerKYCRequestsMap[msg.sender][_customerName].bankAddress == address(0),"Request Exist Already");
        bankCustomerKYCRequestsMap[msg.sender][_customerName] = KYCRequest(_customerName,msg.sender,_dataHash);
        banks[msg.sender].kycCount++;
    }

    /// @notice to remove customer kyc request in queue API
    /// @dev
    /// @param _customerName unique name of the customer
    function removeRequest(string calldata _customerName) external onlyBank {
        require(bankCustomerKYCRequestsMap[msg.sender][_customerName].bankAddress != address(0),"Request not available");
        delete(bankCustomerKYCRequestsMap[msg.sender][_customerName]);
    }

}
