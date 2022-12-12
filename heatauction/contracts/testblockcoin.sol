// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


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
    uint public ownerBid;//used when cancelled
    bool public doctor;//halves heat
    uint public bullet;//increases heat, up to 2
    //uint public randNonce;

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
//uint initialbid,
    function mainAuction(address _owner, uint _bidIncrement, uint _endBlock, uint initialBid,
    string memory _ipfsHash, uint maxauctheat) public payable{
        if (_owner == address(0)) revert();
        if (maxauctheat <= 0) revert();

        owner = _owner;
        bidIncrement = _bidIncrement;
        startBlock = 0;
        endBlock = _endBlock;
        ipfsHash = _ipfsHash;
        pok8heat = maxauctheat;
        heat = 0;
        highestBidder = _owner;
        fundsByBidder[highestBidder] = initialBid;
        ownerBid = initialBid;
        //fundsByBidder[highestBidder] = msg.value;
        doctor = true;
        bullet = 2;
        
    }
    //if (_startBlock >= _endBlock) revert();
    //if (_startBlock < block.number) revert();
    //randNonce = 0;
    /*receive() external payable{

    }
    fallback() external payable {}*/

    function getHighestBid() external view returns (uint)
    {
        return fundsByBidder[highestBidder];
    }
    /*function getDoctor() external view returns (bool)
    {
        return doctor;
    }
    function getBullet() external view returns (uint)
    {
        return bullet;
    }*/
    function getHeat() external view returns (uint)
    {
        return heat;
    }
    function getPok8Heat() external view returns (uint)
    {
        require (msg.sender == owner);
        return pok8heat;
    }
//uint money
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
            highestBindingBid = min(newBid + bidIncrement, highestBid);
        } else {
            if (msg.sender != highestBidder && msg.sender != owner) {
                highestBidder = msg.sender;
                highestBindingBid = min(newBid, highestBid + bidIncrement);
                randheat = uint(keccak256(abi.encodePacked(block.timestamp))) % uint(100);
                randheat = max(randheat, max(newBid, highestBid + bidIncrement) - min(newBid, highestBid + bidIncrement));
                heat = heat + randheat;
            }
            highestBid = newBid;
        }
        //ownerBid = fundsByBidder[owner];
        fundsByBidder[owner] = highestBindingBid;
        if (heat >= pok8heat){
            fundsByBidder[owner] += ((fundsByBidder[highestBidder] - highestBindingBid)/2);
            exploded = true;
            explosion;
        }

        emit LogBid(msg.sender, newBid, highestBidder, highestBid, highestBindingBid);
        return true;
    }
        // if the user has overbid the highestBindingBid but not the highestBid, we simply
        // increase the highestBindingBid and leave highestBidder alone.

        // note that this case is impossible if msg.sender == highestBidder because you can never
        // bid less ETH than you've already bid.
        // if msg.sender is already the highest bidder, they must simply be wanting to raise
        // their maximum bid, in which case we shouldn't increase the highestBindingBid.

        // if the user is NOT highestBidder, and has overbid highestBid completely, we set them
        // as the new highestBidder and recalculate highestBindingBid.
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

    /*function doctorheal() public 
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
    }*/

    function cancelAuction() public
        onlyOwner
        onlyBeforeEnd
        onlyNotCanceled
        onlyNotExploded
        returns (bool success)
    {
        fundsByBidder[owner] = ownerBid;
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

    function withdraw() public payable
        onlyEndedOrCanceledOrExploded
        returns (bool success)
    {
        address withdrawalAccount;
        uint withdrawalAmount;

        if (canceled) {
            withdrawalAccount = msg.sender;
            withdrawalAmount = fundsByBidder[msg.sender];

        } 
        else if (exploded){
            if (msg.sender == owner) {
                withdrawalAccount = msg.sender;
                withdrawalAmount = fundsByBidder[withdrawalAccount];
                ownerHasWithdrawn = true;

            } else if (msg.sender == highestBidder) {
                withdrawalAccount = highestBidder;
                withdrawalAmount = ((fundsByBidder[highestBidder] - highestBindingBid)/2) + (heat-pok8heat);
                heat -= pok8heat;
            }
            else {
                withdrawalAccount = msg.sender;
                withdrawalAmount = fundsByBidder[withdrawalAccount];
            }
        }
                /*if (ownerHasWithdrawn) {
                    withdrawalAmount = fundsByBidder[highestBidder];
                } else {
                    withdrawalAmount = ((fundsByBidder[highestBidder] - highestBindingBid)/2) + heatSend;
                }*/
                /*if (ownerHasWithdrawn) {
                    withdrawalAmount = fundsByBidder[highestBidder];
                } else {
                    withdrawalAmount = fundsByBidder[highestBidder] - highestBindingBid;
                }*/
        else{
            if (msg.sender == owner) {
                withdrawalAccount = msg.sender;
                withdrawalAmount = highestBindingBid;
                ownerHasWithdrawn = true;

            } else if (msg.sender == highestBidder) {
                withdrawalAccount = highestBidder;
                withdrawalAmount = fundsByBidder[highestBidder] - highestBindingBid;
            } else {
                withdrawalAccount = msg.sender;
                withdrawalAmount = fundsByBidder[withdrawalAccount];
            }
        }

        if (withdrawalAmount == 0) revert("Poor");

        fundsByBidder[withdrawalAccount] -= withdrawalAmount;
        require(msg.sender == withdrawalAccount, "Who are you??");
        
        
        (bool sent,) = payable(msg.sender).call{value: withdrawalAmount}("") ;
        require(sent, "Transfer failed");
        //require(payable(msg.sender).send(withdrawalAmount) == true, "Error??");
        //if(!payable(msg.sender).send(withdrawalAmount)) revert("money different!");
        //payable(msg.sender).transfer(withdrawalAmount);
        emit LogWithdrawal(msg.sender, withdrawalAccount, withdrawalAmount);
        return true;
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

    modifier onlyEndedOrCanceledOrExploded {
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

