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
