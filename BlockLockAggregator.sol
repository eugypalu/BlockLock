pragma solidity ^0.5.6;

contract BlocklockAggregator {

    address creator;
    
    uint256 globalCounter;
    
    //address[] blocklockList;
    
    //mapping (address => bytes32) addressToId;
    
    modifier onlyCreator(address _usr){
        require(_usr == creator);
        _;
    }
        
    constructor() public{
        creator = msg.sender;
    }
    
    function addBlocklock(address _blocklockAddress, bytes32 _blocklockId) public{
        //addressToId[_blocklockAddress] = _blocklockId;
        //blocklockList.push(_blocklockAddress);
        globalCounter += 1;
    }
    
    function deleteBlocklock(address _blocklockAddress, bytes32 _blocklockId) public{
        //addressToId[_blocklockAddress] = 0;
        globalCounter -= 1;
    }
    
    function closeContract() onlyCreator(msg.sender) public{
        selfdestruct(address(0));
    }

}
