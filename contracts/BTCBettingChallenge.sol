pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// import "./aionInterface.sol";

contract BTCBettingChallenge {
    /* Constructor function */
    constructor() public {
        owner = msg.sender;
    }

    uint256 public totalBalance;
    
    ERC20 _token = ERC20(0x2d7882beDcbfDDce29Ba99965dd3cdF7fcB10A1e);
    AggregatorV3Interface priceFeed = AggregatorV3Interface(0x007A22900a3B98143368Bd5906f8E17e9867581b);

    address public owner;
    
    uint constant WIN = 1;
    uint constant LOSE = 2;
    uint constant TIE = 3;
    uint constant PENDING = 4;

    uint constant BET_CREATED = 5;
    uint constant BET_IN_PROGRESS = 6;
    uint constant BET_COMPLETE = 7;
    // uint constant BET_ERROR = 8;

    struct Gambler {
        address accnt; // Bet created By
        uint btcPrediction; // Predicted BTC value
        uint status;
    }

    struct Bet {
        uint betForTimestamp; // Bet for the BTC price on a timestamp in seconds (UTC)
        uint betPrice; // How much bet is for in USDC
        uint status; // Status
        Gambler gamblerA;
        Gambler gamblerB;
    }

    Bet public bet;

    modifier ownerOnly {
        require(msg.sender == owner, "Owner Only Call");
        _;
    }
    
    modifier isValidAddress {
        require(msg.sender != address(0), "Address can not be zero");
        _;
    }


    function chooseWinner () public
    ownerOnly
    returns (bool) {
            require(bet.gamblerA.status == PENDING, "Gambler A should be in PENDING status");
            require(bet.gamblerB.status == PENDING, "Gambler B should be in PENDING status");

            int256 price = getThePrice();

                // If Bet was not challeged, Send the bet back to creator
                if(bet.status == BET_CREATED){
                    bet.gamblerA.status=WIN;
                    transfer(bet.gamblerA.accnt , bet.betPrice);
                }
                // If bet was challeged, compare the price and select the nearest value as winner
                if(bet.status == BET_IN_PROGRESS){
                    // If tied, split the bet and send to both creator and challenger
                    int256 gamblerAResult = abs(int(price) - int(bet.gamblerA.btcPrediction));
                    int256 gamblerBResult = abs(int(price) - int(bet.gamblerB.btcPrediction));
                    if(gamblerAResult == gamblerBResult){
                        bet.gamblerA.status=TIE;
                        bet.gamblerB.status=TIE;
                        transfer(bet.gamblerA.accnt , bet.betPrice);
                        transfer(bet.gamblerB.accnt , bet.betPrice);
                    }
                    // If winner, send the whole bet to winner
                    else{
                        Gambler memory winner;
                        Gambler memory looser;
                        if(gamblerAResult < gamblerBResult){
                            winner = bet.gamblerA;
                            looser = bet.gamblerB;
                            bet.gamblerA.status = WIN;
                            bet.gamblerB.status = LOSE;
                        }
                        else if(gamblerBResult < gamblerAResult){
                            winner = bet.gamblerB;
                            looser = bet.gamblerA;
                            bet.gamblerB.status = WIN;
                            bet.gamblerA.status = LOSE;
                        }
                        transfer(winner.accnt , bet.betPrice * 2);
                    }
                }
                
                bet.status=  BET_COMPLETE;
                return true;
    }

    function challengeBet (uint256 prediction) public
    isValidAddress
    payable returns(bool) {
        require(bet.status == BET_CREATED, "Bet should be in BET_CREATED status");
        require(bet.gamblerA.btcPrediction != prediction, "Prediction can not be equal"); // Must be either higher or lower than the creator prediction
        require(address(bet.gamblerA.accnt) != address(msg.sender), "Creator and Challenger should be different");
        bet.gamblerB = Gambler(msg.sender, prediction, PENDING);
        accept(bet.betPrice);
        bet.status = BET_IN_PROGRESS;
    }

    function createBet (uint timestamp, uint prediction, uint betPrice) public
    isValidAddress
    payable returns(bool) {
            require(betPrice != 0, "Bet can not be zero price");
            bet = Bet(
                timestamp,
                betPrice,
                BET_CREATED, 
                Gambler(msg.sender, prediction, PENDING),
                Gambler(address(0), 0, PENDING));
            accept(betPrice);

    }

    function getThePrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
    


  function accept(uint _amount) internal returns (uint) {
    _token.transferFrom(msg.sender, address(this), _amount);
    totalBalance += _amount;
    return _token.balanceOf(msg.sender);
  }

  function transfer(address to, uint _amount) internal returns(bool) {
    _token.transfer(to, _amount);
    totalBalance -= _amount;
    return true;
  }
  
    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

}