# OptionContract
This is a minimal code of a smart contract for trading cash settled call options.

## Deployment
The address deploying it throug `Option(uint256 max, uint256 p, uint256 s, uint256 d)` put on sale an amount `max` of options at a unitary price `p`, strike `s` and duration `d`. It must send to the contract as collateral `max * underlyingPrice * 0.1` where underlyingPrice is in this case the price of BTC converted in ETH. The price of the options can be changed before sale with the function `adjustPrice(uint256 p)`.

## Buying options
The function `buy(uint256 a)` buys an amount a of option contracts at the conditions specified in the smart contract. The option price is paid to the smart cotract. Once `buy(uint256 a)` is called no more trading can happen. The options expire after the specified duration (in seconds) has passed from when they were bought. The payoff of the option, that is `max(0, underlyingPrice-strike)` can be checked with `getValue()`.

## Exercising the option
Before expiration only the buyer can exercise the option with the funcion `exercise` and receive `min(max(0, underlyingPrice - strike), balanceOfContract)`. The remaining ETH balance of the contract is sent to the seller. 

After the expiration anyone can exercise the option with the previously described payoff. In principle,the seller is responsible for exercising it at expiration. However if this is not convenient to the seller he may refuse, this is why the buyer also has the possiblity of exercising the option. This mechanism ensures that if both the buyer and seller act in the optimal way, the option will be exercised precisely at expiration.  
