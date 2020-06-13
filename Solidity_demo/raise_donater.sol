pragma solidity >=0.4.22 <0.6.0;

contract raiseMoney{
    
    
    
    struct raiser{
        address raddress;
        uint goal;
        uint amount;
        uint donater_nums;
        mapping (uint => donater) map;
        
    }
    
    struct donater{
        address daddress;
        uint To_money;
    }
    uint raiseramount;
    mapping (uint => raiser) raiser_map;
    
    
    function newraiser(address _add, uint _goal) public{
        raiseramount++;
        raiser_map[raiseramount] =  raiser(_add,_goal,0,0);
        
    }
    
    function contribute(address _add,uint _raiseamount) public payable{
        raiser storage _raiser = raiser_map[_raiseamount];
        _raiser.amount += msg.value;
        _raiser.donater_nums ++;
        _raiser.map[_raiser.donater_nums] =  donater(_add,msg.value);
        
    }
    
    function IScomplete(uint _raiseamount) public{
        raiser storage _raiser = raiser_map[_raiseamount];
        if (_raiser.amount >= _raiser.goal){
            _raiser.raddress.transfer(_raiser.amount);
        }
    }
    
}