pragma solidity >=0.4.21 <0.7.0;

contract Monopoly {
    //游戏状态：0-未开始，1-游戏中
    enum GameStatus {waiting, playing}

    uint8 constant boardSize = 28;
    uint grid_maxlevel = 3;
    uint price_tax_rate = 2;
    uint256 rand_seed = 1;
    struct Player {
        address id;
        uint8 position;
        int32 money;
    }
    // 自己的地正常计算，别人的地加倍
    // price = base_price * (level+1) 0<=level<3 if level==3 cannot buy
    // tax = base_price * level * ( 1 + up_rate/10 * level)
    struct Grid {
    uint8 grid_type; //0- nothing 1-buyable 2-event
    uint8 belong_to;
    uint8 level;
    uint8 up_rate;
    uint32 base_price;
    }

    struct Room {
        Player[4] players;
        //是哪个选手的轮次:0-none ;1-player1;2-player2;...
        uint8 playerTurn;
        GameStatus playStatus;
        Grid[boardSize] chessboard;
        uint8 player_num;
        uint8 living_num;
        uint8 winner;
    }
    //room number
    mapping(uint32=>Room) public rooms;

    uint128 BET_MONEY = 1 ether;

    event OneStep(uint32 roomId, uint8 step, uint8 thisTurn, uint8 nextTurn);
    event GameStart();
    event PlayerChange();
    event BuyGrid(uint32 roomId, uint8 step, int32 cost, uint8 thisTurn,uint8 grid_pos);
    event BuyInfo(uint32 roomId, int32 cost, uint8 player_turn, uint8 grid_pos);
    event BankRupt(uint32 roomId, uint8 player_turn,address add , uint8 step, uint8 nextTurn, uint8 left_player_num);


     function random() public returns (uint) {
       uint256 t1 = now * rand_seed;
       rand_seed++;
      // return rand_seed;
      return uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty,t1)))%251);
    }
    
    function gameInitial(uint32 _roomId) public  payable{
        //require( _territoryNum  < boardSize - 1, "Not beyond boardSize");
        //initial map
        for (uint i = 0; i < boardSize; ++i) {
             if (i % (boardSize / 4) == 0)
                 rooms[_roomId].chessboard[i].grid_type = 0;
             else {
                 rooms[_roomId].chessboard[i].grid_type = 1; 
                 rooms[_roomId].chessboard[i].up_rate = uint8(random()%10); 
                 rooms[_roomId].chessboard[i].base_price = uint32(10 + random()%40) * 100;
             }
	}  
        
       
        for (uint i = 0; i<rooms[_roomId].player_num;++i){
            rooms[_roomId].players[i].money = 20000;
            rooms[_roomId].players[i].position = 0;  
        }
        
        rooms[_roomId].playStatus = GameStatus.playing;
        rooms[_roomId].playerTurn = 1;
        rooms[_roomId].living_num = rooms[_roomId].player_num;
        emit GameStart();
    }
    
    

    function move(uint32 _roomId, uint8 player_turn) public {
    uint8 _player_turn = player_turn - 1;
    require(player_turn == rooms[_roomId].playerTurn,'error player dump');
    require(msg.sender == rooms[_roomId].players[_player_turn].id,'error player address');
    uint8 step = uint8(random()%6 + 1);
    rooms[_roomId].players[_player_turn].position += step;
    rooms[_roomId].players[_player_turn].position %= boardSize;
    
    uint8 position =  rooms[_roomId].players[_player_turn].position;
    Grid storage _grid = rooms[_roomId].chessboard[position];
    if (rooms[_roomId].chessboard[position].grid_type == 1 ){
            PayTax(_roomId);
            if (Is_Bankruptcy(_roomId)) {
                uint8 next_player_turn = changeplayer(_roomId);
                goBankrupt(_roomId, player_turn, step, next_player_turn);
                return;
            }
        // considerting not BankRupt
        int32 cost = int32(_grid.base_price * (_grid.level+1));
        //buy
        if (rooms[_roomId].players[_player_turn].money > cost
                && _grid.level < 3){
              // buy(_roomId, player_turn, will_buy)
                emit BuyGrid(_roomId, step, cost, player_turn, position);
        }
        //not buy
        else{   
              uint8 next_player_turn = changeplayer(_roomId);
              emit OneStep(_roomId, step, player_turn, next_player_turn);
        }
    }
    //not land
    else{
            uint8 next_player_turn = changeplayer(_roomId);
            emit OneStep(_roomId, step, player_turn, next_player_turn);
    }
}

  

    
    // function Is_territory(uint32 _roomId) private view returns (bool){
    //     uint8 _playerTurn = rooms[_roomId].playerTurn;
    //     uint position =  rooms[_roomId].players[_playerTurn-1].position;
    //     if (rooms[_roomId].chessboard[position].grid_type == 0)
    //           return true;
    //     return false;
    // }
    
    function PayTax(uint32 _roomId) private{
        uint8 _playerTurn = rooms[_roomId].playerTurn;
        uint8 _player_turn = _playerTurn - 1;
        uint8 position =  rooms[_roomId].players[_player_turn].position;
        Grid memory _grid = rooms[_roomId].chessboard[position];
 
        int32 tax = int32( _grid.base_price * _grid.level * ( 1 + _grid.up_rate/10 * _grid.level));
        rooms[_roomId].players[_player_turn].money -= tax;
        if (_grid.belong_to != 0){
            uint8 _belong_to = _grid.belong_to-1;
            rooms[_roomId].players[_belong_to].money += tax;
            
        }
  
    }
    
    function Is_Bankruptcy(uint32 _roomId) private view returns (bool){
        uint8 _playerTurn = rooms[_roomId].playerTurn - 1;
        Player memory _player = rooms[_roomId].players[_playerTurn];
        return ( _player.money <= 0);
    }
    
    function goBankrupt(uint32 _roomId, uint8 player_turn, uint8 step, uint8 next_player_turn) private{
	// all grid belong to this player iturns free;
	  for (uint i = 0; i < boardSize; ++i) {
	        if (rooms[_roomId].chessboard[i].belong_to == player_turn){
	             rooms[_roomId].chessboard[i].belong_to = 0;
	             rooms[_roomId].chessboard[i].level = 0;
	        }
         }
         rooms[_roomId].living_num -- ;
         uint8 _player_turn = player_turn - 1;
	 emit BankRupt(_roomId, player_turn, rooms[_roomId].players[_player_turn].id, step, next_player_turn, rooms[_roomId].living_num);
}

    //先判断是不是自己的, 能不能买 先不判断了

    //计算资费和看够不够，确保够
    
    function buy(uint32 _roomId, uint8 player_turn, bool will_buy) public{
        require(player_turn == rooms[_roomId].playerTurn,'error player dump');
        uint8 _player_turn = player_turn-1;
        if (will_buy) {
        uint8 position =  rooms[_roomId].players[_player_turn].position;
        Grid storage _grid = rooms[_roomId].chessboard[position];
        int32 money2pay = int32(_grid.base_price * (_grid.level+1));
         if ( _grid.belong_to == player_turn ||  _grid.belong_to == 0){
             rooms[_roomId].players[_player_turn].money -= money2pay;
 
         }
         else{
             rooms[_roomId].players[_player_turn].money -= money2pay;
             uint8 _belong_to = _grid.belong_to-1;
             rooms[_roomId].players[_belong_to].money += money2pay;
         }
              
        _grid.belong_to = player_turn;
        _grid.level++;
         emit BuyInfo(_roomId, money2pay, player_turn, position);
	}

         uint8 next_player_turn = changeplayer(_roomId);
         emit OneStep(_roomId, 0, player_turn, next_player_turn);
       // emit OneStep(_roomId, 0, player_turn, next_player_turn);

    }

    function changeplayer(uint32 _roomId) private returns (uint8){
        uint8  _playerTurn = rooms[_roomId].playerTurn;
        uint8 _next_playerTurn = 0;
        while( _next_playerTurn != _playerTurn){
             if (_playerTurn ==  rooms[_roomId].player_num)
                    _next_playerTurn = 1;
             else
                _next_playerTurn = (_playerTurn+1);
                
            rooms[_roomId].playerTurn = _next_playerTurn;
            if  (!Is_Bankruptcy(_roomId)  ) 
                    return rooms[_roomId].playerTurn;        
        }
        return rooms[_roomId].playerTurn;
        
    }



    function getGridInfo(uint32 _roomId, uint8 position) public view returns (uint8 ,uint8, int32 ,int32 ){
          Grid memory _grid = rooms[_roomId].chessboard[position];
          int32 currentprice = int32(_grid.base_price * (_grid.level+1));
          int32 tax = int32( _grid.base_price * _grid.level * ( 1 + _grid.up_rate/10 * _grid.level));
          return (_grid.level,_grid.belong_to,  currentprice,tax);
          

    }

    function createRoom(uint32 _roomId) public payable {
        require(_roomId > 0, "room id must greater than zero");
        require(rooms[_roomId].players[0].id == address(0x0), "this room is not empty");
        rooms[_roomId].players[0].id = msg.sender;
        rooms[_roomId].player_num = 1;
    }

    // function GameTesting(uint32 _roomId) private{
    //     map_initial(_roomId,  10 );
    //     move(_roomId);
        
    // }

    //加入游戏
    function joinRoom(uint32 _roomId) public payable{
        require(_roomId > 0);
        require(rooms[_roomId].player_num != 0 , "this room is empty");
        require(rooms[_roomId].player_num != 4, "this room is full");
        require(rooms[_roomId].playStatus == GameStatus.waiting, "The game has begun.");

        rooms[_roomId].players[rooms[_roomId].player_num].id = msg.sender;
        // rooms[_roomId].playStatus = GameStatus.playing;
        rooms[_roomId].player_num = rooms[_roomId].player_num + 1;
        emit PlayerChange();
    }

    function getRoomInfo(uint32 _roomId) public view returns(address p1_add, uint8 p1_pos, int32 p1_mny,address p2_add, uint8 p2_pos, int32 p2_mny, address p3_add, uint8 p3_pos, int32 p3_mny, address p4_add, uint8 p4_pos, int32 p4_mny){
        require(_roomId > 0, "room id must greater than zero");
        Room memory now_room = rooms[_roomId];
        return (now_room.players[0].id, now_room.players[0].position, now_room.players[0].money, now_room.players[1].id, now_room.players[1].position, now_room.players[1].money, now_room.players[2].id, now_room.players[2].position, now_room.players[2].money, now_room.players[3].id, now_room.players[3].position, now_room.players[3].money);
    }

    function getMyTurn(uint32 _roomId) public view returns(uint8){
        return rooms[_roomId].player_num;
    }


}
