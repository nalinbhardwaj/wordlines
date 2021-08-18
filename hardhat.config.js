require('hardhat-circom');

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.6.7",
  circom: {
    inputBasePath: "./circuits",
    ptau: "pot15_final.ptau",
    circuits: [{ name: "main" }],
  },
};
