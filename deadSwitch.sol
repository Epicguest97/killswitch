// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DeadSwitch - Trustless Digital Inheritance
 * @notice A dead man's switch for crypto assets. If the owner stops
 *         checking in before a timeout, the nominated beneficiary can
 *         claim the locked funds. No lawyer, no bank, no trusted third
 *         party holds the money at any point - the contract enforces it.
 */
contract DeadSwitch {
    struct Will {
        address owner;
        address payable beneficiary;
        uint256 balance;
        uint256 lastCheckIn;      // timestamp of last proof-of-life
        uint256 checkInInterval;  // seconds of silence before claim opens
        bool exists;
    }

    // one will per owner address
    mapping(address => Will) public wills;

    event WillCreated(address indexed owner, address indexed beneficiary, uint256 interval, uint256 amount);
    event FundsDeposited(address indexed owner, uint256 amount);
    event ProofOfLife(address indexed owner, uint256 timestamp);
    event WillCancelled(address indexed owner, uint256 refund);
    event InheritanceClaimed(address indexed owner, address indexed beneficiary, uint256 amount);

    modifier willExists(address owner) {
        require(wills[owner].exists, "No will found for this address");
        _;
    }

    modifier onlyOwner() {
        require(wills[msg.sender].exists, "You have no will registered");
        _;
    }

    /// @notice Register a new will. Value sent is locked immediately.
    function createWill(address payable beneficiary, uint256 intervalInSeconds) external payable {
        require(!wills[msg.sender].exists, "Will already exists for this address");
        require(beneficiary != address(0), "Beneficiary cannot be the zero address");
        require(beneficiary != msg.sender, "Beneficiary must differ from owner");
        require(intervalInSeconds >= 60, "Interval must be at least 60 seconds");
        require(msg.value > 0, "Must lock some ETH when creating a will");

        wills[msg.sender] = Will({
            owner: msg.sender,
            beneficiary: beneficiary,
            balance: msg.value,
            lastCheckIn: block.timestamp,
            checkInInterval: intervalInSeconds,
            exists: true
        });

        emit WillCreated(msg.sender, beneficiary, intervalInSeconds, msg.value);
    }

    /// @notice Lock additional ETH into an existing will.
    function deposit() external payable onlyOwner {
        require(msg.value > 0, "Deposit must be greater than 0");
        wills[msg.sender].balance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Owner signals they are alive. Resets the claim timer.
    function checkIn() external onlyOwner {
        wills[msg.sender].lastCheckIn = block.timestamp;
        emit ProofOfLife(msg.sender, block.timestamp);
    }

    /// @notice Owner cancels the will and reclaims everything (while alive).
    function cancelWill() external onlyOwner {
        Will storage w = wills[msg.sender];
        uint256 refund = w.balance;
        w.balance = 0;
        w.exists = false;
        (bool sent, ) = msg.sender.call{value: refund}("");
        require(sent, "ETH refund failed");
        emit WillCancelled(msg.sender, refund);
    }

    /// @notice Beneficiary claims funds after the owner has gone silent.
    /// @param owner The (inactive) owner's address whose will is being claimed.
    function claimInheritance(address owner) external willExists(owner) {
        Will storage w = wills[owner];
        require(msg.sender == w.beneficiary, "Only the nominated beneficiary can claim");
        require(
            block.timestamp >= w.lastCheckIn + w.checkInInterval,
            "Owner is still active - claim window not open yet"
        );

        uint256 payout = w.balance;
        w.balance = 0;
        w.exists = false;

        (bool sent, ) = w.beneficiary.call{value: payout}("");
        require(sent, "ETH payout failed");

        emit InheritanceClaimed(owner, w.beneficiary, payout);
    }

    /// @notice Read-only helper: how many seconds until the claim window opens.
    function timeUntilClaimable(address owner) external view willExists(owner) returns (uint256) {
        Will storage w = wills[owner];
        uint256 deadline = w.lastCheckIn + w.checkInInterval;
        if (block.timestamp >= deadline) return 0;
        return deadline - block.timestamp;
    }
}
