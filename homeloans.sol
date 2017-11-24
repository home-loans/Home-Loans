pragma solidity ^0.4.14;

contract owned {
    address public owner;
 
    function owned() {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
 
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    require(assertion);
  }
}
 
 
contract HomeLoansToken is owned, SafeMath {
 
    uint public PRICE = 50;
    uint public exchangeRate = 41960;
    string public name;
    string public symbol;
    uint public decimals;
    uint256 public totalSupply;
    bool public release = false;
    
     /// @dev Fix for the ERC20 short address attack http://vessenes.com/the-erc20-short-address-attack-explained/
 /// @param size payload size
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }
 
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;
 
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
 
 

    function HomeLoansToken(
        uint256 initialSupply,
        string tokenName,
        uint decimalUnits,
        string tokenSymbol
    ){  balanceOf[this] = initialSupply*10**decimalUnits;            // Give the creator half initial tokens
        totalSupply = initialSupply*10**decimalUnits;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

 
    /// @dev Tranfer tokens to address
    /// @param _to dest address
    /// @param _value tokens amount
    /// @return transfer result
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success){
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }
 
 
     /// @dev Tranfer tokens from one address to other
    /// @param _from source address
    /// @param _to dest address
    /// @param _value tokens amount
    /// @return transfer result
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {          
        balanceOf[_from] -= _value;                      // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
 
    ///@dev Mint Token
    ///@param mintedAmount Count new Token
    function mint(uint256 mintedAmount) onlyOwner{
        mintedAmount *= 10**decimals;
        balanceOf[this] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
    }

    /// @dev Destroy Tokens
    ///@param destroyAmount Count Token
    function destroyToken(uint256 destroyAmount) onlyOwner{
         destroyAmount *= 10**decimals;
        balanceOf[this] -= destroyAmount;
        totalSupply -= destroyAmount;

    }
 
    /// @dev Change price for 1 tokens
    function setPrice(uint Price) onlyOwner {
        require(Price>0);
        PRICE = Price;
    }
    
    /// @dev Set status passing ICO
    function setRelease(bool Release){
        release = Release;
    }

    /// @dev Change ETH|USD Rate in Cents
    function setExchangeRate(uint ExchangeRate) onlyOwner {
        require(ExchangeRate > 0 );
        exchangeRate = ExchangeRate;
    }   

 
    function buy() payable {
        require(!release);
        var multiplier = 10 ** decimals;
        uint amount = safeMul(weiToUsdCents(msg.value), safeDiv(multiplier, PRICE));          
        require(balanceOf[this] > amount);              
        balanceOf[msg.sender] += amount;                  
        balanceOf[this] -= amount;                         
        Transfer(this, msg.sender, amount);       
    }

   /// @dev Wei value convert to USD cents according to current exchange rate
   /// @param weiValue wei value to convert
   /// @return USD cents equivalent of the wei value
   function weiToUsdCents(uint weiValue) private returns (uint) {
     return safeDiv(safeMul(weiValue, exchangeRate), 1e18);
   }
   
	
	function () payable {
        buy();     
	}
	
    /// @dev Approve transfer
    /// @param _spender holder address
    /// @param _value tokens amount
    /// @return result
    function approve(address _spender, uint _value) returns (bool success) {
        require ((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Token allowance
    /// @param _owner holder address
    /// @param _spender spender address
    /// @return remain amount
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    } 
 
    /// @dev Withdraw all owner
    function withdraw() onlyOwner{
        msg.sender.transfer(this.balance);
    }
}
