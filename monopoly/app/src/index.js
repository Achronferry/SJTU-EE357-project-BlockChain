import '../styles/style.css';
import '../styles/map.png';

import Web3 from "web3";
import monopolyArtifact from "../../build/contracts/Monopoly.json";

let roomId = 0
let myTurn = 0
let RoomStatus = 0 // 0-wait 1-play
let PlayerStateListener
let GameStartListener
let OneStepListener
let BuyGridListener
let BuyInfoListener
let BankRuptListener

const App = {
    web3: null,
    account: null,
    monopoly: null,

    start: async function () {
        let self = this;
        const {web3} = this;

        try {
            // get contract instance
            const networkId = await web3.eth.net.getId();
            const deployedNetwork = monopolyArtifact.networks[networkId];
            this.monopoly = new web3.eth.Contract(
                monopolyArtifact.abi,
                deployedNetwork.address,
            );

            console.log(this.monopoly)
            // get accounts
            const accounts = await web3.eth.getAccounts();
            this.account = accounts[0];

        } catch (error) {
            console.error("Could not connect to contract or chain.");
            console.log(error);
        }

    },

    setStatus: function (message) {
        const status = document.getElementById("status");
        status.innerHTML = message;
    },

    createRoom: async function () {
        let self = this;
        roomId = Math.floor(Math.random() * 900000 + 100000)
        sessionStorage.setItem('roomId', roomId)
        document.getElementById('roomid').value = roomId;
        const {createRoom} = this.monopoly.methods;

        await createRoom(roomId).send({from: this.account}).then(async function (re) {
            await self.JumptoRoom();
            self.setStatus('Create room success');
            console.log('createRoom -- roomId=' + roomId);
        }).catch(function (e) {
            console.log('Failed when creating room-' + roomId)
            console.log(e);
        });
    },

    joinRoom: async function () {
        let self = this;
        if (document.getElementById('roomid').value) {
            roomId = parseInt(document.getElementById('roomid').value)
        }
        sessionStorage.setItem('roomId', roomId);
        if (roomId && roomId > 100000 && roomId < 1000000) {
            const {joinRoom} = this.monopoly.methods;
            await joinRoom(roomId).send({from: this.account}).then(async function (re) {
                await self.JumptoRoom();
                self.setStatus('Join room success');
                console.log('joinRoom -- roomId=' + roomId);
            }).catch(function (e) {
                console.log('Failed when joining room-' + roomId)
                console.log(e);
            });

        } else {
            self.setStatus('房间号需为6位数字')
        }
    },

    JumptoRoom: async function () {
        document.getElementById('body').innerHTML = "\n" +
            "<h1 style='width: 100%; text-align: center'>Monopoly</h1>\n" +
            "<div><span style='width: 250px;'><b>Room :</b><i id=\"roomid\">000000</i></span><span id='roll'></span></div></br>\n" +
            "<div><p id=\"status\"> none </p></div>\n" +
            "\n" +
            "<div style='height: 480px'>\n" +
            "<div id=\"player_info\" style='float: left;width: 250px'>\n" +
            "</br><div id=\"p1_container\"><div id=\"p1\" class='playerinfo'></div></div></br>\n" +
            "<div id=\"p2_container\"><div id=\"p2\" class='playerinfo'></div></div></br>\n" +
            "<div id=\"p3_container\"><div id=\"p3\" class='playerinfo'></div></div></br>\n" +
            "<div id=\"p4_container\"><div id=\"p4\"  class='playerinfo'></div></div></br>\n" +
            "</div>\n" +
            "<div id=\"map_info\" class='map'>\n" +
            "<button class='center_bn' onclick=\"App.clickStart()\">START</button>\n" +
            "</div>\n" +
            "</div>\n" +
            "</br></br></br>\n" +
            "<p>\n" +
            "    -----------------------------------------------</br>\n" +
            "    A simple Web page to display.</br>\n" +
            "    Written by a depressed dog.</br>\n" +
            "</p>"
        document.getElementById('roomid').innerHTML = roomId;
        await this.updatePlayerInfo();
        myTurn = await this.monopoly.methods.getMyTurn(roomId).call();
        console.log(myTurn);
        document.getElementById('p' + myTurn).outerHTML = "<div id=\"p" + myTurn + "\" class='myplayerinfo'>" +
            document.getElementById('p' + myTurn).innerHTML + "</div>"
    },

    updatePlayerInfo: async function () {
        console.log('Updating player information of room: ' + roomId)
        let p_state = await this.monopoly.methods.getRoomInfo(roomId).call();
        document.getElementById('p1').innerHTML =
            "<div id=\"add1\">" + "Player 1" + "</div>\n" +
            "<div id=\"pos1\">" + p_state[1] + "</div>\n" +
            "<div id=\"mny1\">" + p_state[2] + "</div>\n"
        document.getElementById('p2').innerHTML =
            "<div id=\"add2\">" + "Player 2" + "</div>\n" +
            "<div id=\"pos2\">" + p_state[4] + "</div>\n" +
            "<div id=\"mny2\">" + p_state[5] + "</div>\n"
        document.getElementById('p3').innerHTML =
            "<div id=\"add3\">" + "Player 3" + "</div>\n" +
            "<div id=\"pos3\">" + p_state[7] + "</div>\n" +
            "<div id=\"mny3\">" + p_state[8] + "</div>\n"
        document.getElementById('p4').innerHTML =
            "<div id=\"add4\">" + "Player 4" + "</div>\n" +
            "<div id=\"pos4\">" + p_state[10] + "</div>\n" +
            "<div id=\"mny4\">" + p_state[11] + "</div>\n"
    },

    updateGridInfo: async function (grid_id) {
        let grid_state = await this.monopoly.methods.getGridInfo(roomId, grid_id).call();
        let update_html = ""
        if (grid_state[2] !== '0') { // private grid
            update_html += "<div>level: " + grid_state[0] + "</div>"
            if (grid_state[1] !== '0') {
                update_html += "<div>Owner: " + grid_state[1] + "</div>"
                update_html += "<div>Tax: " + grid_state[3] + "</div>"
            }
            if (grid_state[0] !== '3') {
                update_html += "<div>Price: " + grid_state[2] + "</div>"
            }
        }
        update_html += "<div style='color: red' id='g" + grid_id + "'></div>";
        document.getElementById('g' + grid_id).innerHTML = update_html;

    },

    clickStart: async function () {
        await this.monopoly.methods.gameInitial(roomId).send({from: this.account, gas: 3000000});
    },

    startGame: async function () {
        let grid_html = "<table style='width: 100%; height: 100%'>";

        for (let i = 0; i < 8; i++) {
            grid_html += "<tr>"
            for (let j = 0; j < 8; j++) {
                if (i === 0) {
                    grid_html += "<td id='g" + j + "' class='grid'>" + j + "</td>";
                    continue;
                }
                if (i === 7) {
                    grid_html += "<td id='g" + (21 - j) + "' class='grid'>" + (21 - j) + "</td>";
                    continue;
                }
                if (j === 0) {
                    grid_html += "<td id='g" + (28 - i) + "' class='grid'>" + (28 - i) + "</td>";
                    continue;
                }
                if (j === 7) {
                    grid_html += "<td id='g" + (7 + i) + "' class='grid'>" + (7 + i) + "</td>";
                    continue;
                }
                grid_html += "<td>" + "</td>";
            }
            grid_html += "</tr>\n"
        }
        grid_html += "</table>\n"
        document.getElementById('map_info').innerHTML = grid_html;
        // document.getElementById('roll').innerHTML = "<button onclick=\"App.rollMove()\">ROLL</button>"
        await this.updatePlayerInfo();
        for (let i = 0; i < 28; i++) {
            this.updateGridInfo(i);
        }
        if (myTurn === '1') {
            document.getElementById('roll').innerHTML = "<button onclick=\"App.rollMove()\">ROLL</button>"
        }
        RoomStatus = 1;
    },

    rollMove: async function () {
        document.getElementById('roll').innerHTML = "";
        await this.monopoly.methods.move(roomId,myTurn).send({from: this.account, gas: 3000000});

    },

    decideBuyGrid: async function(cost, grid) {
        let will_buy = confirm("Buy this grid in cost of "+ cost + " ?");
        this.monopoly.methods.buy(roomId, myTurn, will_buy).send({from: this.account});
    },
};

window.App = App;

window.addEventListener("load", async function () {
    if (window.ethereum) {
        // use MetaMask's provider
        App.web3 = new Web3(window.ethereum);
        window.ethereum.enable(); // get permission to access accounts
    } else {
        console.warn(
            "No web3 detected. Falling back to http://127.0.0.1:9545. You should remove this fallback when you deploy live",
        );
        // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
        App.web3 = new Web3(
            new Web3.providers.WebsocketProvider("ws://127.0.0.1:9545"),
        );
    }
    await App.start();

    PlayerStateListener = App.monopoly.events.PlayerChange(function (error, event) {
        console.log(event);
    })
        .on('data', function (event) {
            App.updatePlayerInfo();
        })
        .on('error', console.error);

    GameStartListener = App.monopoly.events.GameStart(function (error, event) {
        console.log(event);
    })
        .on('data', function (event) {
            App.startGame();
        })
        .on('error', console.error);

    OneStepListener = App.monopoly.events.OneStep(function (error, event) {
        console.log(event);
    })
        .on('data', function (event) {
            let re = event.returnValues;
            App.updatePlayerInfo();
            if (re.step !== '0') {
                App.setStatus("Player " + re.thisTurn + " moves forward " + re.step + " steps!");
            }
            if (re.nextTurn === myTurn) {
                document.getElementById('roll').innerHTML = "<button onclick=\"App.rollMove()\">ROLL</button>"
            }
        })
        .on('error', console.error);


    BuyGridListener = App.monopoly.events.BuyGrid(function (error, event) {
        console.log(event);
    })
        .on('data', function (event) {
            let re = event.returnValues;
            App.updatePlayerInfo();
            if (re.step !== '0') {
                App.setStatus("Player " + re.thisTurn + " moves forward " + re.step + " steps!");
            }
            if (re.thisTurn === myTurn) {
                App.decideBuyGrid(re.cost, re.grid_pos);
            }
        })
        .on('error', console.error);


    BuyInfoListener = App.monopoly.events.BuyInfo(function (error, event) {
        console.log(event);
    })
        .on('data', function (event) {
            let re = event.returnValues;
            App.setStatus("Player " + re.player_turn + " has bought Grid " +
                re.grid_pos + " within " + re.cost + " RMB!")
            App.updatePlayerInfo();
            App.updateGridInfo(re.grid_pos);
        })
        .on('error', console.error);

    BankRuptListener = App.monopoly.events.BankRupt(function (error, event) {
        console.log(event);
    })
        .on('data', async function (event) {
            let re = event.returnValues;
            if (re.player_turn === myTurn){
                confirm("You have been bankrupt! Current living player number: " + re.left_player_num);
                RoomStatus = 0
            }
            App.setStatus("Player " + re.player_turn + " has go bankrupt! Current living player number: " + re.left_player_num);
            if (re.left_player_num === '1') { //game end
                if (re.nextTurn === myTurn) {
                    confirm("Congratulations! You are the final winner!");
                }
                window.location.reload();
            }
            else {
                App.updatePlayerInfo();
                for (let i=0; i< 28 ;i++) {
                    App.updateGridInfo(i);
                }
                if (re.nextTurn === myTurn) {
                    document.getElementById('roll').innerHTML = "<button onclick=\"App.rollMove()\">ROLL</button>"
                }
            }
        })
        .on('error', console.error);

});

