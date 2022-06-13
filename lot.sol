//SPDX-License-Identifier: MIT 
pragma solidity ^0.8.7; 

contract Lottery {
    struct Person {
        uint personId;
        address addr;
        uint remainingTokens;
}

    struct Item {
        uint itemId;
        address[] tickets;
}
    enum Stage {Init, Reg, Bid, Done}
    Stage public stage = Stage.Init;

    event Winner(address indexed _from, uint256 indexed _id, uint256 indexed _lotcount);
    mapping(address => Person) tokenDetails; // διεύθυνση παίκτη
    Person[4] bidders; // πίνακας 4 παικτών
    Item[] public items; // πίνακας 3 αντικειμένων
    address[3] public winners; // πίνακας νικητών - η τιμή 0 δηλώνει πως δεν υπάρχει νικητής
    address public beneficiary; // ο πρόεδρος του συλλόγου και ιδιοκτήτης του smart contract
    uint bidderCount = 0; // πλήθος των εγγεγραμένων παικτών
    uint public randomNum=0;
    address public winner ;
    uint lotterycount=0; //Αριθμός λαχειοφόρου

    modifier onlyOwner() {
        require(beneficiary == msg.sender, "You are not allowed");
        _;
    }

    modifier noneOwner(){
        if(msg.sender == beneficiary)
            revert("Owner can't take place in lottery");
        _;
    }

    modifier Regtime(){
        if(stage != Stage.Reg)
            revert("It's not the right time for Registration");
        _;
    }

    modifier Donetime(){
        if(stage != Stage.Done)
            revert("It's not the right time for Ruffle");
        _;
    }

    modifier Bidtime(){
        if(stage != Stage.Bid)
            revert("It's not the right time for Bidding");
        _;
    }
    constructor()  payable noneOwner{ //constructor
    // Αρχικοποίηση του προέδρου με τη διεύθυνση του κατόχου του έξυπνου συμβολαίου
    beneficiary = msg.sender;
    address[] memory emptyArray;

    // For initial deployment 3 items are created, after that owner specifies amount

    items.push(Item({itemId:1, tickets:emptyArray})); // το πρώτο αντικείμενο
    items.push(Item({itemId:2, tickets:emptyArray}));
    items.push(Item({itemId:3, tickets:emptyArray}));

    stage = Stage.Reg; //Set stage to Registration phase
    }

    //initialize items array after reset 
    function initialize(uint elements) public onlyOwner{

        address[] memory emptyArray;
        for(uint i=0; i<elements; i++){
            
            items.push(Item({itemId:i, tickets:emptyArray}));
        }
        lotterycount++; // Increase lotterycount by one
    }

    modifier toregister() {
        if (msg.value < 0.01 ether)
            revert("Error :You have less than 0.01 ether");
            _;
        
    }

    function register() public payable toregister Regtime{ // εγγραφή παίκτη
        
        bidders[bidderCount].personId = bidderCount;
        // Αρχικοποίηση της διεύθυνσης του παίκτη
        bidders[bidderCount].addr = msg.sender;
        bidders[bidderCount].remainingTokens = 5; // μόνο 5 λαχεία
        tokenDetails[msg.sender] = bidders[bidderCount];
        bidderCount++;
}

    modifier tobid(uint _count) {
         if (tokenDetails[msg.sender].remainingTokens <= _count )
            revert("The remaining Tokens are not sufficient");
        _;
    }

    modifier existingItem(uint _itemId) {
        uint x = 0;
        for (uint i=0; i< items.length; i++){

                if (items[i].itemId == _itemId)
                     x=1;
        }

        if (x!= 1)
            revert("The itemId doesn't exist");
            
        _;
    }

    function bid(uint _itemId, uint _count) public payable tobid(_count) existingItem(_itemId) Bidtime{ // Ποντάρει _count λαχεία στο
        
        /*
        Δύο έλεγχοι:
        ο παίκτης που καλεί έχει επαρκές πλήθος λαχείων;
        το αντικείμενο υπάρχει;
        */
        
        tokenDetails[msg.sender].remainingTokens -= _count;
        uint identification = tokenDetails[msg.sender].personId;
        bidders[identification] = tokenDetails[msg.sender];

        for (uint i=0; i<_count; i++){
            items[_itemId].tickets.push(msg.sender);
            
        }

        

        /*
        Ενημέρωση του υπολοίπου λαχείων του παίκτη
        */
        /*
        Ενημέρωση της κληρωτίδας του _itemId με εισαγωγή των _count λαχείων που ποντάρει ο παίκτης
        */
}

    
    

    function revealWinners() public  onlyOwner Donetime { // θα υλοποιήσετε modifier με το όνομα onlyOwner
        /*
        Για κάθε αντικείμενο που έχει περισσότερα από 0 λαχεία στην κάλπη του
        επιλέξτε τυχαία έναν νικητή από όσους έχουν τοποθετήσει το λαχείο τους
        */
        for (uint id = 0; id < items.length; id++) { 
            if (items[id].tickets.length !=0){
                randomNum = uint(keccak256(abi.encodePacked(beneficiary, block.timestamp))) % items[id].tickets.length;// παραγωγή τυχαίου αριθμού
                winner = items[id].tickets[randomNum];// ανάκτηση του αριθμού παίκτη που είχε αυτό το λαχείο
                winners[id] = winner;// ενημέρωση του πίνακα winners με τη διεύθυνση του νικητή
                emit Winner(winner, id, lotterycount);
            }
            
           
        }
    }


    // Withdraw all Balance from Conctract to Owner
    function withdraw() public onlyOwner {
        uint _amount;
        _amount = getBalance();
        payable(msg.sender).transfer(_amount);
    }

    // Get Balance of Contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    //Get personal Details of a Person
    function getPersonDetails(uint id) public view returns(uint, uint, address){
        return (bidders[id].remainingTokens, bidders[id].personId, bidders[id].addr);
    }

    function reset(uint elements) public onlyOwner payable {
        
        delete items;   // empty items array
        delete bidders; // empty bidders array
        delete winners; // empty winners array
        bidderCount = 0;// reset bidder Count
        initialize(elements);   // initialize new items array with amount of items equall elements
        stage = Stage.Reg;      // Set stage to Registration Phase again
        
    }

    // For Debugging Purposes
    //function getCount() public view returns(uint count){
    //    return items.length;
    //}

    function advanceState() public onlyOwner{
        if (stage == Stage.Done)
            revert("The Lottery is on done Stage, Please call Reset function");
        if( stage == Stage.Bid)
            stage = Stage.Done;
        if( stage == Stage.Reg)
            stage = Stage.Bid;
    }

    // For Debugging Purposes
    //function getState() public pure  returns(Stage stage){
    //    return stage;
    // }

    
}