require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("@nomicfoundation/hardhat-ethers");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [{ version: "0.8.19" }, { version: "0.8.20" }],
  },

  namedAccounts: {
    deployer: {
      default: 0,
      1: 0, //(for sepolia),
      // 31337: 2 (for hardhat localhost),
    },
    // OR multiple users
    // users: {
    //   user1: ....
    // }
  },
};
