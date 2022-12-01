// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./TestToken.sol";

contract MasterFork is Ownable{


   using SafeMath for uint256; 
   using SafeERC20 for IERC20;

//  Info of each user

    struct UserInfo {
       uint256 amount; // Lp tokens user has provided
       uint256 RewardRec; //Reward Received
    }

// Info of each pool
    struct PoolInfo{
      IERC20 lpToken; // Address of Lp Token contract.
      uint256 allocPoint; // How many allocation Point assigned to the pool.
      uint256 totalDeposited; // Total lp tokens deposited  
      uint256 accTestTokenPerShare; // Lat block no. that reeard Distributed.
      uint256 lastRewardBlock;  // Last Blockno. that Reward was distributed.
    }
    // The TestToken 
    TestToken public cake;
    // address to send the reward as a commission 
    address public myaddress;

    // TestToken created per block.
    uint256 public tokenPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
    // Total allocationpoint
    uint256 public totalAllocPoint;
     
    //The Block no. when TestToken minning starts.
    uint256 public startBlock;


    constructor(
        TestToken _cake,
        address _myaddress,
        uint256 _tokenPerBlock,
        uint256 _startBlock
    ) public {
        cake = _cake;
        myaddress = _myaddress;
        tokenPerBlock =_tokenPerBlock;
        startBlock = _startBlock;
        
        //staking pool
        poolInfo.push(PoolInfo({lpToken: _cake, allocPoint: 1000, totalDeposited: 0, lastRewardBlock: startBlock, accTestTokenPerShare: 0}));

        totalAllocPoint = 1000;
    }

    /**
     * @notice add a new lp to the pool
     * @param _lpToken address of the lptoken.
     * @param _allocPoint given to the pooltoken.
     */
    function add(IERC20 _lpToken, uint256 _allocPoint) public onlyOwner{
        require(_allocPoint < totalAllocPoint,"point more than totalAllocPoint");
        
        _lpToken.balanceOf(address(this));

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({lpToken: _lpToken, allocPoint: _allocPoint, totalDeposited: 0, accTestTokenPerShare: 0, lastRewardBlock: startBlock})
        );
    } 
     /**
     * @notice Update the given pool's TestToken allocation to the pool
     * @param _pid of the lptoken.
     * @param _allocPoint given to the pooltoken.
     */
       function set(uint256 _pid, uint256 _allocPoint) public onlyOwner{
        require(_allocPoint < totalAllocPoint,"point more than totalAllocPoint");

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }
    
    // Return reward multiplier over the given _from to _to block.

      function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }
      
     /**
     * @notice Update reward variables of the given pool to be up-to-date.
     * @param _pid of the given pool.
     */
      function updatePool(uint256 _pid) public {

        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 TokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        cake.mint(myaddress, TokenReward.div(10));
        pool.accTestTokenPerShare = pool.accTestTokenPerShare.add(TokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }
     /**
     * @notice Deposit LP tokens to MasterFork for TestTokenallocation
     * @param _pid of the given pool.
     * @param _amount of lptoken to Deposit.
     */
       
        function deposit(uint256 _pid, uint256 _amount) public {

           PoolInfo storage pool = poolInfo[_pid];
           UserInfo storage user = userInfo[_pid][msg.sender];
           updatePool(_pid);
            if (_amount > 0) {
            pool.totalDeposited = pool.totalDeposited.add(_amount);
            pool.lpToken.transferFrom(address(msg.sender),address(this), _amount);
            user.amount = user.amount.add(_amount);
       
        }

    
        user.RewardRec = user.amount.mul(pool.accTestTokenPerShare).div(1e12);
    }
     /**
     * @notice Withdraw LP tokens to MasterFork for TestToken allocation
     * @param _pid of the given pool.
     * @param _amount of lptoken to Withdraw.
     */

      function withdraw(uint256 _pid, uint256 _amount) external  {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "not enought amount to withdrwaw");       
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalDeposited = pool.totalDeposited.sub(_amount);
            pool.lpToken.transfer(msg.sender, _amount);
        }
        user.RewardRec = user.amount.mul(pool.accTestTokenPerShare).div(1e12);
    }
   /**
     * @notice Stake  TestTokens to MasterFork.
     * @param _amount of TestToken to Withdraw.
     */
        function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (_amount > 0) {
            pool.totalDeposited = pool.totalDeposited.add(_amount);
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.RewardRec = user.amount.mul(pool.accTestTokenPerShare).div(1e12);
    }
    /**
     * @notice UnStake TestTokens to MasterFork.
     * @param _amount of TestToken to Withdraw.
     */

       function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount,"not enought amount to withdrwaw");
        updatePool(0);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalDeposited = pool.totalDeposited.sub(_amount);
            pool.lpToken.transfer(address(msg.sender), _amount);
        }
        user.RewardRec = user.amount.mul(pool.accTestTokenPerShare).div(1e12);
    }
}