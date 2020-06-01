# SJTU-EE357-project-BlockChain
SJTU-EE357计算机网络课程大作业，实现简单的智能合约应用

## Introduction

**区块链智能合约技术** 

a)研究导向：智能合约是区块链最为吸引商业界广泛关注的一个发展方向，请参考相关 资料，搭建公链或联盟链平台，部署并运行智能合约，了解智能合约的发展趋势。 

*b) 工程导向：智能合约可自动在区块链上执行，但其应用并不局限于处理交易。目前， 智能合约也被用于实现安全多方计算、实现简单的区块链小游戏等方向。请基于以太坊或联盟链平台，编写智能合约，并利用该智能合约实现除处理交易以外的功能（例如：简单的智能合约小游戏）。

联盟链的搭建可参考： https://hyperledger-fabric.readthedocs.io/en/release-1.4/whatis.html ；

智能合约的相关研究可参考 https://github.com/decrypto-org/blockchain-papers#general ；

以太坊的使用请参考：https://ethereum.org/ ；





# Configuration

- 18.04.2-Ubuntu x86_64 GNU/Linux 
- node.js	v12.17.0 
- npm	6.14.4 
- truffle	v5.1.28

# Issue

```bash
truffle init
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
✔ Preparing to download box
✖ Downloading
Unbox failed!
✖ Downloading
Unbox failed!
RequestError: Error: connect ECONNREFUSED 0.0.0.0:443
......
```

raw.githubusercontent.com 域名污染,see: https://bbs.huaweicloud.com/blogs/143682