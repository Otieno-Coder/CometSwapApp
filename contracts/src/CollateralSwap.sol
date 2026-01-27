// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {FlashLoanReceiverBase} from "./FlashLoanReceiverBase.sol";
import {IComet} from "./interfaces/compound/IComet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ISwapRouter02
 * @notice Minimal interface for Uniswap V3 SwapRouter02
 * @dev SwapRouter02 doesn't use deadline in struct - it's handled via multicall
 */
interface ISwapRouter02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

/**
 * @title CollateralSwap
 * @notice Enables atomic collateral swaps on Compound V3 (Comet) using Aave flash loans
 * @dev Users can swap their collateral from one asset to another without exiting their position
 *
 * Flow:
 * 1. User initiates swap (sourceAsset -> targetAsset)
 * 2. Flash borrow targetAsset from Aave
 * 3. Supply targetAsset to Comet as collateral
 * 4. Withdraw sourceAsset from Comet
 * 5. Swap sourceAsset -> targetAsset on Uniswap
 * 6. Repay flash loan + fee
 */
contract CollateralSwap is FlashLoanReceiverBase, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Structs ============

    struct SwapParams {
        address user; // User performing the swap
        address sourceAsset; // Asset to swap FROM (withdraw from Comet)
        address targetAsset; // Asset to swap TO (supply to Comet)
        uint256 sourceAmount; // Amount of source asset to withdraw
        uint256 minTargetAmount; // Minimum target asset to receive (slippage protection)
        uint24 swapFee; // Uniswap pool fee tier
    }

    // ============ State Variables ============

    /// @notice Compound V3 (Comet) contract
    IComet public immutable comet;

    /// @notice Uniswap V3 SwapRouter02
    ISwapRouter02 public immutable swapRouter;

    /// @notice Mapping of supported collateral assets
    mapping(address => bool) public supportedCollaterals;

    /// @notice List of supported collateral addresses (for enumeration)
    address[] public collateralList;

    // ============ Events ============

    event CollateralSwapped(
        address indexed user,
        address indexed sourceAsset,
        address indexed targetAsset,
        uint256 sourceAmount,
        uint256 targetAmount,
        uint256 flashLoanFee
    );

    event CollateralAdded(address indexed asset);
    event CollateralRemoved(address indexed asset);

    // ============ Errors ============

    error UnsupportedCollateral(address asset);
    error InsufficientCollateral(address asset, uint256 required, uint256 available);
    error SlippageExceeded(uint256 expected, uint256 received);
    error UnauthorizedCaller(address expected, address actual);
    error SwapFailed();
    error ZeroAmount();
    error SameAsset();
    error NotComet();

    // ============ Constructor ============

    constructor(
        address _poolAddressesProvider,
        address _comet,
        address _swapRouter,
        address _owner
    ) FlashLoanReceiverBase(_poolAddressesProvider) Ownable(_owner) {
        comet = IComet(_comet);
        swapRouter = ISwapRouter02(_swapRouter);
    }

    // ============ External Functions ============

    /**
     * @notice Swap collateral from one asset to another
     * @param sourceAsset The collateral asset to swap FROM
     * @param targetAsset The collateral asset to swap TO
     * @param sourceAmount The amount of source collateral to swap
     * @param minTargetAmount Minimum amount of target collateral (slippage protection)
     * @param swapFee Uniswap V3 pool fee tier (500, 3000, or 10000)
     */
    function swapCollateral(
        address sourceAsset,
        address targetAsset,
        uint256 sourceAmount,
        uint256 minTargetAmount,
        uint24 swapFee
    ) external nonReentrant {
        // ============ Validations ============
        if (sourceAmount == 0) revert ZeroAmount();
        if (sourceAsset == targetAsset) revert SameAsset();
        if (!supportedCollaterals[sourceAsset]) revert UnsupportedCollateral(sourceAsset);
        if (!supportedCollaterals[targetAsset]) revert UnsupportedCollateral(targetAsset);

        // Check user has sufficient collateral
        uint128 userCollateral = comet.collateralBalanceOf(msg.sender, sourceAsset);
        if (userCollateral < sourceAmount) {
            revert InsufficientCollateral(sourceAsset, sourceAmount, userCollateral);
        }

        // Encode parameters for flash loan callback
        SwapParams memory params = SwapParams({
            user: msg.sender,
            sourceAsset: sourceAsset,
            targetAsset: targetAsset,
            sourceAmount: sourceAmount,
            minTargetAmount: minTargetAmount,
            swapFee: swapFee
        });

        // Initiate flash loan for the target asset
        // We need to flash borrow enough target asset to cover the swap
        // This is an approximation - in production, use a quoter
        _initiateFlashLoan(targetAsset, minTargetAmount, abi.encode(params));
    }

    /**
     * @notice Callback function for Aave flash loans
     * @dev Called by Aave Pool after flash loan is received
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Only the Aave Pool can call this
        if (msg.sender != address(POOL)) revert UnauthorizedCaller(address(POOL), msg.sender);
        // Only this contract can initiate
        if (initiator != address(this)) revert UnauthorizedCaller(address(this), initiator);

        // Decode swap parameters
        SwapParams memory swapParams = abi.decode(params, (SwapParams));

        // ============ Step 1: Supply target asset to Comet for user ============
        IERC20(asset).forceApprove(address(comet), amount);
        comet.supplyTo(swapParams.user, asset, amount);

        // ============ Step 2: Withdraw source asset from Comet ============
        // Note: User must have approved this contract via comet.allow()
        comet.withdrawFrom(swapParams.user, address(this), swapParams.sourceAsset, swapParams.sourceAmount);

        // ============ Step 3: Swap source -> target on Uniswap ============
        IERC20(swapParams.sourceAsset).forceApprove(address(swapRouter), swapParams.sourceAmount);

        uint256 amountOut = swapRouter.exactInputSingle(
            ISwapRouter02.ExactInputSingleParams({
                tokenIn: swapParams.sourceAsset,
                tokenOut: swapParams.targetAsset,
                fee: swapParams.swapFee,
                recipient: address(this),
                amountIn: swapParams.sourceAmount,
                // Use user-provided minimum target amount for Uniswap slippage protection.
                // Flash loan repayment is enforced separately below.
                amountOutMinimum: swapParams.minTargetAmount,
                sqrtPriceLimitX96: 0
            })
        );

        // ============ Step 4: Verify we have enough to repay ============
        uint256 amountOwed = amount + premium;
        if (amountOut < amountOwed) {
            revert SlippageExceeded(amountOwed, amountOut);
        }

        // ============ Step 5: Approve repayment and return excess to user ============
        _approveRepayment(asset, amount, premium);

        // Return any excess to user
        uint256 excess = amountOut - amountOwed;
        if (excess > 0) {
            IERC20(asset).safeTransfer(swapParams.user, excess);
        }

        emit CollateralSwapped(
            swapParams.user,
            swapParams.sourceAsset,
            swapParams.targetAsset,
            swapParams.sourceAmount,
            amount, // target amount supplied
            premium
        );

        return true;
    }

    // ============ Admin Functions ============

    /**
     * @notice Add a supported collateral asset
     * @param asset The collateral asset address
     */
    function addCollateral(address asset) external onlyOwner {
        if (!supportedCollaterals[asset]) {
            supportedCollaterals[asset] = true;
            collateralList.push(asset);
            emit CollateralAdded(asset);
        }
    }

    /**
     * @notice Remove a supported collateral asset
     * @param asset The collateral asset address
     */
    function removeCollateral(address asset) external onlyOwner {
        if (supportedCollaterals[asset]) {
            supportedCollaterals[asset] = false;
            // Remove from list (swap and pop)
            for (uint256 i = 0; i < collateralList.length; i++) {
                if (collateralList[i] == asset) {
                    collateralList[i] = collateralList[collateralList.length - 1];
                    collateralList.pop();
                    break;
                }
            }
            emit CollateralRemoved(asset);
        }
    }

    /**
     * @notice Add multiple collateral assets at once
     * @param assets Array of collateral asset addresses
     */
    function addCollaterals(address[] calldata assets) external onlyOwner {
        for (uint256 i = 0; i < assets.length; i++) {
            if (!supportedCollaterals[assets[i]]) {
                supportedCollaterals[assets[i]] = true;
                collateralList.push(assets[i]);
                emit CollateralAdded(assets[i]);
            }
        }
    }

    // ============ View Functions ============

    /**
     * @notice Get the list of supported collateral assets
     * @return Array of supported collateral addresses
     */
    function getSupportedCollaterals() external view returns (address[] memory) {
        return collateralList;
    }

    /**
     * @notice Check if an asset is supported as collateral
     * @param asset The asset address to check
     * @return True if the asset is supported
     */
    function isCollateralSupported(address asset) external view returns (bool) {
        return supportedCollaterals[asset];
    }

    /**
     * @notice Get the flash loan premium (fee) from Aave
     * @return The flash loan premium in basis points
     */
    function getFlashLoanPremium() external view returns (uint128) {
        return POOL.FLASHLOAN_PREMIUM_TOTAL();
    }

    // ============ Emergency Functions ============

    /**
     * @notice Rescue stuck tokens (emergency only)
     * @param token The token to rescue
     * @param to The recipient address
     * @param amount The amount to rescue
     */
    function rescueTokens(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}
