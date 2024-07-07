// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Dummy WETH
contract WETH is ERC20 {
    constructor(uint256 initialSupply) ERC20("Wrapped Ether", "WETH") {
        _mint(msg.sender, initialSupply * 10**decimals());
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

// Dummy USDC with 6 decimals
contract USDC is ERC20 {
    constructor(uint256 initialSupply) ERC20("USD Coin", "USDC") {
        _mint(msg.sender, initialSupply * 10**6);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

// Basic ERC20 token with mint function
contract TestToken is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * 10**decimals());
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract DeployTestTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Dummy WETH
        WETH weth = new WETH(1_000_000);
        console2.log("Dummy WETH deployed at:", address(weth));

        // Deploy Dummy USDC
        USDC usdc = new USDC(10_000_000);
        console2.log("Dummy USDC deployed at:", address(usdc));

        // Deploy 556 Bullets token
        TestToken bullets = new TestToken("556 Bullets", "BULLET", 1_000_000);
        console2.log("556 Bullets token deployed at:", address(bullets));

        // Deploy Metro token
        TestToken metro = new TestToken("Metro", "METROCAR", 2_000_000);
        console2.log("Metro token deployed at:", address(metro));

        vm.stopBroadcast();
    }
}