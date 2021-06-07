pragma solidity 0.8.0;
// SPDX-License-Identifier: MIT
import "./Admin.sol";

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


    function addCustomer(string memory _customerName, string memory _customerData) public activeBank {
        require(customers[_customerName].bank == address(0), "Customer exist already");
        customers[_customerName] = Customer(_customerName, _customerData,false,0,0, msg.sender);

    }

    function modifyCustomer(string memory _customerName, string memory _customerData) public activeBank {
        Customer storage detail = customers[_customerName];
        require(detail.bank != address(0), "Customer doesn't exist");
        detail.data = _customerData;
    }

    function viewCustomer(string memory _customerName) public view onlyBank returns( string memory username,
        string memory data,
        bool kycStats,
        uint256 downVotes,
        uint256 upVotes,
        address bank)
    {
        Customer memory detail = customers[_customerName];
        require(detail.bank != address(0), "Customer doesn't exist");
        return (detail.username, detail.data, detail.kycStatus, detail.downVotes, detail.upVotes, detail.bank);
    }

    function _checkCustomerKYCConditions(Customer storage _customer) private activeBank {
        _customer.kycStatus = _customer.upVotes > _customer.downVotes && (_customer.downVotes * 3 < activeBanksCount);
    }

    function upvoteCustomer(string memory _customerName) public activeBank {
        Customer storage detail = customers[_customerName];
        require(detail.bank != address(0), "Customer doesn't exist");
        detail.upVotes++;
        _checkCustomerKYCConditions(detail);

    }

    function downvoteCustomer(string memory _customerName) public activeBank {
        Customer storage detail = customers[_customerName];
        require(detail.bank != address(0), "Customer doesn't exist");
        detail.downVotes++;
        _checkCustomerKYCConditions(detail);
    }

    function addRequest(string calldata _customerName, string calldata _dataHash) external activeBank {
        Customer storage detail = customers[_customerName];
        if(detail.bank == address(0)){ // Customer not present, so add to the system b4 initiating the KYC
            addCustomer(_customerName, _dataHash);
        }
        require(bankCustomerKYCRequestsMap[msg.sender][_customerName].bankAddress == address(0),"Request Exist Already");
        bankCustomerKYCRequestsMap[msg.sender][_customerName] = KYCRequest(_customerName,msg.sender,_dataHash);
        banks[msg.sender].kycCount++;
    }

    function removeRequest(string calldata _customerName) external onlyBank {
        require(bankCustomerKYCRequestsMap[msg.sender][_customerName].bankAddress != address(0),"Request not available");
        delete(bankCustomerKYCRequestsMap[msg.sender][_customerName]);
    }

}
