pragma solidity ^0.5.6;

contract Blocklock {
    
    address creator;
    bool status;
    bytes32 lockId;
    
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
    
    event statusChanged(uint256 block);//non metto altre info come l'address di chi ha aperto la porta per non lasciare troppe info 
    event blocklockCreated(uint256 block);
    event userAdded(uint256 block);
    event userUpgraded(uint256 block);
    event userDeleted(uint256 block);
    
    constructor(string memory _lockId/*, address _creator*/) public{
        //creator = _creator;
        creator = msg.sender;
        lockId = stringToBytes(_lockId);
        emit blocklockCreated(block.number);
        isRoot[creator] = 2;
    }
    
    function changeDoorStatus() isUser(msg.sender) public{
        status = !status;
        emit statusChanged(block.number);
    }
    
    function addUser(address _newUSer) onlyRoot(msg.sender) public{
        isRoot[_newUSer] = 1;
        emit userAdded(block.number);
    }
    
    function addTimeUser(address _newUSer, uint256 _duration) onlyRoot(msg.sender) public{
        isRoot[_newUSer] = block.number + _duration;
        emit userAdded(block.number);
    }
    
    function upgradeUser(address _stdUser) onlyRoot(msg.sender) public{
        isRoot[_stdUser] = 2;
        emit userUpgraded(block.number);
    }
    
    /**
     * a differenza della precedente versione il creator ha i poteri supremi :)
     * può eliminare chiunque
     * (da ragionarci)
     * Se questa funzione la lasciamo così non serve nemmeno la resetDoor, perchè l'unico che ha il permesso di resettarla
     * è il creator, quindi tanto vale che chiude il contratto e lo rideploya(meno costoso)
     * In alternativa tenere traccia degli utenti su array poi elminare tutti gli address del map scorrendo l'array
     */
    function deleteUser(address _usr) onlyRoot(msg.sender) public{//non vera la cosa del creator i root eliminano i root
    //TODO cambiare tutto
        if(isRoot[_usr] == 1){
           isRoot[_usr] = 0; 
            emit userDeleted(block.number);
        }else if(isRoot[_usr] == 2){
            require(msg.sender == creator);
            isRoot[_usr] = 0; 
            emit userDeleted(block.number);
        }
    }
    
    function getDoorStatus() public view returns(bool){
        return status;
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