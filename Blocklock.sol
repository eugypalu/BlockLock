pragma solidity ^0.5.6;

import "./BlocklockAggregator.sol";

contract Blocklock {
    
    address creator;
    bool status; //stato della porta
    bytes32 lockId; //id della porta
    BlocklockAggregator aggregator; 
    address[] users; //lista di utenti, serve solo per far restituire gli utenti della porta senza scorrere la map

    /**
     * informazioni relative alla finestra temporale
     * inizio e fine espressa in blocchi
     **/
    struct timeAccess{
        uint256 start;
        uint256 end;
    }
    
    /**
     * mappa gli utenti con la loro tipologia:
     * 0 is not user 
     * 1 is user
     * 2 is root 
     * 3 is temp user, la validità della data viene comtrollata dal modifier isUser con la funzione isValidTemp
     **/
    mapping (address => uint256) isRoot;
    
    /**
     * mappa gli utenti con le relative informazioni sulla finestra temporale
     **/
    mapping (address => timeAccess[]) tempUser;

    /**
     * Controlla che l'utente abbia i permessi
     * chiama la funzione isValidTemp per verificare che l'utente temporaneo abbia ancora i permessi
     **/
    modifier isUser(address _usr){
        require(isRoot[_usr] == 1 || isRoot[_usr] == 2 || isRoot[_usr] == 3 && isValidTemp(_usr));
        _;
    }
    
    /**
     * Controlla che l'utente abbia i permessi di root
     **/
    modifier onlyRoot(address _usr){
        require(isRoot[_usr] == 2);
        _;
    }
    
    /**
     * Controlla che l'utente sia colui che ha creato il contratto, quindi istanziato blocklock
     **/
    modifier onlyCreator(address _usr){
        require(_usr == creator);
        _;
    }
    
    //Eventi
    event statusChanged(uint256 block, address blocklockAddress, address user); 
    event blocklockCreated(uint256 block, address blocklockAddress, address user);
    event userAdded(uint256 block, address blocklockAddress, address fromUser, address to);
    event userUpgraded(uint256 block, address blocklockAddress, address fromUser, address to);
    event userDeleted(uint256 block, address blocklockAddress, address fromUser, address to);
    
    constructor(string memory _lockId, address _aggregator) public{
        creator = msg.sender; //setta il creator
        aggregator = BlocklockAggregator(_aggregator); //setta l'address dell'aggregator
        lockId = stringToBytes(_lockId); //trasforma la stringa in bytes per risparmiare spazio e setta l'id di blocklock 
        emit blocklockCreated(block.number, address(this), address(creator));
        isRoot[creator] = 2; //setta il creator a utente root
        users.push(creator);//aggiunge il creator alla lista di utenti
        aggregator.addBlocklock(address(this), creator); //aggiunge blocklock all'aggregator
    }
    
    /**
     * Cambia lo stato della porta solo se l'utente ha i permessi di accesso
     **/
    function changeDoorStatus() isUser(msg.sender) public{
        status = !status;
        emit statusChanged(block.number, address(this), msg.sender);
    }
    
    /**
     * Garantisce i permessi di accesso base ad un nuovo utente
     **/
    function addUser(address _newUSer) onlyRoot(msg.sender) public{
        isRoot[_newUSer] = 1; //permessi base al nuovo utente
        emit userAdded(block.number, address(this), msg.sender, _newUSer);
        users.push(_newUSer); //aggiungo l'utente alla lista
    }
    
    /**
     * Garantisce i permessi di accesso base ad un nuovo utente solo per una certa finestra temporale
     * richiede i permessi di root per effettuare l'add
     **/
    function addTimeUser(address _newUSer, uint256 _duration, uint256 _startBlock) onlyRoot(msg.sender) public{
        isRoot[_newUSer] = 3; //permessi temporanei all'utente
        tempUser[_newUSer].push(timeAccess(_startBlock, _startBlock + _duration));
        emit userAdded(block.number, address(this), msg.sender, _newUSer);
        users.push(_newUSer); //aggiungo l'utente alla lista
        aggregator.addUser(address(this), _newUSer); //questo è da gestire, perchè quando è scaduto il tempo andrebbe eliminato dall'aggregator
    }
    
    /**
     * aggiorna i permessi di un utente da base a root
     * richiede i permessi di root per effettuare l'upgrade
     **/
    function upgradeUser(address _stdUser) onlyRoot(msg.sender) public{
        isRoot[_stdUser] = 2; //setto l'utente a root
        emit userUpgraded(block.number, address(this), msg.sender, _stdUser);
    }
    
    /**
     * toglie i permessi di accesso ad un utente base o root
     * richiede i permessi di root
     **/
    function deleteUser(address _usr) onlyRoot(msg.sender) public{
        isRoot[_usr] = 0; //tolgo ogni tipo di permesso all'utente
        emit userDeleted(block.number, address(this), msg.sender, _usr);
        aggregator.deleteUser(address(this), _usr); //lo elimino anche dall'aggregator in modo che non gli compaia più la porta
    }
    
    /**
     * Resetta la smart lock, il contratto attuale viene chiuso, viene eliminata la porta assegnata agli utenti nell'aggregator 
     * e viene creato un nuovo contratto. il nuovo contratto non incrementa il counter dei contratti creati
     **/
    function resetLock() public onlyRoot(msg.sender){
        aggregator.resetBlocklock(address(this), msg.sender, lockId); //l'aggregator crea un nuovo contrattto
        closeContract(); //chiudo il contratto
    }
    
    /**
     * restituisce lo stato della porta
     **/
    function getDoorStatus() public view returns(bool){
        return status;
    }
    
    /**
     * restituisce gli utenti associati alla porta
     **/
    function getUser() public view returns(address[] memory){
        address[] memory res;
        uint count;
        //aggiungo utenti bae e root
        for(uint i = 0; i < users.length; i++){
            if(isRoot[users[i]] == 1 || isRoot[users[i]] == 2){
                res[count] = users[i];
                count++;
            }

            //aggiungo gli utenti temporanei aventi i permessi
            for(uint k = 0; k < tempUser[users[i]].length; k++){
                if(tempUser[users[i]][k].start >= block.number && tempUser[users[i]][k].end <= block.number){
                    res[count] = users[i];
                    count++;
                }
            }
        }
        return res;
    }
    
    /**
     * Controlla che gli utenti temporanei abbiano attualmente il tempo di accesso
     **/
    function isValidTemp(address _usr) public view returns(bool){
        for(uint i = 0; i < tempUser[_usr].length; i++){
            if(tempUser[_usr][i].start >= block.number && tempUser[_usr][i].end <= block.number){
                return true;
            }
        }
        return false;
    }
    
    /**
     * Converte le stringhe in bytes32
     **/
    function stringToBytes(string memory _s) private pure returns (bytes32){
        bytes32 result;
        assembly {
            result := mload(add(_s, 32))
        }
        return result;
    }

    /**
     * Converte i bytes32 in stringhe
     **/
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
    
    /**
     * chiude il contratto
     **/
    function closeContract() onlyCreator(msg.sender) public{
        selfdestruct(address(0));
    }
    
}