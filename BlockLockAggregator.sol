pragma solidity ^0.5.6;

import "./Blocklock.sol";

contract BlocklockAggregator {

    address creator;
    
    uint256 globalCounter;

    Blocklock blockL;
    
    //address[] blocklockList;
    
    //mapping (address => bytes32) addressToId;
    mapping(address => address[]) doorsUser;
    mapping(address => address[]) userToDoors;
    
    modifier onlyCreator(address _usr){
        require(_usr == creator);
        _;
    }

    constructor() public{
        creator = msg.sender;
    }

    function addBlocklock(address _blocklockAddress, address _usr) public{
        //addressToId[_blocklockAddress] = _blocklockId;
        //blocklockList.push(_blocklockAddress);
        doorsUser[_blocklockAddress].push(_usr);
        userToDoors[_usr].push(_blocklockAddress);
        globalCounter += 1;
    }

    function addUser(address _blocklockAddress, address _usr) public{
        doorsUser[_blocklockAddress].push(_usr);
        userToDoors[_usr].push(_blocklockAddress);
    }

    function deleteUser(address _blocklockAddress, address _usr) public{
        for(uint i = 0; i < doorsUser[_blocklockAddress].length; i++){
            if(doorsUser[_blocklockAddress][i] == _usr){
                delete doorsUser[_blocklockAddress][i];
                break;
            }
        }

        for(uint i = 0; i < userToDoors[_usr].length; i++){
            if(userToDoors[_usr][i] == _blocklockAddress){
                delete userToDoors[_usr][i];
                break;
            }
        }
    }

    function resetBlocklock(address _blocklockAddress, address _usr, bytes32 lockId) public{
        for(uint i = 0; i < userToDoors[_usr].length; i++){
            if(userToDoors[_usr][i] == _blocklockAddress){
                delete userToDoors[_usr][i];
                break;
            }
        }

        Blocklock bl = new Blocklock(bytesToString(lockId));
        doorsUser[_usr].push(address(bl));
        userToDoors[address(bl)].push(_usr);
        
    }
    
    //Non mi serve il delete, ogni volta che resetto blocklock il vecchio addres non controlla più il dispositivo
    /*function deleteBlocklock(address _blocklockAddress, bytes32 _blocklockId) public{
        //addressToId[_blocklockAddress] = 0;
        globalCounter -= 1;
    }*/

    function bytesToString (bytes32 _bytes32) private pure returns (string memory){
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
    
    function closeContract() public onlyCreator(msg.sender){
        selfdestruct(address(0));
    }

}
