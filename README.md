# Cycle

Cycle is a crypto that uses matrix operations as the means of distribution. The main aim of Cycle is to distribute hefty calculations to a network of workers. The main use case of Cycle is executing convolutions for training nueral networks. It is well suited to convolutions because the heavy data reuse in the operation allows more work to be done with less data. It is built in two parts;

### Cycle Ethereum Smart Contract
The Ethereum Smart Contract is designed to work as a decentralized job manager and track the balances of users. Cycle SHOULD meet [ERC20 Token standards](https://theethereum.wiki/w/index.php/ERC20_Token_Standard) for all releases. 

#### Internals
For job distribution, Cycle uses a FIFO queue that feeds into a pool of active jobs. Active jobs are distributed randomly as miners query for work. A job's lifetime ends after it has had 10 solutions submitted to it. After the last solution is submitted, a consensus is found to verify that the job was actually completed. All miners who arrive at the correct consesus recieve Cycle.

### Cycle Miner Software
The Cycle Miner Software is used by miners to retrieve work from the smart contract.
