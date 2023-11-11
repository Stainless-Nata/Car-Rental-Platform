// // Uncomment this line to use console.log
// // import "hardhat/console.sol";

// contract Lock {
//     uint public unlockTime;
//     address payable public owner;

//     event Withdrawal(uint amount, uint when);

//     constructor(uint _unlockTime) payable {
//         require(
//             block.timestamp < _unlockTime,
//             "Unlock time should be in the future"
//         );

//         unlockTime = _unlockTime;
//         owner = payable(msg.sender);
//     }

//     function withdraw() public {
//         // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
//         // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

//         require(block.timestamp >= unlockTime, "You can't withdraw yet");
//         require(msg.sender == owner, "You aren't the owner");

//         emit Withdrawal(address(this).balance, block.timestamp);

//         owner.transfer(address(this).balance);
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CarRentalPlatform {
    // DATA
    // Counter
    uint256 private _counter;
    // Owner
    address private immutable owner;
    // Total Payments
    uint private totalPayments;
    // User Struct
    struct User {
        address walletAddress;
        string name;
        string lastName;
        uint rentCarId;
        uint balance;
        uint start;
        uint debt;
    }
    // Car Struct
    struct Car {
        uint id;
        string name;
        string imgUrl;
        Status status;
        uint rentFee;
        uint saleFee;
    }
    // enum to indicate the status of the car
    enum Status {
        Retires,
        Inuse,
        Available
    }
    // Events
    event CarAdded(
        uint indexed id,
        string name,
        string imgUrl,
        uint rentFee,
        uint saleFee
    );
    event CarMetaDataEdited(
        uint indexed id,
        string name,
        string imgUrl,
        uint rentFee,
        uint saleFee
    );
    event CarStatusEdited(uint indexed id, Status status);
    event UserAdded(
        address indexed walletAddress,
        string name,
        string lastName
    );
    event Deposit(address indexed walletAddress, uint amount);
    event CheckOut(address indexed walletAddress, uint indexed carId);
    event CheckIn(address indexed walletAddress, uint indexed carId);
    event PaymentMade(address indexed walletAddress, uint amount);
    event BalanceWithdrawn(address indexed walletAddress, uint amount);
    // User mapping
    mapping(address => User) private users;
    // Car mapping
    mapping(uint => Car) private cars;

    // Constructor
    constructor() {
        owner = msg.sender;
        totalPayments = 0;
    }

    // MODIFIERS
    // onlyOwner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // FUNCTIONS
    // Execute functions:
    //setOwner #onlyOwner
    // function setOwner(address _newOwner) external onlyOwner {
    //     owner = _newOwner;
    // }

    //addUser #nonExisting
    function addUser(string calldata name, string calldata lastname) external {
        require(!isUser(msg.sender), "User already exists");
        users[msg.sender] = User(msg.sender, name, lastname, 0, 0, 0, 0);

        emit UserAdded(
            msg.sender,
            users[msg.sender].name,
            users[msg.sender].lastName
        );
    }

    //addCar #onlyOwner #nonExistingCar
    function addCar(
        string calldata name,
        string calldata imgUrl,
        uint rentFee,
        uint saleFee
    ) external onlyOwner {
        _counter++;
        uint counter = _counter;
        cars[counter] = Car(
            counter,
            name,
            imgUrl,
            Status.Available,
            rentFee,
            saleFee
        );

        emit CarAdded(
            counter,
            cars[counter].name,
            cars[counter].imgUrl,
            cars[counter].rentFee,
            cars[counter].saleFee
        );
    }

    //editCarMetaData #onlyOwner #existingCar
    function editCarMetaData(
        uint id,
        string calldata name,
        string calldata imgUrl,
        uint rentFee,
        uint saleFee
    ) external onlyOwner {
        require(cars[id].id != 0, "Car with given ID do not exist");
        Car storage car = cars[id];
        if (bytes(name).length != 0) car.name = name;
        if (bytes(imgUrl).length != 0) car.imgUrl = imgUrl;
        if (rentFee > 0) car.rentFee = rentFee;
        if (saleFee > 0) car.saleFee = saleFee;

        emit CarMetaDataEdited(
            id,
            car.name,
            car.imgUrl,
            car.rentFee,
            car.saleFee
        );
    }

    //editCarStatus #onlyOwner #existingCar
    function editCarStatus(uint id, Status status) external onlyOwner {
        require(cars[id].id != 0, "Car with given ID does not exist");
        cars[id].status = status;

        emit CarStatusEdited(id, status);
    }

    //checkOut #existingUser #isCarAvailale #userHasNotRentedCar #userHasNoDebt
    function checkOut(uint id) external {
        require(isUser(msg.sender), "User does not exist");
        require(
            cars[id].status == Status.Available,
            "Car is not available for use"
        );
        require(
            users[msg.sender].rentCarId == 0,
            "User has already rented a car"
        );
        require(users[msg.sender].debt == 0, "User has an outstanding debt!");

        users[msg.sender].start = block.timestamp;
        users[msg.sender].rentCarId = id;
        cars[id].status = Status.Inuse;

        emit CheckOut(msg.sender, id);
    }

    //checkIn #existingUser #userHasRentedCar
    function checkIn() external {
        require(isUser(msg.sender), "User does not exist");
        uint renterCarId = users[msg.sender].rentCarId;
        require(renterCarId != 0, "User has not rented a car");

        uint usedSeconds = block.timestamp - users[msg.sender].start;
        uint rentFee = cars[renterCarId].rentFee;
        users[msg.sender].debt += calculateDebt(usedSeconds, rentFee);

        users[msg.sender].rentCarId = 0;
        users[msg.sender].start = 0;
        cars[renterCarId].status = Status.Available;

        emit CheckIn(msg.sender, renterCarId);
    }

    //deposit #existingUser
    function deposit() external payable {
        require(isUser(msg.sender), "User does not exist");
        users[msg.sender].balance += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    //makePayment #existingUser #existing #sufficientBalance
    function makePayment() external payable {
        require(isUser(msg.sender), "User does not exist");
        uint debt = users[msg.sender].debt;
        uint balance = users[msg.sender].balance;

        require(debt > 0, "User has no debt to pay");

        require(balance >= debt, "User has insuffucuent balance");

        unchecked {
            users[msg.sender].balance -= debt;
        }
        totalPayments += debt;
        users[msg.sender].debt = 0;

        emit PaymentMade(msg.sender, debt);
    }

    //withdrawBalance #existingUser
    function withdrawBalance(uint amount) external {
        require(isUser(msg.sender), "User does not exist");
        uint balance = users[msg.sender].balance;
        require(balance >= amount, "Insufficient balance to withdraw");

        unchecked {
            users[msg.sender].balance -= amount;
        }

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit BalanceWithdrawn(msg.sender, amount);
    }

    //withdrawOwnerBalance #onlyOwner
    function withdrawOwnerBalance(uint amount) external onlyOwner {
        require(
            totalPayments >= amount,
            "Insufficient contract balance to withdraw"
        );

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        unchecked {
            totalPayments -= amount;
        }
    }

    // Query functions:
    //getOwner
    function getOwner() external returns (address) {
        return owner;
    }

    //isUser
    function isUser(address walletAddress) private view returns (bool) {
        return users[walletAddress].walletAddress != address(0);
    }

    //getUser #existingUser
    function getUser(
        address walletAddress
    ) external view returns (User memory) {
        require(isUser(walletAddress), "User does not exist");
        return users[walletAddress];
    }

    //getCar #existingCar
    function getCar(uint id) external view returns (Car memory) {
        require(cars[id].id != 9, "Car does not exist");
        return cars[id];
    }

    //getCarByStatus
    function getCarByStatus(
        Status _status
    ) external view returns (Car[] memory) {
        uint count = 0;
        uint length = _counter;
        for (uint i = 1; i <= length; i++) {
            if (cars[i].status == _status) count++;
        }

        Car[] memory carWithStatus = new Car[](count);
        count = 0;
        for (uint i = 1; i <= length; i++) {
            if (cars[i].status == _status) {
                carWithStatus[count] = cars[i];
                count++;
            }
        }

        return carWithStatus;
    }

    //calculateDebt
    function calculateDebt(
        uint usedSeconds,
        uint rentFee
    ) private pure returns (uint) {
        uint usedMinutes = usedSeconds / 60;
        return usedMinutes * rentFee;
    }

    //getCurrentCount
    function getCurrentCount() external view returns (uint) {
        return _counter;
    }

    //getContractBalance #onlyOwner
    function getContractBalance() external view onlyOwner returns (uint) {
        return address(this).balance;
    }

    //getTotalPayment #onlyOwner
    function getTotalPayments() external view onlyOwner returns (uint) {
        return totalPayments;
    }
}
