// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Marketplace {
    address public owner;
    uint public artisansLength;
    address public cUsdTokenAddress;
    uint public gasPrice;

    struct Artisan {
        address payable owner;
        string name;
        string image;
        string description;
        string location;
        uint price;
        uint sold;
        bool active;
    }

    mapping(uint => Artisan) public artisans;

    event ArtisanAdded(address indexed owner, string name, uint price);
    event ArtisanHired(address indexed buyer, address indexed artisanOwner, string artisanName, uint price);
    event ArtisanRemoved(address indexed owner, string name);

    constructor(address _cUsdTokenAddress) {
        owner = msg.sender;
        cUsdTokenAddress = _cUsdTokenAddress;
        gasPrice = 1000000000; // Default gas price in wei (1 Gwei)
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function setGasPrice(uint _gasPrice) public onlyOwner {
        gasPrice = _gasPrice;
    }

    function addArtisan(
        string memory _name,
        string memory _image,
        string memory _description,
        string memory _location,
        uint _price
    ) public {
        require(_price > 0, "Price must be greater than zero");
        artisans[artisansLength] = Artisan(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _location,
            _price,
            0,
            true
        );
        artisansLength++;
        emit ArtisanAdded(msg.sender, _name, _price);
    }

    function removeArtisan(uint _index) public {
        require(_index < artisansLength, "Invalid artisan index");
        require(artisans[_index].owner == msg.sender, "Only the artisan owner can remove it");
        artisans[_index].active = false;
        emit ArtisanRemoved(msg.sender, artisans[_index].name);
    }

    function hireArtisan(uint _index) public payable {
        require(_index < artisansLength, "Invalid artisan index");
        Artisan storage artisan = artisans[_index];
        require(artisan.active, "Artisan is not available");
        require(msg.value >= gasPrice * 21000, "Insufficient ether for gas");

        uint totalPayment = artisan.price;
        uint refundAmount = msg.value - totalPayment;
        artisan.sold++;
        artisan.owner.transfer(totalPayment);
        msg.sender.transfer(refundAmount);

        emit ArtisanHired(msg.sender, artisan.owner, artisan.name, artisan.price);
    }

    function hireArtisanForDiscount(uint _index) public payable {
        require(_index < artisansLength, "Invalid artisan index");
        Artisan storage artisan = artisans[_index];
        require(artisan.active, "Artisan is not available");
        require(msg.value >= gasPrice * 21000, "Insufficient ether for gas");

        uint totalPayment = (artisan.price * 70) / 100;
        uint refundAmount = msg.value - totalPayment;
        artisan.sold++;
        artisan.owner.transfer(totalPayment);
        msg.sender.transfer(refundAmount);

        emit ArtisanHired(msg.sender, artisan.owner, artisan.name, totalPayment);
    }
}
