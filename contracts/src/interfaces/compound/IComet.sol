// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IComet
 * @notice Interface for Compound V3 (Comet) protocol
 * @dev This interface covers the main functions needed for collateral management
 */
interface IComet {
    // ============ Structs ============

    struct AssetInfo {
        uint8 offset;
        address asset;
        address priceFeed;
        uint64 scale;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
        uint16 assetsIn;
    }

    struct UserCollateral {
        uint128 balance;
        uint128 _reserved;
    }

    // ============ Supply/Withdraw Functions ============

    /**
     * @notice Supply an amount of asset to the protocol
     * @param asset The asset to supply
     * @param amount The amount to supply
     */
    function supply(address asset, uint256 amount) external;

    /**
     * @notice Supply an amount of asset on behalf of another address
     * @param dst The address to supply on behalf of
     * @param asset The asset to supply
     * @param amount The amount to supply
     */
    function supplyTo(address dst, address asset, uint256 amount) external;

    /**
     * @notice Supply an amount of asset from a source address to a destination address
     * @param from The address to supply from
     * @param dst The address to supply to
     * @param asset The asset to supply
     * @param amount The amount to supply
     */
    function supplyFrom(address from, address dst, address asset, uint256 amount) external;

    /**
     * @notice Withdraw an amount of asset from the protocol
     * @param asset The asset to withdraw
     * @param amount The amount to withdraw
     */
    function withdraw(address asset, uint256 amount) external;

    /**
     * @notice Withdraw an amount of asset to a destination address
     * @param to The address to withdraw to
     * @param asset The asset to withdraw
     * @param amount The amount to withdraw
     */
    function withdrawTo(address to, address asset, uint256 amount) external;

    /**
     * @notice Withdraw an amount of asset from a source address to a destination address
     * @param src The address to withdraw from
     * @param to The address to withdraw to
     * @param asset The asset to withdraw
     * @param amount The amount to withdraw
     */
    function withdrawFrom(address src, address to, address asset, uint256 amount) external;

    // ============ Borrow/Repay Functions ============

    /**
     * @notice Borrow an amount of the base asset
     * @param amount The amount to borrow
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Repay an amount of the base asset
     * @param amount The amount to repay
     */
    function supply(uint256 amount) external;

    // ============ View Functions ============

    /**
     * @notice Get the balance of collateral for an account
     * @param account The account to check
     * @param asset The collateral asset
     * @return The collateral balance
     */
    function collateralBalanceOf(address account, address asset) external view returns (uint128);

    /**
     * @notice Get the borrow balance of an account
     * @param account The account to check
     * @return The borrow balance
     */
    function borrowBalanceOf(address account) external view returns (uint256);

    /**
     * @notice Get the base token balance (supply balance) of an account
     * @param account The account to check
     * @return The base token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Check if an account is liquidatable
     * @param account The account to check
     * @return True if the account is liquidatable
     */
    function isLiquidatable(address account) external view returns (bool);

    /**
     * @notice Check if an account has positive borrow balance
     * @param account The account to check
     * @return True if the account is borrowing
     */
    function isBorrowCollateralized(address account) external view returns (bool);

    /**
     * @notice Get the number of supported assets
     * @return The number of assets
     */
    function numAssets() external view returns (uint8);

    /**
     * @notice Get asset info by index
     * @param i The asset index
     * @return The asset info
     */
    function getAssetInfo(uint8 i) external view returns (AssetInfo memory);

    /**
     * @notice Get asset info by address
     * @param asset The asset address
     * @return The asset info
     */
    function getAssetInfoByAddress(address asset) external view returns (AssetInfo memory);

    /**
     * @notice Get the base asset address
     * @return The base asset address
     */
    function baseToken() external view returns (address);

    /**
     * @notice Get the base asset scale
     * @return The base asset scale
     */
    function baseScale() external view returns (uint256);

    /**
     * @notice Get the price feed address for the base asset
     * @return The price feed address
     */
    function baseTokenPriceFeed() external view returns (address);

    /**
     * @notice Get the price of an asset from its price feed
     * @param priceFeed The price feed address
     * @return The price (scaled)
     */
    function getPrice(address priceFeed) external view returns (uint256);

    /**
     * @notice Get user's basic info
     * @param account The account address
     * @return The user basic struct
     */
    function userBasic(address account) external view returns (UserBasic memory);

    /**
     * @notice Get user's collateral info for an asset
     * @param account The account address
     * @param asset The asset address
     * @return The user collateral struct
     */
    function userCollateral(address account, address asset) external view returns (UserCollateral memory);

    // ============ Authorization Functions ============

    /**
     * @notice Allow or disallow another address to withdraw or transfer on behalf of the owner
     * @param manager The address to allow/disallow
     * @param isAllowed True to allow, false to disallow
     */
    function allow(address manager, bool isAllowed) external;

    /**
     * @notice Check if a manager is allowed to act on behalf of an owner
     * @param owner The owner address
     * @param manager The manager address
     * @return True if allowed
     */
    function isAllowed(address owner, address manager) external view returns (bool);

    // ============ Protocol Info ============

    /**
     * @notice Get the Comet version
     * @return The version string
     */
    function version() external view returns (string memory);
}
