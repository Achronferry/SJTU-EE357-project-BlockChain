import '../styles/style.css'

import Web3 from "web3";
import monopolyArtifact from "../../build/contracts/Monopoly.json";

let roomId = 0

const App = {
    web3: null,
    account: null,
    monopoly: null,

    start: async function () {
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
        let self = this ;
        if (document.getElementById('roomid').value) {
            roomId = parseInt(document.getElementById('roomid').value)
        }
        sessionStorage.setItem('roomId', roomId);
        if (roomId && roomId > 100000 && roomId < 1000000) {
            const {joinRoom} = this.monopoly.methods;
            await joinRoom(roomId).send({from: this.account}).then(function (re) {
                self.JumptoRoom();
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
            "<h1>Monopoly</h1>\n" +
            "<div><b>Room :</b><i id=\"roomid\">000000</i></div>\n" +
            "\n" +
            "<div>\n" +
            "<div id=\"player_info\" style='float: left;width: 300px'>\n" +
            "<div id=\"p1\">empty</div>\n" +
            "<div id=\"p2\">empty</div>\n" +
            "<div id=\"p3\">empty</div>\n" +
            "<div id=\"p4\">empty</div>\n" +
            "</div>\n" +
            "<div id=\"map_info\" style='overflow: hidden'>\n" +
            "    map\n" +
            "</div>\n" +
            "</div>\n" +
            "</br>\n" +
            "</br>\n" +
            "</br>\n" +
            "<p id=\"status\"> none </p>\n" +
            "<p>\n" +
            "    -----------------------------------------------</br>\n" +
            "    A simple Web page to display.</br>\n" +
            "    Written by a depressed dog.</br>\n" +
            "</p>"
        document.getElementById('roomid').innerHTML = roomId;
        await this.updatePlayerInfo();

    },

    updatePlayerInfo: async function () {
        console.log('Updating player information of room: '+roomId)
        const {getPlayerOne} = this.monopoly.methods;
        let p_state = await getPlayerOne(roomId).call();
        document.getElementById('p1').innerHTML =
            "<div id=\"add1\">"+ p_state[0] + "</div>\n" +
            "<div id=\"pos1\">"+ p_state[1] + "</div>\n" +
            "<div id=\"mny1\">"+ p_state[2] + "</div>\n"
        document.getElementById('p2').innerHTML =
            "<div id=\"add2\">"+ p_state[3] + "</div>\n" +
            "<div id=\"pos2\">"+ p_state[4] + "</div>\n" +
            "<div id=\"mny2\">"+ p_state[5] + "</div>\n"
        document.getElementById('p3').innerHTML =
            "<div id=\"add3\">"+ p_state[6] + "</div>\n" +
            "<div id=\"pos3\">"+ p_state[7] + "</div>\n" +
            "<div id=\"mny3\">"+ p_state[8] + "</div>\n"
        document.getElementById('p4').innerHTML =
            "<div id=\"add4\">"+ p_state[9] + "</div>\n" +
            "<div id=\"pos4\">"+ p_state[10] + "</div>\n" +
            "<div id=\"mny4\">"+ p_state[11] + "</div>\n"
    }

};

window.App = App;

window.addEventListener("load", function () {
    if (window.ethereum) {
        // use MetaMask's provider
        App.web3 = new Web3(window.ethereum);
        window.ethereum.enable(); // get permission to access accounts
    } else {
        console.warn(
            "No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live",
        );
        // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
        App.web3 = new Web3(
            new Web3.providers.HttpProvider("http://127.0.0.1:9545"),
        );
    }

    App.start();
});