const { deployments, getNamedAccounts } = require("hardhat");
const { assert } = require("chai");

describe("CarRentalPlatform", async function () {
  let deployer;
  let carRent, CarRental;

  beforeEach(async function () {
    deployer = (await getNamedAccounts()).deployer;
    console.log(deployer);
    await deployments.fixture(["all"]);

    carRent = await deployments.get("CarRentalPlatform", deployer);
    console.log(carRent.address);
    CarRental = await ethers.getContractAt(
      "CarRentalPlatform",
      carRent.address
    );
    console.log(CarRental.target);
  });

  describe("Adds Users and Cars", function () {
    it("adds users", async function () {
      const num = 0;
      await CarRental.addUser("David", "Chukwudi");
      const response = await CarRental.getUser(deployer);
      const tests = [deployer, "David", "Chukwudi"];
      console.log(response);
      console.log(tests);
      assert.equal(response, tests);
    });
    it("adds cars", async function () {
      await CarRental.addCar("ferrari", "The_Image", "100", "40000");
      const response = await CarRental.getCar(1);
      const tests = [1, "ferrari", "The_Image", 2, 100, 40000];
      console.log(response);
    });
  });

  // ----------------------
  describe("Checks out and Checks in Car", function () {
    it("Checks out car", async function () {
      console.log("Hey");
      const accounts = await ethers.getSigners();
      console.log("hi");
      const user2 = accounts[1];
      console.log(user2);
    });
  });
});
