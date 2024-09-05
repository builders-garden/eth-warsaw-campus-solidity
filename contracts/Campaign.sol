// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Campaign is ERC1155 {
    //usdc token address on Base network
    address public usdcAddress;

    //campaign status
    bool public goalReached; //false by default
    bool public isInitialized;
    bool public isPaused;

    //campaign details
    address public cpAdmin;
    string  public cpMetadata;
    uint256 public cpTargetAmount;
    uint256 public cpStart;
    uint256 public cpEnd;

    modifier onlyAdmin() {
        require(msg.sender == cpAdmin, "Only campaign admin can call this function");
        _;
    }

    constructor(address _usdcAddress, address _cpAdmin, string memory _cpMetadata, uint256 _cpTargetAmount, uint256 _cpStart, uint256 _cpEnd) ERC1155(""){
        _createCampaign(_usdcAddress, _cpAdmin, _cpMetadata, _cpTargetAmount, _cpStart, _cpEnd);
    }
    
    //initialize the campaign
    function init(address _usdcAddress, address _cpAdmin, string memory _cpMetadata, uint256 _cpTargetAmount, uint256 _cpStart, uint256 _cpEnd) public {
       _createCampaign(_usdcAddress, _cpAdmin, _cpMetadata, _cpTargetAmount, _cpStart, _cpEnd);
    }

    // cpAdmin functions
    //function to create a campaign
    function createCampaign(address _usdcAddress, address _cpAdmin, string memory _cpMetadata, uint256 _cpTargetAmount, uint256 _cpStart, uint256 _cpEnd) external onlyAdmin {
        _createCampaign(_usdcAddress, _cpAdmin, _cpMetadata, _cpTargetAmount, _cpStart, _cpEnd);
    }

    //function to pause the campaign
    function pauseCampaign() external onlyAdmin {
        require(cpStart > block.timestamp, "Campaign has not started");
        isPaused = true;
    }

    //function for the cpAdmin to claim the campaign funds
    function claim() external onlyAdmin {
        require(cpEnd < block.timestamp, "Campaign has not ended");
        require(goalReached, "Campaign goal has not been reached");
        IERC20(usdcAddress).transfer(cpAdmin, IERC20(usdcAddress).balanceOf(address(this)));
    }

    //donor functions
    //function to donate to the campaign
    function donate(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(cpStart > block.timestamp, "Campaign has not started");
        require(block.timestamp < cpEnd, "Campaign has ended");
        require(!isPaused, "Campaign is paused");
        require(IERC20(usdcAddress).transferFrom(msg.sender, address(this), amount), "Transfer failed"); //campaign contract
        _mint(msg.sender, 1, amount, "");
        _checkCampaignGoal();
    }

    //function to withdraw the campaign funds
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(cpEnd > block.timestamp || (cpEnd < block.timestamp && !goalReached), "Campaign has not ended");
        _burn(msg.sender, 1, amount); 
        IERC20(usdcAddress).transfer(msg.sender, amount); //campaign contract
    }

    //internal functions

    //internal function to create a campaign used by createCampaign function or init function
    function _createCampaign(address _usdcAddress, address _cpAdmin, string memory _cpMetadata, uint256 _cpTargetAmount, uint256 _cpStart, uint256 _cpEnd) internal {
        require(!isInitialized, "Campaign already initialized");
        require(_usdcAddress != address(0), "Invalid USDC address"); 
        require(_cpAdmin != address(0), "Invalid campaign admin address");
        require(_cpTargetAmount > 0, "Target amount must be greater than 0");
        require(_cpStart > block.timestamp, "Start time must be in the future");
        require(_cpEnd > _cpStart, "End time must be after start time");

        usdcAddress = _usdcAddress;
        cpAdmin = _cpAdmin;
        cpMetadata = _cpMetadata;
        cpTargetAmount = _cpTargetAmount;
        cpStart = _cpStart;
        cpEnd = _cpEnd;
        //must be initialized once
        isInitialized = true;
    }
    
    //internal function to check if the campaign goal has been reached
    function _checkCampaignGoal() internal {
        if (IERC20(usdcAddress).balanceOf(address(this)) >= cpTargetAmount) {
            goalReached = true;
        }
    }
}