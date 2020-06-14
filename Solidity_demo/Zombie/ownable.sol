function createRandomZombie(name) {
  // 这将需要一段时间，所以在界面中告诉用户这一点
  // 事务被发送出去了
  $("#txStatus").text("正在区块链上创建僵尸，这将需要一会儿...");
  // 把事务发送到我们的合约:
  return cryptoZombies.methods.createRandomZombie(name)
  .send({ from: userAccount })
  .on("receipt", function(receipt) {
    $("#txStatus").text("成功生成了 " + name + "!");
    // 事务被区块链接受了，重新渲染界面
    getZombiesByOwner(userAccount).then(displayZombies);
  })
  .on("error", function(error) {
    // 告诉用户合约失败了
    $("#txStatus").text(error);
  });
}