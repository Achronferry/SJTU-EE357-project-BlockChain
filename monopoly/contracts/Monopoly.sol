pragma solidity >=0.4.21 <0.7.0;

contract Monopoly {
    //游戏状态：0-未开始，1-游戏中，2-已结束
    enum GameStatus {start, playing, over}

    uint constant boardSize = 36;
    uint grid_maxlevel = 3;
    uint price_tax_rate = 2;

    struct Player {
        address id;
        uint position;
        uint money;
    }
    // price = base_price * (level+1) 0<=level<3 if level==3 cannot buy
    // tax = base_price * (level+1) * (price_tax_rate + up_rate * level)
    struct Grid {
    uint8 grid_type; //0-personal 1-start 2-event
    address belong_to;
    uint8 level;
    ufixed8x2 up_rate;
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

    function createRoom(uint32 _roomId) public payable {
        require(_roomId > 0, "room id must greater than zero");
        require(rooms[_roomId].players[0].id == address(0x0), "this room is not empty");
        rooms[_roomId].players[0].id = msg.sender;
        rooms[_roomId].players[0].money = msg.value;
        rooms[_roomId].player_num = 1;
    }

    //加入游戏
    function joinRoom(uint32 _roomId) public payable{
        require(_roomId > 0);
        require(rooms[_roomId].player_num == 0 , "this room is empty");
        require(rooms[_roomId].player_num == 4, "this room is full");

        rooms[_roomId].players[1].id = msg.sender;
        rooms[_roomId].players[1].money = msg.value;
        rooms[_roomId].playStatus = GameStatus.playing;
        rooms[_roomId].playerTurn = 1;
        emit GameStart();
    }


    function getMyMoney(uint32 _roomId) payable public  {
        require(rooms[_roomId].playStatus == GameStatus.over || rooms[_roomId].playStatus == GameStatus.start, "The game is playing");
        require(rooms[_roomId].winner > 0);
        Player memory player = rooms[_roomId].players[rooms[_roomId].winner - 1];
        require(player.id == msg.sender);
        uint senderMoney = player.money;
        require(senderMoney > 0, "You have got your money");
        assert(address(this).balance >= senderMoney);
        address(msg.sender).transfer(senderMoney);
    }



    //标记胜出者
    function winGame(uint8 _winner, uint32 _roomId) private {
        require(0 <= _winner && _winner <= 2, "invalid winner state");
        rooms[_roomId].winner = _winner;
        // 游戏结束
        if (rooms[_roomId].winner != 0) {
            rooms[_roomId].playStatus = GameStatus.over;
            rooms[_roomId].playerTurn = 0;
            if (rooms[_roomId].winner == 1) {
                assert(rooms[_roomId].players[1].money >= BET_MONEY);
                rooms[_roomId].players[1].money -= BET_MONEY;
                rooms[_roomId].players[0].money += BET_MONEY;
            }else {
                assert(rooms[_roomId].players[0].money >= BET_MONEY);
                rooms[_roomId].players[0].money -= BET_MONEY;
                rooms[_roomId].players[1].money += BET_MONEY;
            }
            emit GameOver(rooms[_roomId].winner);
        }
    }
}
