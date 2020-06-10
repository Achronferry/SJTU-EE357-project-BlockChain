pragma solidity ^0.4.23;

contract Gobang {
    //游戏状态：0-未开始，1-游戏中，2-已结束
    enum GameStatus {start, playing, over}

    uint constant boardSize = 15;

    struct Player {
        address id;
        uint money;
    }
    struct Room {
        Player[2] players;
        //是哪个选手的轮次:0-noone;1-player1;2-player2
        uint8 playerTurn;
        GameStatus playStatus;
        uint8[boardSize][boardSize] chessboard;
        //统计棋子的数量
        uint8 stone_num;
        uint8 winner;
    }
    //房间号对应了两位玩家
    mapping(uint32=>Room) public rooms;

    uint128 BET_MONEY = 1 ether;

    event OneStep(uint8 x, uint8 y, uint8 playerTurn);
    event GameStart();
    event GameOver(uint8 winner);

    function createRoom(uint32 _roomId) public payable {
        require(_roomId > 0, "room id must greater than zero");
        require(rooms[_roomId].players[0].id == 0x0, "this room is not empty");
        require(msg.value >= BET_MONEY, "need 1 ether bet fund");
        rooms[_roomId].players[0].id = msg.sender;
        rooms[_roomId].players[0].money = msg.value;
    }

    //加入游戏
    function joinGame(uint32 _roomId) public payable{
        require(_roomId > 0);
        require(rooms[_roomId].players[0].id != 0x0 , "this room is empty");
        require(rooms[_roomId].players[1].id == 0x0, "there two players in the room");
        require(msg.value >= BET_MONEY, "need 1 ether bet fund");

        rooms[_roomId].players[1].id = msg.sender;
        rooms[_roomId].players[1].money = msg.value;
        rooms[_roomId].playStatus = GameStatus.playing;
        rooms[_roomId].playerTurn = 1;
        emit GameStart();
    }

    //玩家落子
    function oneStep(uint8 _x, uint8 _y, uint32 _roomId) public {
        require(rooms[_roomId].playStatus != GameStatus.over, "Game is over");
        require(rooms[_roomId].playStatus != GameStatus.start, "Game is preparing");
        require(msg.sender == rooms[_roomId].players[rooms[_roomId].playerTurn - 1].id, "Not your turn");
        require(checkBoundary(_x, _y), "Out of boundary");
        require(rooms[_roomId].chessboard[_x][_y] == 0, "Can not move chess here");

        //放置棋子
        rooms[_roomId].chessboard[_x][_y] = rooms[_roomId].playerTurn;
        rooms[_roomId].stone_num++;
        emit OneStep(_x, _y, rooms[_roomId].playerTurn);

        // 检查是否五子连珠
        if (checkFive(_x, _y, 1, 0, _roomId) || // 水平方向
        checkFive(_x, _y, 0, 1, _roomId) || // 垂直方向
        checkFive(_x, _y, 1, 1, _roomId) || // 左上到右下方向
        checkFive(_x, _y, 1, - 1, _roomId)) {// 右上到左下方向
            winGame(rooms[_roomId].playerTurn, _roomId);
            // 五子连珠达成，当前用户胜利
            return;
        }

        if (rooms[_roomId].stone_num == 225) {
            // 棋盘放满，和局
            rooms[_roomId].playStatus = GameStatus.over;
            rooms[_roomId].playerTurn = 0;
            emit GameOver(0);
        }
        else {
            // 修改下一步棋的落子方
            if (rooms[_roomId].playerTurn == 1) {
                rooms[_roomId].playerTurn = 2;
            }
            else {
                rooms[_roomId].playerTurn = 1;
            }
            rooms[_roomId].playStatus = GameStatus.playing;
        }
    }

    function getNewestState(uint32 _roomId) public view returns (uint8, address, address, GameStatus, uint8[15][15]) {
        return (rooms[_roomId].playerTurn, rooms[_roomId].players[0].id, rooms[_roomId].players[1].id, rooms[_roomId].playStatus, rooms[_roomId].chessboard);
    }

    function getMyMoney(uint32 _roomId) payable public  {
        require(rooms[_roomId].playStatus == GameStatus.over || rooms[_roomId].playStatus == GameStatus.start, "The game is playing");
        require(rooms[_roomId].winner > 0);
        Player player = rooms[_roomId].players[rooms[_roomId].winner - 1];
        require(player.id == msg.sender);
        uint senderMoney = player.money;
        require(senderMoney > 0, "You have got your money");
        assert(address(this).balance >= senderMoney);
        address(msg.sender).send(senderMoney);
    }

    function getSomething() view public returns (uint something)  {
        return address(this).balance;
    }

    //检查边界
    function checkBoundary(uint8 _x, uint8 _y) private pure returns (bool) {
        return (_x < boardSize && _y < boardSize);
    }

    //检查是否五子连珠
    function checkFive(uint8 _x, uint8 _y, int _xdir, int _ydir, uint32 _roomId) private view returns (bool) {
        uint8 count = 0;
        count += countChess(_x, _y, _xdir, _ydir, _roomId);
        // 检查反方向
        count += countChess(_x, _y, - 1 * _xdir, - 1 * _ydir, _roomId) - 1;
        if (count >= 5) {
            return true;
        }
        return false;
    }

    //数棋子的数量
    function countChess(uint8 _x, uint8 _y, int _xdir, int _ydir, uint32 _roomId) private view returns (uint8) {
        uint8 count = 1;
        while (count <= 5) {
            uint8 x = uint8(int8(_x) + _xdir * count);
            uint8 y = uint8(int8(_y) + _ydir * count);
            if (checkBoundary(x, y) && rooms[_roomId].chessboard[x][y] == rooms[_roomId].chessboard[_x][_y]) {
                count += 1;
            }
            else {
                return count;
            }
        }
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
