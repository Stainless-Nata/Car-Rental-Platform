const { deployments, getNamedAccounts } = require("hardhat");

module.exports = async function () {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  console.log("Deploying Contract.......");
  const CarRental = await deploy("CarRentalPlatform", {
    from: deployer,
    args: [],
    log: true,
  });
  console.log(deployer);
  console.log(`Contract deployed at: ${CarRental.address}`);
};

module.exports.tags = ["all", "CarRental"];
