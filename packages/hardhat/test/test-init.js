//  Init the test environment
const { ethers } = require('hardhat');

const initialize = async (accounts) => {
  const setup = {};
  setup.roles = {
    root: accounts[0],
    user1: accounts[1],
    user2: accounts[2]
  };

  return setup;
};

const token = async (setup, name, symbol) => {
  const tokenFactory = await ethers.getContractFactory("Token");
  let tokenContract = await tokenFactory.deploy(name, symbol);

  return tokenContract;
};

const basicCpmm = async (setup) => {
    const basicCpmmFactory = await ethers.getContractFactory("BasicCPMM");
    let basicCPMM = await basicCpmmFactory.deploy();

    return basicCPMM;
};

module.exports = {
  initialize,
  token,
  basicCpmm
}; 
