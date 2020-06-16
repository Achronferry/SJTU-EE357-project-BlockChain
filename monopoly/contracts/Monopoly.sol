pragma solidity >=0.4.21 <0.7.0;

contract Monopoly {
    //游戏状态：0-未开始，1-游戏中
    enum GameStatus {waiting, playing}

    uint constant boardSize = 28;
    uint grid_maxlevel = 3;
    uint price_tax_rate = 2;

    struct Player {
        address id;
        uint8 position;
        uint32 money;
    }
    // 自己的地正常计算，别人的地加倍
    // price = base_price * (level+1) 0<=level<3 if level==3 cannot buy
    // tax = base_price * level * ( 1 + up_rate/10 * level)
    struct Grid {
    uint8 grid_type; //0-personal 1-start 2-event
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
    
    
    function gameInitial(uint32 _roomId) public {
        //initial map
        for (uint i = 0; i < boardSize; ++i) {
             if (i % (boardSize / 4) == 0)
                 rooms[_roomId].chessboard[i].grid_type = 0;
             else {
                 rooms[_roomId].chessboard[i].grid_type = 1; 
                 rooms[_roomId].chessboard[i].up_rate = random()%10; 
                 rooms[_roomId].chessboard[i].base_price = (10 + random()%40) * 100;
             }
	}  
        
       
        for (uint i = 0; i<rooms[_roomId].player_num;++i){
            rooms[_roomId].players[i].money = 20000;
            rooms[_roomId].players[i].position = 0;  
        }
        rooms[_roomId].playStatus = GameStatus.playing;
        rooms[_roomId].playerTurn = 1;
        emit GameStart();
    }
    

    function move(uint32 _roomId) private{
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
        uint32 tax = _grid.base_price* (_grid.level+1) * (1 + _grid.up_rate/10 * _grid.level);
        _player.money -= tax;
        for (uint i =0;i<4;++i){
            if (_grid.belong_to == rooms[_roomId].players[_playerTurn].id )
                rooms[_roomId].players[_playerTurn].money += tax;
        }
        
    }
    
    function Is_Bankruptcy(uint32 _roomId) private view returns (bool){
        uint8 _playerTurn = rooms[_roomId].playerTurn;
        Player memory _player = rooms[_roomId].players[_playerTurn];
        return ( _player.money < 0);
    }

    //先判断是不是自己的, 能不能买 先不判断了

    //计算资费和看够不够，确保够

    function Buy_territory(uint32 _roomId) private{
        uint8 _playerTurn = rooms[_roomId].playerTurn;
        uint position =  rooms[_roomId].players[_playerTurn].position;
        Grid storage _grid = rooms[_roomId].chessboard[position];
        Player storage _player = rooms[_roomId].players[_playerTurn];
        uint32 money2pay;
        if (_grid.belong_to == msg.sender && _grid.level < 3 ){
             money2pay = _grid.base_price * (_grid.level+1);
            _player.money -= money2pay;
        }
        else {
            money2pay = _grid.base_price * (_grid.level+1)*2;
            _player.money -= money2pay;
            for (uint i =0;i<4;++i){
                if (_grid.belong_to == rooms[_roomId].players[_playerTurn].id )
                    rooms[_roomId].players[_playerTurn].money += money2pay;
            
            }
        }
        _grid.belong_to = msg.sender;
        _grid.level++;
    }
    
    function changeplayer(uint32 _roomId) private{
        uint8  _playerTurn = rooms[_roomId].playerTurn;
        if (_playerTurn ==  rooms[_roomId].player_num)
            rooms[_roomId].player_num = 1;
        else
            rooms[_roomId].playerTurn = (_playerTurn+1);
        
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
    function joinRoom(uint32 _roomId) public payable returns(uint8 player_num){
        require(_roomId > 0);
        require(rooms[_roomId].player_num != 0 , "this room is empty");
        require(rooms[_roomId].player_num != 4, "this room is full");
        require(rooms[_roomId].playStatus == GameStatus.waiting, "The game has begun.");

        rooms[_roomId].players[rooms[_roomId].player_num].id = msg.sender;
        // rooms[_roomId].playStatus = GameStatus.playing;
        rooms[_roomId].player_num = rooms[_roomId].player_num + 1;
        emit PlayerChange();
        return rooms[_roomId].player_num;
    }

    function getRoomInfo(uint32 _roomId) public view returns(address p1_add, uint8 p1_pos, uint32 p1_mny,address p2_add, uint8 p2_pos, uint32 p2_mny, address p3_add, uint8 p3_pos, uint32 p3_mny, address p4_add, uint8 p4_pos, uint32 p4_mny){
        require(_roomId > 0, "room id must greater than zero");
        Room memory now_room = rooms[_roomId];
        return (now_room.players[0].id, now_room.players[0].position, now_room.players[0].money, now_room.players[1].id, now_room.players[1].position, now_room.players[1].money, now_room.players[2].id, now_room.players[2].position, now_room.players[2].money, now_room.players[3].id, now_room.players[3].position, now_room.players[3].money);
    }



}
