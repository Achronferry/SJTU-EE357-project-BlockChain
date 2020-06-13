import '../styles/style.css'

import Web3 from "web3";
import monopolyArtifact from "../../build/contracts/Monopoly.json";

let roomId = 0

const App = {
  web3: null,
  account: null,
  monopoly: null,

  start: async function() {
    const { web3 } = this;

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

      // this.refreshBalance();
    } catch (error) {
      console.error("Could not connect to contract or chain.");
    }
  },

  refreshBalance: async function() {
    const { getBalance } = this.monopoly.methods;
    const balance = await getBalance(this.account).call();

    const balanceElement = document.getElementsByClassName("balance")[0];
    balanceElement.innerHTML = balance;
  },

  sendCoin: async function() {
    const amount = parseInt(document.getElementById("amount").value);
    const receiver = document.getElementById("receiver").value;

    this.setStatus("Initiating transaction... (please wait)");

    const { sendCoin } = this.monopoly.methods;
    await sendCoin(receiver, amount).send({ from: this.account });

    this.setStatus("Transaction complete!");
    this.refreshBalance();
  },

  setStatus: function(message) {
    const status = document.getElementById("status");
    status.innerHTML = message;
  },

  createRoom: async function () {
    roomId = Math.floor(Math.random() * 900000 + 100000)
    sessionStorage.setItem('roomId', roomId)
    document.getElementById('roomid').value = roomId
    const { createRoom } = this.monopoly.methods;
    await createRoom(roomId).send({ from: this.account });

    self.setStatus('Create room success')
    console.log('createRoom -- roomId=' + roomId)

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