## Geth Commands

To Initialise the Private Blockchain
```
geth --datadir ./datadir-alpha init ./Init.json
```

To Start the geth node in http with access to underlying apis and account unlock
```
geth --datadir ./datadir-alpha --networkid 2211 --http --http.api="eth,net,web3,personal,web3" --allow-insecure-unlock --http.addr "127.0.0.1" --http.port 8545 console
```


Create Accounts inside geth console with password (pwd@123), create multiple accounts and first account will be considered as the conibase account and also admin account for smart contract creation via truffle migrate
```
personal.newAccount("pwd@123")
```

Start Mining
```
miner.start()
```


## Truffle console commands

To access all the accounts in the blockchain
```
var accounts = await web3.eth.getAccounts();
```

To Access KYC smart contract
```
let kyc = await KYC.deployed();

```

To unlock an account
```
web3.eth.personal.unlockAccount(address, password, duration);
```

To access the methods inside smart contract and account needs to unlocked before invoking any method from the smart contract

```
 kyc.<method_name>(..args,{from:"source account of the transaction"});

 kyc.addBank("hdfc","0x5BD8bA18A1Bbd48be4da2815386310fC03c9FfA0",1);

 kyc.viewBankDetails("0x5BD8bA18A1Bbd48be4da2815386310fC03c9FfA0",{from:accounts[1]})

 ```
