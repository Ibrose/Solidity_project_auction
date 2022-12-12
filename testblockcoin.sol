// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


contract Pok8Coin  {
    // static
    address public owner;
    uint public bidIncrement;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
    uint public heat;//heat of auction
    uint public randheat;
    uint public pok8heat;//heat which auction explodes
    bool public doctor;//halves heat
    uint public bullet;//increases heat, up to 2
    uint public randNonce;

    // state
    bool public canceled;
    uint public highestBindingBid;
    address public highestBidder;
    mapping(address => uint256) public fundsByBidder;
    bool ownerHasWithdrawn;
    bool public exploded;
    
    

    event explosion();
    event LogBid(address bidder, uint bid, address highestBidder, uint highestBid, uint highestBindingBid);
    event LogWithdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event LogCanceled();

    function mainAuction(address _owner, uint _bidIncrement, uint _startBlock, uint _endBlock, string memory _ipfsHash, uint maxauctheat) public{
        if (_startBlock >= _endBlock) revert();
        if (_startBlock < block.number) revert();
        if (_owner == address(0)) revert();
        if (maxauctheat <= 0) revert();

        owner = _owner;
        bidIncrement = _bidIncrement;
        startBlock = _startBlock;
        endBlock = _endBlock;
        ipfsHash = _ipfsHash;
        pok8heat = maxauctheat;
        heat = 0;
        doctor = true;
        bullet = 2;
        randNonce = 0;
    }
   

    function getHighestBid() external view returns (uint)
    {
        return fundsByBidder[highestBidder];
    }
    function getDoctor() external view returns (bool)
    {
        return doctor;
    }
    function getBullet() external view returns (uint)
    {
        return bullet;
    }
    function getHeat() external view returns (uint)
    {
        return heat;
    }
    function getPok8Heat() external view returns (uint)
    {
        require (msg.sender == owner);
        return pok8heat;
    }

    function placeBid() external payable 
        onlyAfterStart
        onlyBeforeEnd
        onlyNotCanceled
        onlyNotOwner
        onlyNotExploded
        returns (bool success) //돈 보내는 함수
    {
        // reject payments of 0 ETH
        if (msg.value == 0) revert();

        uint newBid = fundsByBidder[msg.sender] + msg.value;
        if (newBid <= highestBindingBid) revert();

        
        uint highestBid = fundsByBidder[highestBidder];

        fundsByBidder[msg.sender] = newBid;

        if (newBid <= highestBid) {
            // if the user has overbid the highestBindingBid but not the highestBid, we simply
            // increase the highestBindingBid and leave highestBidder alone.

            // note that this case is impossible if msg.sender == highestBidder because you can never
            // bid less ETH than you've already bid.

            highestBindingBid = min(newBid + bidIncrement, highestBid);
        } else {
            // if msg.sender is already the highest bidder, they must simply be wanting to raise
            // their maximum bid, in which case we shouldn't increase the highestBindingBid.

            // if the user is NOT highestBidder, and has overbid highestBid completely, we set them
            // as the new highestBidder and recalculate highestBindingBid.

            if (msg.sender != highestBidder) {
                highestBidder = msg.sender;
                highestBindingBid = min(newBid, highestBid + bidIncrement);
                randheat = uint(keccak256(abi.encodePacked(block.timestamp))) % uint(100);
                randheat = min(randheat, max(newBid, highestBid + bidIncrement) - min(newBid, highestBid + bidIncrement));
                heat = heat + randheat;
            }
            highestBid = newBid;
        }
        if (heat >= pok8heat){
            exploded = true;
            explosion;
        }

        emit LogBid(msg.sender, newBid, highestBidder, highestBid, highestBindingBid);
        return true;
    }

    function min(uint a, uint b)
        private
        pure
        returns (uint)
    {
        if (a < b) return a;
        return b;
    }
    function max(uint a, uint b)
        private
        pure
        returns (uint)
    {
        if (a > b) return a;
        return b;
    }

    function doctorheal() public 
    onlyNotCanceled
    onlyNotExploded
    returns (bool success){
        if (doctor == false) revert();
        
        heat = heat/2;
        doctor = false;
        return true;
    }
    function bulletshot() public 
    onlyNotCanceled
    onlyNotExploded
    returns (bool success){
        if (bullet <= 0) revert();
        bullet = bullet - 1;
        heat = heat + 100;
        if (heat >= pok8heat) exploded = true; emit explosion();
        return true;
    }

    function cancelAuction() public
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
        onlyNotExploded
        returns (bool success)
    {
        canceled = true;
        emit LogCanceled();
        return true;
    }
    function explodedAuction() public
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
        onlyNotExploded
        returns (bool success)
    {
        exploded = true;
        emit LogCanceled();
        return true;
    }

    function withdraw() public
        onlyEndedOrCanceled
        returns (bool success)
    {
        address withdrawalAccount;
        uint withdrawalAmount;

        if (canceled) {
            // if the auction was canceled, everyone should simply be allowed to withdraw their funds
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[withdrawalAccount];

        } 
        else if (exploded){
            if (msg.sender == owner) {
                // the auction's owner should be allowed to withdraw the highestBindingBid
                withdrawalAccount = highestBidder;
                withdrawalAmount = highestBindingBid + min(heat, pok8heat);
                ownerHasWithdrawn = true;

            } else if (msg.sender == highestBidder) {
                // the highest bidder should only be allowed to withdraw the difference between their
                // highest bid and the highestBindingBid
                withdrawalAccount = highestBidder;
                if (ownerHasWithdrawn) {
                    withdrawalAmount = fundsByBidder[highestBidder];
                } else {
                    withdrawalAmount = fundsByBidder[highestBidder] - highestBindingBid;

                }

        }
        else {
            // the auction finished without being canceled

            if (msg.sender == owner) {
                // the auction's owner should be allowed to withdraw the highestBindingBid
                withdrawalAccount = highestBidder;
                withdrawalAmount = highestBindingBid;
                ownerHasWithdrawn = true;

            } else if (msg.sender == highestBidder) {
                // the highest bidder should only be allowed to withdraw the difference between their
                // highest bid and the highestBindingBid
                withdrawalAccount = highestBidder;
                if (ownerHasWithdrawn) {
                    withdrawalAmount = fundsByBidder[highestBidder];
                } else {
                    withdrawalAmount = fundsByBidder[highestBidder] - highestBindingBid;
                }

            } else {
                // anyone who participated but did not win the auction should be allowed to withdraw
                // the full amount of their funds
                withdrawalAccount = msg.sender;
                withdrawalAmount = fundsByBidder[withdrawalAccount];
            }
        }

        if (withdrawalAmount == 0) revert();

        fundsByBidder[withdrawalAccount] -= withdrawalAmount;

        // send the funds
        
        require(msg.sender == withdrawalAccount);
        

        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);

        return true;
    }
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    modifier onlyNotOwner {
        if (msg.sender == owner) revert();
        _;
    }

    modifier onlyAfterStart {
        if (block.number < startBlock) revert();
        _;
    }

    modifier onlyBeforeEnd {
        if (block.number > endBlock) revert();
        _;
    }

    modifier onlyNotCanceled {
        if (canceled) revert();
        _;
    }

    modifier onlyEndedOrCanceled {
        if (block.number < endBlock && !canceled && !exploded) revert();
        _;
    }

    modifier onlyNotExploded{
        if (exploded) revert();
        _;
    }

    modifier doctorDone{
        if (doctor == false) revert();
        _;
    }

    modifier bulletUsed{
        if (bullet == 0) revert();
        _;
    }
   
}

