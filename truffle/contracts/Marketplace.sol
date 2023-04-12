// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Marketplace {

  //Firstly we are going to have a structure for the products that the sellers sell
  struct product{
    //Now the product should have the following things
    uint price;
    string description;
    address payable seller;
    address payable highestbidder;
    int startdate;
    uint productId;
    int enddate;
    bool bidover;
    bool delivered;
    bool sold;
  }

  //This is the array that will store all the products that are registered by the seller
  product[] public registered;

  //This is the address of the delivery agency which is delivering the product
  address public agent;

  //Initally as we have no products available with us the productId will start from 0 and will keep on increasing as more products are
  //registered
  uint public count=0;

  //Here we are going to have a mapping which maps the productid with the number of bidders for the product
  mapping(uint=>mapping(address=>uint)) public totalbidders;

  //This address is the manager of the smart contract
  address payable public  manager;

  constructor(address sender,address _agent)
  {
    manager=payable(sender);
    agent=_agent;
  }

  //These are some of the events that are emitted once the function is successfully executed
  event productregistered(uint productId,uint price,string description,address payable seller);
  event bidmade(uint productId,address payable buyer);
  event outfordelivery(uint productId,uint finalprice,address buyer);
  event delivered(uint productId,address buyer,address seller);

  //In case some hacker got into the smart contract and the contract got compromised then in that case all the ethers from the contract
  //will be sent back again to the manager
  modifier manageronly{
    require(msg.sender==manager,"Only the manager can destroy the smart contract");
    _;
  }
  
  function destroy() public manageronly{
    manager.transfer(address(this).balance);
  }

  //Now we are creating a function where the seller registers their respective products in the marketplace
  function registerproduct(uint _price,string memory _description) public{
    //Here we are going to have a require function which checks whether the price that the user entered in ethers is greater than 0
    require(_price>0,"The price of the product cannot be less than or equal to 0");
    product memory temp;
    temp.price=_price;
    temp.description=_description;
    temp.seller=payable(msg.sender);
    temp.productId=count;
    count++;

    //This means that the start time is the time when the product is registered
    //And the end time is the start time + some amount of time where bidding is allowed
    temp.startdate=int(block.timestamp);
    temp.enddate=int(block.timestamp+10);
    registered.push(temp);

    //Hence this means that the product is now registered and thus the event can be emitted
    emit productregistered(count-1, _price, _description, payable(msg.sender));
  }

  //Now this is the function which checks whether the time for the bidding of the  given product is over or not
  //Hence this function returns the endtime - the current time
  function gettimeleft(uint _productId) public view returns(int)
  {
    int time=registered[_productId].enddate;
    return time-int(block.timestamp);
  }

  //This function returns the current time
  function getcurrentime() public view returns(uint)
  {
    return block.timestamp;
  }

  modifier bidpermitted(uint _productId){
    int timeleft=gettimeleft(_productId);
    if(timeleft>0)
    {
    }
    else{
      revert("The time for bidding on this product is now over");
    }
    _;
  }

  //Now this is the function where users bid for different products that are registered by the buyers
  function bid(uint _productId,uint _price) public bidpermitted(_productId){
    //The first requirement is that the buyer cannot be the seller of the product
    require(msg.sender!=registered[_productId].seller,"The bidder cannot be the seller of the product");

    //The second requirement is that the price that the bidder puts should be atleast greater than the listing price
    require(_price>=registered[_productId].price,"You cannot bid for a price that is lower than the listed price");

    //Now after passing all these tests it is time to bid for the product
    if(totalbidders[_productId][registered[_productId].highestbidder]<=_price)
    {
      registered[_productId].highestbidder=payable(msg.sender);
    }
    totalbidders[_productId][msg.sender]=_price;

    //This means that the bid has now been made
    //The user doesn't know whether he/she has won the bid(they kind of know because the bidder can see the highest bid)

    emit bidmade(_productId,payable(msg.sender));
  }


  //This is the function which returns the highest bidder for the given product
  function highestbid(uint _productId) public view returns(address)
  {
    return registered[_productId].highestbidder;
  }

  //This is the function where we return the highest bidder of the product once the bid time is over
  function highestbidfinal(uint _productId) public view returns(address)
  {
    int timeleft=gettimeleft(_productId);
    if(timeleft<0)
    {
    }
    else{
      revert("The time for bidding on this product is not yet over hence the highest bidder wouldn't be declared");
    }
    //This function only returns the highest bidder of the product once the bid time has been over
    return registered[_productId].highestbidder;
  }

  //Hence now all the bids have been made and the highest bidder is assigned to the product once the time for the bidding gets over
  //Now it is the time for the highest bidder to pay the amount to the contract
  //This paid amount will remain with the contract till the time the product is actually delievered


  //Only the buyer of the product can initate the delivery
  function initiatedelivery(uint _productId) public payable{

    //Firstly we need to check whether the bidding period is over or not
    int timeleft=gettimeleft(_productId);
    if(timeleft>=0)
    {
      revert("The bidding period is not over");
    }
    //We need to check whether this function is called by the buyer of the smart contract or not
    require(msg.sender==registered[_productId].highestbidder,"Only the highest bidder can initate delivery");
    
    //Also we are checking whether the ethers sent are equal to the promised amount by the bidder
    require(msg.value==totalbidders[_productId][registered[_productId].highestbidder],"The ethers sent must be equal to the bid amount");

    registered[_productId].bidover=true;
    emit outfordelivery(_productId,msg.value,msg.sender);
  }

 //This function returns the balance of the smart contract
  function balanceOf() public view returns(uint)
  {
    return address(this).balance;
  }

  //Now the highest bidder has called the initiate delivery function 
  //Hence the delivery company delivers the product
  //This function is called by the delivery agent to confirm that the product has been delivered
  function deliveredproduct(uint _productId) external
  {
    require(registered[_productId].bidover==true,"The product is not yet out for delivery");
    require(msg.sender==agent,"Only the delivery agent can call this function");

    //This now transfers the amount to the seller's account
    registered[_productId].seller.transfer(totalbidders[_productId][registered[_productId].highestbidder]);
  }

  //This is the fallback function in case no function was called of the smart contract
  //The fallback function transfers the ethers back to the address that called the function
  fallback() external payable{
    payable(msg.sender).transfer(msg.value);
  }

}
