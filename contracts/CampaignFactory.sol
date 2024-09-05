// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Campaign.sol";
import "@openzeppelin/contracts/proxy/Clones.sol"; 
contract cpFactory {

    event CpCreated(address indexed cpAddress, address indexed cpAdmin);

    address public implementationCp;
    address constant USDC_ADDRESS = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238; //USDC address on Sepolia

    constructor(address _implementationCp) {
        implementationCp = _implementationCp;
    }

    function createCp(address _cpAdmin, string memory _cpMetadata, uint256 _cpTargetAmount, uint256 _cpStart, uint256 _cpEnd) external returns(address) {
        address newCp = Clones.clone(implementationCp); // -> creates a new campaign contract
        Campaign(newCp).init(USDC_ADDRESS, _cpAdmin, _cpMetadata, _cpTargetAmount, _cpStart, _cpEnd);
        emit CpCreated(newCp, _cpAdmin);
        return(newCp);
    }

}