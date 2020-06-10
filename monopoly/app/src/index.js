import '../styles/style.css'

import Web3 from "web3";
import { default as contract } from 'truffle-contract';
// import metaCoinArtifact from "../../build/contracts/MetaCoin.json";

const Monopoly = contract(gobangArtifact)

let roomId = 0


const App = {
  web3: null,
  account: null,
  meta: null,

  start: async function() {
    const { web3 } = this;

    try {
      // get contract instance
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = metaCoinArtifact.networks[networkId];
      this.meta = new web3.eth.Contract(
        metaCoinArtifact.abi,
        deployedNetwork.address,
      );

      // get accounts
      const accounts = await web3.eth.getAccounts();
      this.account = accounts[0];

      this.refreshBalance();
    } catch (error) {
      console.error("Could not connect to contract or chain.");
    }
  },

  CreateRoom: function () {
    let self = this
    roomId = Math.floor(Math.random() * 900000 + 100000)
    sessionStorage.setItem('roomid', roomId)
    document.getElementById('roomid').value = roomId
    window.gobang.createRoom(roomId, {
      value: '1000000000000000000'
    }).then((data) => {
      self.setStatus('Create room success')
      console.log('createRoom -- roomId=' + roomId)
      console.log(data)
    })
  },


  JoinRoom: function () {
    let self = this
    if (document.getElementById('roomid').value) {
      roomId = parseInt(document.getElementById('roomid').value)
    }
    sessionStorage.setItem('roomid', roomId)
    console.log('joinGame -- roomId=' + roomId)
    if (roomId && roomId > 100000 && roomId < 1000000) {
      window.gobang.joinGame(roomId, {
        value: '1000000000000000000'
      }).then(function (re) {
        // self.cleanChess()
        // self.drawChess()
        self.setStatus('Join game success')
        console.log('joinGame=============================')
        console.log(re)

        // clearTimeout(timeout)
        // timeout = setInterval(function () {
        //   self.getNewestState()
        // }, 1000)
      }).catch(function (e) {
        console.log(e)
        // self.setStatus('Error sending coin; see log.')
      })
    } else {
      self.setStatus('Room ID should be a 6-length number')
    }
  },
  refreshBalance: async function() {
    const { getBalance } = this.meta.methods;
    const balance = await getBalance(this.account).call();

    const balanceElement = document.getElementsByClassName("balance")[0];
    balanceElement.innerHTML = balance;
  },

  sendCoin: async function() {
    const amount = parseInt(document.getElementById("amount").value);
    const receiver = document.getElementById("receiver").value;

    this.setStatus("Initiating transaction... (please wait)");

    const { sendCoin } = this.meta.methods;
    await sendCoin(receiver, amount).send({ from: this.account });

    this.setStatus("Transaction complete!");
    this.refreshBalance();
  },

  setStatus: function(message) {
    const status = document.getElementById("status");
    status.innerHTML = message;
  },
};

window.App = App;

window.addEventListener("load", function() {
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
      new Web3.providers.HttpProvider("http://127.0.0.1:8545"),
    );
  }

  App.start();
});
