pragma solidity ^0.5.6;

import "./BlocklockAggregator.sol";

contract Blocklock {
    
    address creator;
    bool status;
    bytes32 lockId;
    BlocklockAggregator aggregator;
    address[] users;
    address[] temp;
    
    /**
     * 0 is not user 
     * 1 is user
     * 2 is root 
     * se maggiore di 2 allora que valore è il limite temporale oltre il quale non potrà rientrare
     */
    mapping (address => uint256) isRoot;

    modifier isUser(address _usr){
        require(isRoot[_usr] == 1 || isRoot[_usr] == 2 || isRoot[_usr] >= block.number);
        _;
    }
    
    modifier onlyRoot(address _usr){
        require(isRoot[_usr] == 2);
        _;
    }
    
    modifier onlyCreator(address _usr){
        require(_usr == creator);
        _;
    }
    
    event statusChanged(uint256 block, address blocklockAddress, address user); 
    event blocklockCreated(uint256 block, address blocklockAddress, address user);
    event userAdded(uint256 block, address blocklockAddress, address fromUser, address to);
    event userUpgraded(uint256 block, address blocklockAddress, address fromUser, address to);
    event userDeleted(uint256 block, address blocklockAddress, address fromUser, address to);
    
    constructor(string memory _lockId, address _aggregator) public{
        creator = msg.sender;
        aggregator = BlocklockAggregator(_aggregator);
        lockId = stringToBytes(_lockId);
        emit blocklockCreated(block.number, address(this), address(creator));
        isRoot[creator] = 2;
        users.push(creator);
        aggregator.addBlocklock(address(this), creator);
    }
    
    function changeDoorStatus() isUser(msg.sender) public{
        status = !status;
        emit statusChanged(block.number, address(this), msg.sender);
    }
    
    function addUser(address _newUSer) onlyRoot(msg.sender) public{
        isRoot[_newUSer] = 1;
        emit userAdded(block.number, address(this), msg.sender, _newUSer);
        users.push(_newUSer);
    }
    
    function addTimeUser(address _newUSer, uint256 _duration) onlyRoot(msg.sender) public{
        isRoot[_newUSer] = block.number + _duration;
        emit userAdded(block.number, address(this), msg.sender, _newUSer);
        users.push(_newUSer);
        aggregator.addUser(address(this), _newUSer); //questo è da gestire, perchè quando è scaduto il tempo andrebbe eliminato dall'aggregator
    }
    
    function upgradeUser(address _stdUser) onlyRoot(msg.sender) public{
        isRoot[_stdUser] = 2;
        emit userUpgraded(block.number, address(this), msg.sender, _stdUser);
    }
    
    function deleteUser(address _usr) onlyRoot(msg.sender) public{
        isRoot[_usr] = 0;
        emit userDeleted(block.number, address(this), msg.sender, _usr);
        aggregator.deleteUser(address(this), _usr);
    }
    
    function resetLock() public onlyRoot(msg.sender){
        aggregator.resetBlocklock(address(this), msg.sender, lockId);
    }
    
    function getDoorStatus() public view returns(bool){
        return status;
    }
    
    function getUser() public view returns(address[] memory){
        address[] memory res;
        uint count;
        for(uint i = 0; i < users.length; i++){
            if(isRoot[users[i]] == 1 || isRoot[users[i]] == 2){
                res[count] = users[i];
            }
        }
        return res;
    }
    
    function stringToBytes(string memory _s) private pure returns (bytes32){
        bytes32 result;
        assembly {
            result := mload(add(_s, 32))
        }
        return result;
    }

    function bytesToString(bytes32 _bytes32) private pure returns (string memory){
        string memory result;
        assembly {
        let val := mload(0x40)
        mstore(val, 0x20)
        mstore(add(val, 0x20), _bytes32)
        mstore(0x40, add(val, 0x40))
        result := val
        }
        return result;
    }
    
    function closeContract() onlyCreator(msg.sender) public{
        selfdestruct(address(0));
    }
    
}