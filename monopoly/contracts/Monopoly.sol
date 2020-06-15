pragma solidity >=0.4.21 <0.7.0;

contract Monopoly {
    //游戏状态：0-未开始，1-游戏中，2-已结束
    enum GameStatus {start, playing, over}

    uint constant boardSize = 36;
    uint grid_maxlevel = 3;
    uint price_tax_rate = 2;

    struct Player {
        address id;
        uint8 position;
        uint32 money;
    }
    // price = base_price * (level+1) 0<=level<3 if level==3 cannot buy
    // tax = base_price * (level+1) * (price_tax_rate + up_rate/10 * level)
    struct Grid {
    uint8 grid_type; //0-personal 1-start 2-event
    address belong_to;
    uint8 level;
    uint8 up_rate;
    uint32 base_price;
    uint32 price_tax_rate;
    }

    struct Room {
        Player[4] players;
        //是哪个选手的轮次:0-none;1-player1;2-player2;...
        uint8 playerTurn;
        GameStatus playStatus;
        Grid[boardSize] chessboard;
        uint8 player_num;
        uint8 winner;
    }
    //room number
    mapping(uint32=>Room) public rooms;

    uint128 BET_MONEY = 1 ether;

    event OneStep(uint8 x, uint8 y, uint8 playerTurn);
    event GameStart();
    event GameOver(uint8 winner);
    event PlayerChange();

      function random() public view returns (uint) {
      return uint(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%251);
    }
    
    
    function map_initial(uint32 _roomId,  uint _territoryNum ) private{
        require( _territoryNum  < boardSize - 1, "Not beyond boardSize");
        //initial map
        for (uint i = 0; i < boardSize; ++i)
             rooms[_roomId].chessboard[i].grid_type = 1;   
        

        //initial territory
        for (uint i = 0; i < _territoryNum; ++i){
            uint rand = random()%36;
            if (rand == 0 && rooms[_roomId].chessboard[rand].grid_type == 0)
                i--;
            else
               rooms[_roomId].chessboard[rand].grid_type = 0;
        }
    }
    
    function  move(uint32 _roomId) private{
        uint8 step = uint8(random()%6);
        Room storage now_room = rooms[_roomId];
        uint8 _playerTurn = now_room.playerTurn;
        now_room.players[_playerTurn].position += step;
    }
    
    
    function Is_territory(uint32 _roomId) private view returns (bool){
        uint8 _playerTurn = rooms[_roomId].playerTurn;
        uint position =  rooms[_roomId].players[_playerTurn].position;
        if (rooms[_roomId].chessboard[position].grid_type == 0)
              return true;
        return false;
    }
    
    function PayTax(uint32 _roomId) private{
        uint8 _playerTurn = rooms[_roomId].playerTurn;
        uint position =  rooms[_roomId].players[_playerTurn].position;
        Grid storage _grid = rooms[_roomId].chessboard[position];
        Player storage _player = rooms[_roomId].players[_playerTurn];
        uint32 tax = _grid.base_price* (_grid.level+1) * (_grid.price_tax_rate + _grid.up_rate/10 * _grid.level);
        _player.money -= tax;
    }
    
    function Is_Bankruptcy(uint32 _roomId) private{
        
        
    }

    function createRoom(uint32 _roomId) public payable {
        require(_roomId > 0, "room id must greater than zero");
        require(rooms[_roomId].players[0].id == address(0x0), "this room is not empty");
        rooms[_roomId].players[0].id = msg.sender;
        rooms[_roomId].player_num = 1;
    }

    //加入游戏
    function joinRoom(uint32 _roomId) public payable{
        require(_roomId > 0);
        require(rooms[_roomId].player_num != 0 , "this room is empty");
        require(rooms[_roomId].player_num != 4, "this room is full");

        rooms[_roomId].players[rooms[_roomId].player_num].id = msg.sender;
        // rooms[_roomId].playStatus = GameStatus.playing;
        rooms[_roomId].player_num = rooms[_roomId].player_num + 1;
        emit PlayerChange();
    }

    function getRoomInfo(uint32 _roomId) public view returns(address p1_add, uint8 p1_pos, uint32 p1_mny,address p2_add, uint8 p2_pos, uint32 p2_mny, address p3_add, uint8 p3_pos, uint32 p3_mny, address p4_add, uint8 p4_pos, uint32 p4_mny){
        require(_roomId > 0, "room id must greater than zero");
        Room memory now_room = rooms[_roomId];
        return (now_room.players[0].id, now_room.players[0].position, now_room.players[0].money, now_room.players[1].id, now_room.players[1].position, now_room.players[1].money, now_room.players[2].id, now_room.players[2].position, now_room.players[2].money, now_room.players[3].id, now_room.players[3].position, now_room.players[3].money);
    }



}