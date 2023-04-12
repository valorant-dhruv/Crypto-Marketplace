//This is the test file where we are writing the script to test the smart contract
const Marketplace = artifacts.require("Marketplace");

//Chai is an assertion library
const { assert, expect } = require("chai");

contract("Market place", (accounts) => {
  let marketplace = null;
  let owner;
  let acc1;
  let acc2;
  let acc3;
  let agent;

  //This is the before hook which creates an instance of the smart contract before all the test blocks are run
  before(async () => {
    marketplace = await Marketplace.deployed();
    owner = accounts[0];
    acc1 = accounts[1];
    acc2 = accounts[2];
    acc3 = accounts[3];
    agent = accounts[4];
  });

  //These are the test blocks
  it("Should return the registered product with perfect start and end time", async () => {
    //As there is a require inside the function we use the try catch block in case there is some error
    try {
      await marketplace.registerproduct(30, "Tablet", {
        from: acc1,
      });

      let final = await marketplace.registered(0);

      console.log(
        "This is the start time of the bid:",
        final.startdate.toString()
      );
      console.log("This is the end time of the bid", final.enddate.toString());
      assert.equal(final.startdate.toNumber(), final.enddate.toNumber() - 10);
    } catch (error) {
      assert(
        false,
        "Out of bounds error: The value passed is zero or negative"
      );
    }
  });

  //   it("Should return the time left for bidding on the product", async () => {
  //     let timeleft = await marketplace.gettimeleft(0);
  //     console.log(
  //       "The difference betweent the current time and the endtime:",
  //       timeleft.toString()
  //     );
  //     timeleft = await marketplace.getcurrentime();
  //     console.log("The current time is:", timeleft.toNumber());
  //   });

  //In this test block first we make a bid which becomes the higest bid and then after sometime the we again make a higher bid from other
  //account
  it("Should bid for the product and the bid should be the highest bid", async () => {
    try {
      let timeleft;
      function fnc() {
        return new Promise((resolve, reject) => {
          setTimeout(() => {
            resolve(2);
          }, 5000);
        });
      }
      let result = await fnc();
      let productId = 0;
      let price = 40;
      await marketplace.bid(productId, price, {
        from: acc2,
      });

      let highestbidder = await marketplace.highestbid(productId);
      assert.equal(highestbidder, acc2);

      await marketplace.bid(productId, price + 10, {
        from: acc3,
      });

      highestbidder = await marketplace.highestbid(productId);
      assert.equal(highestbidder, acc3);
    } catch (error) {
      assert(false, error.toString());
    }
  });

  //In this test block we are checking whether the highestbidder initiates the delivery
  it("The highest bidder should initate the delivery of the product", async () => {
    let productId = 0;
    function fnc() {
      return new Promise((resolve, reject) => {
        setTimeout(() => {
          resolve(2);
        }, 6000);
      });
    }
    let result = await fnc();
    try {
      await marketplace.initiatedelivery(productId, {
        from: acc3,
        value: 50,
      });
      //Now we need to check the balance of the smart contract
      //The balance must be equal to the amount that is paid
      let balance = await marketplace.balanceOf();
      assert.equal(50, balance.toNumber());
    } catch (error) {
      assert(false, error.toString());
    }
  });

  it("Should check whether the product is delivered and the funds are transferred to the seller of the product", async () => {
    //The balance of the seller before the sending of ethers
    //In this case the seller of the product is the acc1
    let beforebalance = await web3.eth.getBalance(acc1);
    let beforebalanceinethers = await web3.utils.fromWei(
      beforebalance,
      "ether"
    );
    console.log(
      "The balance of the seller in ether before ",
      beforebalanceinethers
    );
    //The delivery agent is calling this function to ensure that the product has been delivered
    try {
      await marketplace.deliveredproduct(0, {
        from: agent,
      });
      let afterbalance = await web3.eth.getBalance(acc1);
      let afterbalanceinethers = await web3.utils.fromWei(
        afterbalance,
        "ether"
      );
      console.log(
        "The balance of the seller in ether now is ",
        afterbalanceinethers
      );
      console.log(beforebalance);
      console.log(afterbalance);
      assert.equal(parseInt(beforebalance), parseInt(afterbalance) - 45);
    } catch (error) {
      assert(false, error.toString());
    }
  });
});
