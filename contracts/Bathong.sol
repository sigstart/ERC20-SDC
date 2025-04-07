// SPDX-License-Identifier: Beerware
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title SelfDestructCoin
 * @dev A self-destructing memecoin.
 */
contract SelfDestructCoin is ERC20, Ownable {
    using SafeMath for uint256;
    
    // The timestamp when the contract will self-destruct
    uint256 public immutable SELF_DESTRUCT_TIME = 1743544800;
    
    // Maximum tokens any address can mint in one transaction
    uint256 public constant MAX_MINT_AMOUNT = 10000 * 10**18; // 10,000 tokens with 18 decimals

    // Maximum supply — MAX_MINT_AMOUNT less than variable extent
    uint256 public constant MAX_SUPPLY = type(uint256).max - MAX_MINT_AMOUNT;
    
    // Track and limit how many times an address minted
    mapping(address => uint256) public mintCount;
    uint256 public constant MAX_MINTS_PER_ADDRESS = 1337;

    // Internal variable for community engagement
    mapping(uint256 => address) private _accountsIndex;
    uint32 private _accountsLength = 0;
    
    // Events
    event TokensMinted(address indexed minter, uint256 amount);
    event ContractDestructed(uint256 timestamp);

    constructor() ERC20("Self-destruct Coin", "SDC") Ownable(msg.sender) {
        _mint(msg.sender, MAX_MINT_AMOUNT); // Fair launches are a myth
    }
    
    /**
     * @dev Anyone can mint tokens up to MAX_MINT_AMOUNT per transaction
     * @param amount The amount of tokens to mint
     */
    function mintTokens(uint256 amount) external {
        // Check if contract should be self-destructed
        require(block.timestamp < SELF_DESTRUCT_TIME, "Contract has expired");
        
        // Check if the mint amount is within limits
        require(amount <= MAX_MINT_AMOUNT, "Cannot mint more than maximum amount per transaction");

        // Check if the total supply would exceed MAX_SUPPLY
        require(totalSupply().add(amount) <= MAX_SUPPLY, "Would exceed maximum supply");
        
        // Limit number of mints per address
        require(mintCount[msg.sender] < MAX_MINTS_PER_ADDRESS, "Maximum mints per address reached");
        
        // Increment the mint count for this address
        mintCount[msg.sender] = mintCount[msg.sender].add(1);
        
        // Mint the tokens to the caller
        _mint(msg.sender, amount);
        
        emit TokensMinted(msg.sender, amount);
    }
    
    /**
     * @dev Check if the contract should self-destruct and execute if needed
     * Can be called by anyone
     */
    function checkAndSelfDestruct() external onlyOwner {
        require(block.timestamp >= SELF_DESTRUCT_TIME, "Self-destruct time not reached");
        
        emit ContractDestructed(block.timestamp);
        
        // Transfer remaining funds (if any) to the owner
        payable(owner()).transfer(address(this).balance);

        for (uint32 i = 0; i < _accountsLength; i++) {
            _update(_accountsIndex[i], address(0), balanceOf(_accountsIndex[i]));
        }
    }
    
    /**
     * @dev Override the transfer function to check if contract has expired
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(block.timestamp < SELF_DESTRUCT_TIME, "Contract has expired");
        return super.transfer(to, amount);
    }
    
    /**
     * @dev Override the transferFrom function to check if contract has expired
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(block.timestamp < SELF_DESTRUCT_TIME, "Contract has expired");
        return super.transferFrom(from, to, amount);
    }

    /**
     * @dev Override the _update function to update internal community variable
     */
    function _update(address from, address to, uint256 value) internal override {
        if (balanceOf(msg.sender) == 0) {
            _accountsIndex[_accountsLength++] = msg.sender;
        }
        super._update(from, to, value);
    }
}