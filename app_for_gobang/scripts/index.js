// Import the page's CSS. Webpack will know what to do with it.
import '../css/style.css'

// Import libraries we need.
import { default as Web3 } from 'web3'
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
import gobangArtifact from '../../build/contracts/Gobang.json'

// Gobang is our usable abstraction, which we'll use through the code below.
const Gobang = contract(gobangArtifact)

// The following code is simple to show off interacting with your contracts.
// As your needs grow you will likely need to change its form and structure.
// For application bootstrapping, check out window.addEventListener below.

let canvas = document.getElementById('chess')
let context = canvas.getContext('2d')
let isBlack = true // 判断该轮黑白棋落子权
let isMyTurn = false // 判断是否是当前用户落子
let playerTurn // 当前是谁的落子权利
let playStatus // 游戏状态：0-未开始，1-游戏中，2-已结束
let chessBoard = [] // 棋盘二维数组,存储棋盘信息
let roomId = 0
// let isPlaying = false // 是否正在进行游戏
// let timeout // 间隔请求状态的时间
let isFirstGameoverEvent = true

const App = {
  start: function () {
    let self = this
    // 初始化棋盘信息
    for (let i = 0; i < 15; i++) {
      chessBoard[i] = []
      for (let j = 0; j < 15; j++) {
        chessBoard[i][j] = 0
      }
    }

    // Bootstrap the Gobang abstraction for Use.
    Gobang.setProvider(web3.currentProvider)
    Gobang.defaults({
      from: web3.eth.accounts[0]
    })

    Gobang.deployed().then(function (instance) {
      window.gobang = instance
      console.log('gobang============================')
      console.log(window.gobang)

      const updateInfo = (error, result) => {
        if (!error) {
          self.getNewestState()
          console.log('OneStepEvent==========================')
          console.log(result)
        }
      }

      const winnerGetMoney = (error, result) => {
        if (!error && isFirstGameoverEvent) {
          console.log('GameOverEvent=========================')
          console.log(result)
          let winnerOder = parseInt(result.args.winner.toString())
          if (!(winnerOder - 1) === isBlack) {
            alert('you win the bet fund')
            self.getMyMoney(roomId)
          } else {
            alert('you lose the bet fund')
          }
          isFirstGameoverEvent = false
        }
      }

      const beginGobang = (error, result) => {
        if (!error) {
          self.cleanChess()
          self.drawChess()
          self.getNewestState()
          console.log('GameStartEvent=========================')
          console.log(result)
        }
      }

      instance.OneStep(updateInfo)
      instance.GameOver(winnerGetMoney)
      instance.GameStart(beginGobang)

      if (!roomId && sessionStorage.getItem('roomId')) {
        roomId = parseInt(sessionStorage.getItem('roomId'))
        document.getElementById('room_id').value = roomId
      }
      self.getNewestState(true)
    })
  },

  createRoom: function () {
    let self = this
    roomId = Math.floor(Math.random() * 900000 + 100000)
    sessionStorage.setItem('roomId', roomId)
    document.getElementById('room_id').value = roomId
    window.gobang.createRoom(roomId, {
      value: '1000000000000000000'
    }).then((data) => {
      self.setStatus('Create room success')
      console.log('createRoom -- roomId=' + roomId)
      console.log(data)
    })
  },

  joinGame: function () {
    let self = this
    if (document.getElementById('room_id').value) {
      roomId = parseInt(document.getElementById('room_id').value)
    }
    sessionStorage.setItem('roomId', roomId)
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
      self.setStatus('房间号需为6位数字')
    }
  },

  getNewestState: function (isFirst) {
    let self = this
    window.gobang.getNewestState(roomId) // { from: web3.eth.accounts[0] }
      .then(function (newestState) {
        console.log('getNewestState==========================')
        console.log(newestState)
        playerTurn = parseInt(newestState[0].toString())
        if (playerTurn === 0) {
          document.getElementById('creatRoom').style.display = 'block'
          document.getElementById('joinGame').style.display = 'block'
          // alert('请点击join game加入游戏')
          return
        }
        // else if (playerTurn === 2 && web3.eth.accounts[0] === newestState[1]) {
        //
        // }
        if (web3.eth.accounts[0] !== newestState[1] && web3.eth.accounts[0] !== newestState[2]) {
          alert('您不是棋手，无法比赛')
          return
        } else if (web3.eth.accounts[0] === newestState[1]) {
          isBlack = true
        } else if (web3.eth.accounts[0] === newestState[2]) {
          isBlack = false
        }
        isMyTurn = !(playerTurn - 1) === isBlack
        playStatus = parseInt(newestState[3].toString())
        let chainChessboard = newestState[4]
        if (isFirst) {
          self.cleanChess()
          self.drawChess()
        }
        for (let i = 0; i < 15; i++) {
          chessBoard[i] = []
          for (let j = 0; j < 15; j++) {
            chessBoard[i][j] = parseInt(chainChessboard[i][j].toString())
            if (chessBoard[i][j]) {
              self.drawChessPiece(i, j, !(chessBoard[i][j] - 1))
            }
          }
        }
      }).catch(function (e) {
        console.log(e)
      // self.setStatus('Error sending coin; see log.')
      })
  },

  setStatus: function (message) {
    const status = document.getElementById('status')
    status.innerHTML = message
  },

  /**
   * 清除棋盘
   */
  cleanChess: function () {
    context.fillStyle = '#FFFFFF'
    context.fillRect(0, 0, canvas.width, canvas.height)
  },

  /**
   * 绘制棋盘
   */
  drawChess: function () {
    for (let i = 0; i < 15; i++) {
      context.strokeStyle = '#BFBFBF'
      context.beginPath()
      context.moveTo(15 + i * 30, 15)
      context.lineTo(15 + i * 30, canvas.height - 15)
      context.closePath()
      context.stroke()
      context.beginPath()
      context.moveTo(15, 15 + i * 30)
      context.lineTo(canvas.width - 15, 15 + i * 30)
      context.closePath()
      context.stroke()
    }
  },

  /**
   * 绘制棋子
   * @param i     棋子x轴位置
   * @param j     棋子y轴位置
   * @param isBlack    棋子颜色
   */
  oneStep: function (i, j, isBlack) {
    // this.getNewestState()
    if (chessBoard[i][j] === 0 && isMyTurn) {
      window.gobang.oneStep(i, j, roomId).then((data) => {
        console.log('oneStepData===============')
        console.log(data)
        this.drawChessPiece(i, j, isBlack)
      })
      isMyTurn = false
    }
  },

  // 绘制棋子
  drawChessPiece: function (i, j, isBlack) {
    context.beginPath()
    context.arc(15 + i * 30, 15 + j * 30, 13, 0, 2 * Math.PI)
    context.closePath()
    let gradient = context.createRadialGradient(15 + i * 30 + 2, 15 + j * 30 - 2,
      13, 15 + i * 30 + 2, 15 + j * 30 - 2, 0)
    if (isBlack) {
      gradient.addColorStop(0, '#0A0A0A')
      gradient.addColorStop(1, '#636766')
    } else {
      gradient.addColorStop(0, '#D1D1D1')
      gradient.addColorStop(1, '#F9F9F9')
    }
    context.fillStyle = gradient
    context.fill()
  },

  // 胜利玩家获取游戏奖励
  getMyMoney: function () {
    window.gobang.getMyMoney(roomId) // { from: web3.eth.accounts[0] }
      .then(function (re) {
        console.log('getMyMoney=========================')
        console.log(re)
      }).catch((err) => {
        console.log(err)
      })
  }
}

window.App = App

window.addEventListener('load', function () {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn(
      'Using web3 detected from external source.' +
      ' If you find that your accounts don\'t appear or you have 0 Gobang,' +
      ' ensure you\'ve configured that source properly.' +
      ' If using MetaMask, see the following link.' +
      ' Feel free to delete this warning. :)' +
      ' http://truffleframework.com/tutorials/truffle-and-metamask'
    )
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider)
  } else {
    console.warn(
      'No web3 detected. Falling back to http://127.0.0.1:9545.' +
      ' You should remove this fallback when you deploy live, as it\'s inherently insecure.' +
      ' Consider switching to Metamask for development.' +
      ' More info here: http://truffleframework.com/tutorials/truffle-and-metamask'
    )
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:8545'))
  }

  App.start()
})

/**
 * canvas 鼠标点击事件
 * @param e
 */
canvas.onclick = function (e) {
  if (playStatus !== 1) {
    return
  }

  let x = e.offsetX
  let y = e.offsetY
  let i = Math.floor(x / 30)
  let j = Math.floor(y / 30)

  // 如果该位置没有棋子,则允许落子
  if (chessBoard[i][j] === 0 && isMyTurn) {
    // 绘制棋子(玩家)
    App.oneStep(i, j, isBlack)
    // 改变棋盘信息(该位置有棋子)
    chessBoard[i][j] = playerTurn
  }
}
