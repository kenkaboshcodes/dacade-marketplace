// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IERC20Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract Marketplace is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address internal cUsdTokenAddress;

    string[5] public couponCodes;

    struct Artisan {
        address payable owner;
        string name;
        string image;
        string description;
        string location;
        uint price;
        uint sold;
    }

    uint public artisansLength;
    mapping (uint => Artisan) public artisans;

    event ArtisanAdded(address indexed owner, string name, string image, uint indexed index);
    event ArtisanHired(uint indexed index, address indexed buyer, uint price, uint discountPrice, uint sold);

    constructor(address _tokenAddress) {
        cUsdTokenAddress = _tokenAddress;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        cUsdTokenAddress = _tokenAddress;
    }

    function addArtisan(
        string memory _name,
        string memory _image,
        string memory _description,
        string memory _location,
        uint _price
    ) external {
        require(_price > 0, "Price must be greater than zero");

        artisans[artisansLength] = Artisan({
            owner: payable(msg.sender),
            name: _name,
            image: _image,
            description: _description,
            location: _location,
            price: _price,
            sold: 0
        });

        emit ArtisanAdded(msg.sender, _name, _image, artisansLength);
        artisansLength++;
    }

    function hireArtisan(uint _index) external nonReentrant {
        Artisan storage artisan = artisans[_index];
        require(artisan.owner != address(0), "Artisan does not exist");
        require(artisan.price > 0, "Invalid price");

        uint priceToPay = artisan.price;
        require(transferTokens(msg.sender, artisan.owner, priceToPay), "Transfer failed");

        artisan.sold++;
        emit ArtisanHired(_index, msg.sender, artisan.price, priceToPay, artisan.sold);
    }

    function hireArtisanForDiscount(uint _index) external nonReentrant {
        Artisan storage artisan = artisans[_index];
        require(artisan.owner != address(0), "Artisan does not exist");
        require(artisan.price > 0, "Invalid price");

        uint discountPrice = artisan.price.mul(70).div(100);
        require(transferTokens(msg.sender, artisan.owner, discountPrice), "Transfer failed");

        artisan.sold++;
        emit ArtisanHired(_index, msg.sender, artisan.price, discountPrice, artisan.sold);
    }

    function getArtisansLength() external view returns (uint) {
        return artisansLength;
    }

    function getCouponCodes() external view returns (string[5] memory) {
        return couponCodes;
    }

    function transferTokens(address _from, address _to, uint _amount) internal returns (bool) {
        return IERC20Token(cUsdTokenAddress).transferFrom(_from, _to, _amount);
    }
}
