// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

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

    uint internal artisansLength = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    // Fixed sized array, all elements initialize to 0
    string[5] public couponCodes = ["35ty6", "78utr","uy789", "poy71", "9081a"];

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
    
    
    function getArtisansLength() public view returns (uint) {
        return (artisansLength);
    }

    function getCouponCodes() public view returns (string[5] memory) {
        return (couponCodes);
    }
}