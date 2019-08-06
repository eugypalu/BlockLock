pragma solidity ^0.5.6;

import "./Blocklock.sol";

//----------------------Il contratto non deve essere mai chiuso, Non implementare la closecontract---------------------

contract BlocklockAggregator {

    address creator; //potrebbe non servire
    
    //tiene traccia del numero di blocklock create. Necessario perchè non tiene in considerazione i reset
    uint256 globalCounter;

    //istanza di blocklock
    Blocklock blockL;
    
    /**
     * Info sulla porta
     * isActive ci dice se la porta è ancora attiva o meno
     * userList è la lista di utenti di una certa porta
     **/
    struct doorInfo{
        bool isActive;
        address doorAddress;
    }

    /**
     * utenti relativi ad una porta
     * primo parametro è la porta, il seconondo è l'array di utenti
     **/
    //mapping(address => address[]) doorsUser;
    //Posso prenderlo già da blocklock 

    /**
     * Porte relative ad un singolo utente
     * primo parametro è l'address dell'utente, il seconondo è l'array di porte (identificate da struct)
     **/
    mapping(address => doorInfo[]) userToDoors;
    
    event blockLockAdded(uint256 block, address blocklockAddress, address creator);

    constructor() public{
        creator = msg.sender;
    }

    /**
     * Aggiunge una nuova Blocklock
     **/
    function addBlocklock(address _blocklockAddress, address _usr) public{
        //doorsUser[_blocklockAddress].push(_usr); //Aggiunge il creator come utente della porta
        userToDoors[_usr].push(doorInfo(true, _blocklockAddress));
        globalCounter += 1;
        emit blockLockAdded(block.number, _blocklockAddress, _usr);
    }

    function addUser(address _blocklockAddress, address _usr) public{
        //doorsUser[_blocklockAddress].push(_usr);
        userToDoors[_usr].push(doorInfo(true, _blocklockAddress));
    }

    function deleteUser(address _blocklockAddress, address _usr) public{
        /*for(uint i = 0; i < doorsUser[_blocklockAddress].length; i++){
            if(doorsUser[_blocklockAddress][i] == _usr){
                delete doorsUser[_blocklockAddress][i];
                break;
            }
        }*/

        for(uint i = 0; i < userToDoors[_usr].length; i++){
            if(userToDoors[_usr][i].doorAddress == _blocklockAddress){
                delete userToDoors[_usr][i];
                break;
            }
        }
    }

    function resetBlocklock(address _blocklockAddress, address _usr, bytes32 lockId) public{
        for(uint i = 0; i < userToDoors[_usr].length; i++){
            if(userToDoors[_usr][i].doorAddress == _blocklockAddress){
                userToDoors[_usr][i].isActive = false;
                break;
            }
        }
        
        Blocklock bl = new Blocklock(bytesToString(lockId), address(this));
        //doorsUser[_usr].push(address(bl));
        userToDoors[_usr].push(doorInfo(true, address(bl)));
    }
    
    function getCounter() public view returns(uint256){
        return globalCounter;
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

}
