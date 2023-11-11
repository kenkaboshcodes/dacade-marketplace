// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// erc20 interface
interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Marketplace {
    //numbers of artisan. increment as each artisan registers
    uint internal artisansLength = 0;

    //cUSD token address
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    // Fixed sized array, all elements initialize to 0
    string[5] public couponCodes = ["35ty6", "78utr","uy789", "poy71", "9081a"];

    // declares a usedCodes array for used coupon codes
    string[] public usedCodes;

    //struct for each artisan
    struct Artisan {
        address payable owner;
        string name;
        string image;
        string description;
        string location;
        uint price;
        uint sold;
    }


    mapping (uint => Artisan) internal artisans;

    // adds a new artisan to blockchain
    function writeArtisan(
        string memory _name,
        string memory _image,
        string memory _description, 
        string memory _location, 
        uint _price
    ) public {
        uint _sold = 0;
        artisans[artisansLength] = Artisan(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _location,
            _price,
            _sold
        );
        artisansLength++;
    }

    // reads artisan from the blockchain
    function readArtisan(uint _index) public view returns (
        address payable,
        string memory, 
        string memory, 
        string memory, 
        string memory, 
        uint, 
        uint
    ) {
        return (
            artisans[_index].owner,
            artisans[_index].name, 
            artisans[_index].image, 
            artisans[_index].description, 
            artisans[_index].location, 
            artisans[_index].price,
            artisans[_index].sold
        );
    }

    // hires artisan and transfers cUSD to an artisan
    function hireArtisan(uint _index) public payable  {
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            artisans[_index].owner,
            artisans[_index].price
          ),
          "Transfer failed."
        );
        artisans[_index].sold++;
    }


    // hires artisan for a discounted amount of 30%
    function hireArtisanForDiscount(uint _index) public payable  {
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            artisans[_index].owner,
            artisans[_index].price*70/100
          ),
          "Transfer failed."
        );
        artisans[_index].sold++;
    }
    
    //push used codes
    function pushUsedCouponCode(string memory _couponCodes) public payable {
        usedCodes.push(_couponCodes);
    }
    
    // gets the length of all artisan in the blockchain
    function getArtisansLength() public view returns (uint) {
        return (artisansLength);
    }

    // gets coupon codes from the blockchain
    function getCouponCodes() public view returns (string[5] memory) {
        return (couponCodes);
    }

    // gets used coupon codes
    function getUsedCodes() public view returns (string[] memory) {
        return (usedCodes);
    }
}