pragma solidity ^0.4.23;

import "./usingOraclize.sol";
import "./HomeCreditInterface.sol";

contract borrower {
    address public borrower;

    function borrower() {
        borrower = msg.sender;
    }

    modifier onlyBorrower {
        require(msg.sender == borrower);
        _;
    }
}

contract admin {
    address public admin;

    function admin() {
        admin = address(0x13aacd3E5a85A12C48E1cE9Cc688A40A4184087D);
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    function transferOwnership(address newAdmin) onlyAdmin {
        if (newAdmin != address(0)) {
            admin = newAdmin;
        }
    }
}


pragma solidity ^ 0.4.21;

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
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}


contract HomeLoansToken is owned {
    using SafeMath
    for uint256;

    string public name;
    string public symbol;
    uint public decimals;
    uint256 public totalSupply;
  

    /// @dev Fix for the ERC20 short address attack http://vessenes.com/the-erc20-short-address-attack-explained/
    /// @param size payload size
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowed;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);



    function HomeLoansToken(
        uint256 initialSupply,
        string tokenName,
        uint decimalUnits,
        string tokenSymbol
    ) {
        owner = msg.sender;
        totalSupply = initialSupply.mul(10 ** decimalUnits);
        balanceOf[msg.sender] = totalSupply; // Give the creator half initial tokens
        name = tokenName; // Set the name for display purposes
        symbol = tokenSymbol; // Set the symbol for display purposes
        decimals = decimalUnits; // Amount of decimals for display purposes
    }


    /// @dev Tranfer tokens to address
    /// @param _to dest address
    /// @param _value tokens amount
    /// @return transfer result
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns(bool success) {
        require(_to != address(0));
        require(_value <= balanceOf[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }


    /// @dev Tranfer tokens from one address to other
    /// @param _from source address
    /// @param _to dest address
    /// @param _value tokens amount
    /// @return transfer result
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(2 * 32) returns(bool success) {
        require(_to != address(0));
        require(_value <= balanceOf[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /// @dev Destroy Tokens
    ///@param destroyAmount Count Token
    function destroyToken(uint256 destroyAmount) onlyOwner {
        destroyAmount = destroyAmount.mul(10 ** decimals);
        balanceOf[owner] = balanceOf[owner].sub(destroyAmount);
        totalSupply = totalSupply.sub(destroyAmount);

    }

    /// @dev Approve transfer
    /// @param _spender holder address
    /// @param _value tokens amount
    /// @return result
    function approve(address _spender, uint _value) returns(bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Token allowance
    /// @param _owner holder address
    /// @param _spender spender address
    /// @return remain amount
    function allowance(address _owner, address _spender) constant returns(uint remaining) {
        return allowed[_owner][_spender];
    }
}


contract HomeMainCreditContract is admin, HomeCreditInterface, usingOraclize {

    struct Credit{
        uint256 create;
        address borrower;
        uint256 allSum;
        int creditMonth;
        int256 creditPercent;
        uint256 creditMonthPay;
        uint256 amountSum;
        uint collectionEndTime;
        address creditAddress;
        contractStatus status;
        uint256 paySize;
    }
    

    mapping(address=>Credit) public contracts;

    mapping (address => mapping(address => Pay[])) public pays;
    
    event Payed(address borrower, address creditAddress, uint256 day, uint256 amout, bool isTime);

    event ChangeStatus(address creditAddress, contractStatus status);

    event LogInfo(string description);
    event LogPriceUpdate(uint256 price);

    uint256 public courseHome;
    string public URL;
 

    function HomeMainCreditContract() {
      
    }

    function update(uint delay) payable {
       
    }

    function __callback(bytes32 id, string result, bytes proof) public {
        require(msg.sender == oraclize_cbAddress());

        courseHome = parseInt(result, 18);
        emit LogPriceUpdate(courseHome);
        update(60);
    }
    
    function() payable{}

    function addCredit(uint256 create,
        address borrower,
        uint256 allSum,
        int  creditMonth,
        int256  creditPercent,
        uint256  creditMonthPay,
        uint256  amountSum,
        uint  collectionEndTime)
        {
            
        }

    function addPay(address borrower, uint256 day, uint256 amount, bool isTime, rating ratingPay){
      
    }

    function changeStatusAwait()
    {
    }

    function setActive() {
        
    }

    function closeContract(contractStatus status){
        
    }
}

contract HomeCreditContract is borrower,admin, usingOraclize, HomeCreditInterface {
    
    using SafeMath for uint256;
    
    struct Investor{
        uint256 amount;
        uint256 percent;
    }

    struct Job{
        contractJobs typeJob;
        bool isDone;
    }

    event Payed(uint256 day, uint256 amout, bool isTime);

    event AddInvestor(address investor, uint256 amount);

    event ChangeStatus(contractStatus status);

    event LogConstructorInitiated(string nextStep);

    event LogPriceUpdated(string price);

    event LogNewOraclizeQuery(string description);

    event SendInvestorCoin(address investor, uint256 amount);

    event Appraisal(bool status);

    event Insurance(bool status);
    

    Pay[] public pays;
    
    uint256 public allSum; //Сумма кредита

    int public creditMonth;

    int256 public creditPercent;

    uint256 public creditMonthPay;

    bool public isInsurance = false;

    bool public isAppraisal = false;

    uint256 public amountSumWithPercent = 0; //Сколько выплатил
    uint256 public amountSumWithoutPercent = 0;
    HomeLoansToken public token;
    address public guaranteefund = address(0x682d8562A1B8062F5EF9be2462990376BCc8f556);

    HomeMainCreditContract homeMainCreditContract;

    uint public collectionEndTime; //Когда закончится

    uint public activeContractDate; //Когда закончится

    uint256 public collectedSum; // Сколько собрали

    uint256 public initCourse;

    contractStatus public status;

    enum contractJobs {UpdatePrice, CheckPay, CheckIsEndedTime}

    mapping (address=>Investor) public investors;
    

    mapping (bytes32 => Job) public jobs;

    //TODO DEBUG
    address[] public investorArray;

    bool public isTime = true;
    int public OverdueDay = 0;
    bool private sendFund = false;
    


    function HomeCreditContract(uint256 allSumInit, uint256 period, int creditMonthInit, int256 creditPercentInit) payable{
        allSum = allSumInit;
        status = contractStatus.Wait;
        creditMonth = creditMonthInit;
        creditPercent = creditPercentInit/12;
        
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        collectionEndTime = now.add(period * 24 * 60 * 60);
        checkEndTimeJob(collectionEndTime);
        calculateMonthPay(creditMonth, allSumInit);

        token = HomeLoansToken(0xad1efe76955bc8bc4ce21c435b110d837a02a041);
        homeMainCreditContract = HomeMainCreditContract(0x761BdAC6f05d48eBFD9124Cd8824b4269a92354d);
        homeMainCreditContract.addCredit(now, msg.sender, allSum, creditMonth, creditPercentInit, creditMonthPay, 0, collectionEndTime);
        initCourse = uint256(homeMainCreditContract.courseHome());
    }

    function calculateMonthPay(int month, uint256 sum) internal
    {
        if(sum<=0) revert();
        int256 coefficient = int256(((creditPercent+10000))*10**18);
    
        for (int i=0;i<month-1;i++){
            coefficient = coefficient * int256(((creditPercent+10000))*10**14) / 10**18;
        }

        int256 creditMonthPay2 =  creditPercent * coefficient;
        creditMonthPay2 = creditMonthPay2/((coefficient - (10**22))/10**14);
        creditMonthPay2 = int256(sum)*creditMonthPay2/(10**18);
        creditMonthPay = uint256(creditMonthPay2);
    }

    function __callback(bytes32 myid, string result, bytes proof) {
        if (jobs[myid].isDone) revert();

        if (msg.sender != oraclize_cbAddress()) revert();

        if(jobs[myid].typeJob == contractJobs.CheckIsEndedTime){
            checkEndTime();
        }else if(jobs[myid].typeJob == contractJobs.CheckPay){
            if(status == contractStatus.Active){
                checkPay();
            }
        }

        jobs[myid].isDone=true;
    }

    function checkEndTime()
    {
        if (msg.sender != oraclize_cbAddress()) revert();
        if(isEndedTimeCollection() && status == contractStatus.Wait){
            if(collectedSum<allSum){
                for(uint i=0;i<investorArray.length;i++){
                    address addressInvestor = investorArray[i];
                    Investor investor = investors[addressInvestor];
                    if (!token.transfer(addressInvestor, investor.amount)) revert();
                    homeMainCreditContract.closeContract(contractStatus.Closed);
                }
                suicide(borrower);
            }
        }
    }

    function sendToken(uint256 _amount, address payAccount, bool isFund, bool isEvent){
        for(uint i=0;i<investorArray.length;i++){
                address addressInvestor = investorArray[i];
                Investor investor = investors[addressInvestor];
                uint256 amount = _amount.div(10000).mul(investor.percent);
                if (!token.transferFrom(payAccount, addressInvestor, amount)) revert();
                if(isFund) {
                    sendFund = true;
                }
                if(isEvent){
                    emit SendInvestorCoin(addressInvestor, amount);
                }
        }
    }
    
    function checkPay(){
        if (msg.sender != oraclize_cbAddress()) revert();
        setOverdue();

        if(OverdueDay>3){
            sendToken(creditMonthPay,guaranteefund,true,true);
            checkPayJob(29 days);
        }

        if(OverdueDay>91){
             sendToken(leftSum(),guaranteefund,true,true);
            homeMainCreditContract.closeContract(contractStatus.Closed);
        }

        if(OverdueDay<=0) {
             isTime = true;
             OverdueDay = 0;
             sendFund = false;
             checkPayJob(32 days);
        }
    }

    function setOverdue()
    {
        uint256 dayLastPay;
        if(pays.length == 0){
            dayLastPay =  now.sub(activeContractDate)/60/60/24-31;
        }else{
            Pay lastPay = pays[pays.length-1];
            dayLastPay =  now.sub(pays[pays.length-1].day)/60/60/24-31;
        }
        if(dayLastPay>0){
            OverdueDay = int(dayLastPay);
            isTime = false;
        }
    }

     function checkPayJob(uint delay) payable {
        if (oraclize_getPrice("URL") > this.balance) {

        } else {
            bytes32 queryId = oraclize_query(delay, "URL", "");
            Job memory job = Job(contractJobs.CheckPay, false);
            jobs[queryId] = job;
        }
    }


    function checkEndTimeJob(uint delay) payable {
        if (oraclize_getPrice("URL") > this.balance) {

        } else {
            bytes32 queryId = oraclize_query(delay, "URL", "");
            Job memory job = Job(contractJobs.CheckIsEndedTime, false);
            jobs[queryId] = job;
        }
    }

    function setToken(address tokenAddress) onlyAdmin {
        token = HomeLoansToken(tokenAddress);
    }

    function setHomeMainCreditContract(address mainContract) onlyAdmin{
        homeMainCreditContract = HomeMainCreditContract(mainContract);
    }

    function addPay() onlyBorrower{
        require(status == contractStatus.Active);
        require(isInsurance == true);
        require(isAppraisal == true);
        if(leftSum()<creditMonthPay){
            if (!token.transferFrom(msg.sender, guaranteefund, leftSum())) revert();    
            amountSumWithoutPercent = amountSumWithoutPercent.add(leftSum());
        }else{
            rating ratingPay = getRating(); 
            setOverdue();
            
            if(OverdueDay > 0){
                int256 overduePay = (int256(allSum)*OverdueDay*2)/1000;
                if (!token.transferFrom(msg.sender, guaranteefund, uint256(overduePay))) revert();
            }

            if(sendFund){
                if (!token.transferFrom(msg.sender, guaranteefund, creditMonthPay)) revert();    
            }else{
                pay(creditMonthPay);
            }
           
            pays.push(Pay(now, creditMonthPay, isTime, ratingPay));
            amountSumWithPercent = amountSumWithPercent.add(creditMonthPay);
            amountSumWithoutPercent = amountSumWithoutPercent.add(calculateAmount(creditMonthPay));
            Payed(now, creditMonthPay, isTime);
            homeMainCreditContract.addPay(borrower, now, creditMonthPay, isTime, ratingPay);
        }
        if(amountSumWithoutPercent>=allSum) {
             status=contractStatus.Finished;
             emit  ChangeStatus(contractStatus.Finished);
             homeMainCreditContract.closeContract(contractStatus.Finished);
        }
    }

    function getRating() returns (rating)
    {
        if(pays.length == 0) return rating.New;
        uint256 dayLastPay =  now.sub(pays[pays.length-1].day)/60/60/24;
        if(dayLastPay > 31 && dayLastPay<=61){
             return rating.Delat1to29;
        }else if(dayLastPay > 61 && dayLastPay<=91){
             return rating.Delay30to59;
        }else if(dayLastPay >91 && dayLastPay<=121){
             return rating.DelayMore120;
        }
        return rating.WithoutDelay;
    }

    function calculateAmount(uint256 amount) returns (uint256)
    {
        uint256 amountPercent = ((leftSum() * (uint256(creditPercent)*12)*31)/(100*365))/10**2;
        return uint256(amount)-amountPercent;
    }

    function addErlyPay(uint256 amountCoin) onlyBorrower
    {
        require(status == contractStatus.Active);
        require(isInsurance == true);
        require(isAppraisal == true);
        if(amountCoin<=creditMonthPay) revert();
         rating raingPay = getRating();
        if(calculateAmount(creditMonthPay).add(amountCoin)>leftSum()) {
            uint256 newAmount = leftSum();
            if(newAmount>amountCoin) revert();
            amountCoin = newAmount;
        }
         setOverdue();
         if(OverdueDay > 0){
                int256 overduePay = (int256(allSum)*OverdueDay*2)/1000;
                if (!token.transferFrom(msg.sender, guaranteefund, uint256(overduePay))) revert();
            }

         if(sendFund){
                if (!token.transferFrom(msg.sender, guaranteefund, creditMonthPay)) revert();    
        }else{
                pay(creditMonthPay);
        }
        
        pays.push(Pay(now, amountCoin, isTime, raingPay));
        amountSumWithPercent = amountSumWithPercent.add(amountCoin);
        amountSumWithoutPercent = amountSumWithoutPercent.add(calculateAmount(amountCoin));
        Payed(now, amountCoin, isTime);
        homeMainCreditContract.addPay(borrower, now, amountCoin, isTime, raingPay);

        if(amountSumWithPercent>=allSum) {
             status=contractStatus.Finished;
             emit  ChangeStatus(contractStatus.Finished);
             homeMainCreditContract.closeContract(contractStatus.Finished);
        }else{
            calculateMonthPay(creditMonth-int(pays.length), leftSum());
        }
    }

     function pay(uint256 amountCoin){
        uint256 lastCourseHome = uint256(homeMainCreditContract.courseHome());
        uint256 borrowerPay = amountCoin*((amountCoin*initCourse));
        borrowerPay = borrowerPay/(amountCoin*lastCourseHome);
        int256 guaranteefundPay = int256(amountCoin - borrowerPay);
        if(guaranteefundPay>=0){
            sendToken(borrowerPay,msg.sender,false,true);
        
            if(guaranteefundPay>0){
                  sendToken(uint256(guaranteefundPay),guaranteefund,false,true);
            }
        }else{
             sendToken(creditMonthPay,msg.sender,false,true);
            guaranteefundPay = int256(borrowerPay - amountCoin);
            if (!token.transferFrom(msg.sender, guaranteefund, uint256(guaranteefundPay))) revert();
        }
    }

    function addInvestors(uint256 amount) 
    {
        require(validPurchase());
        if(amount<=0) revert();
        if(collectedSum.add(amount)>allSum) {
            uint256 newAmount = allSum.sub(collectedSum);
            if(newAmount>amount) revert();
            amount = newAmount;
        }
        if (!token.transferFrom(msg.sender, this, amount)) revert();
        collectedSum = collectedSum.add(amount);
        if(investors[msg.sender].amount == 0){
            investorArray.push(msg.sender);
        }
       investors[msg.sender] = Investor(investors[msg.sender].amount.add(amount),amount.mul(10000).div(allSum));
       emit AddInvestor(msg.sender,amount);
       if(collectedSum>=allSum) {
            status = contractStatus.WaitApproved;
            emit ChangeStatus(contractStatus.WaitApproved);
       }
    }

    function validPurchase() internal constant returns (bool) {
		  bool withinPeriod = now < collectionEndTime;
		  bool isAll = allSum > collectedSum;
		  return withinPeriod && isAll;
	  }

    function isEndedTimeCollection() public constant returns (bool){
        return now > collectionEndTime;
    }

    function leftSum() public constant returns (uint256)
    {
        return allSum.sub(amountSumWithoutPercent);
    }

     function getPaysLength() public constant returns (uint) {
        return pays.length;
    }

    function getInvestorsLength() public constant returns (uint){
        return investorArray.length;
    }

    function setActive() onlyAdmin {
      require(status == contractStatus.WaitApproved);
      require(isInsurance == true);
      require(isAppraisal == true);
      if(!token.transfer(borrower, token.balanceOf(this))) revert();
      status = contractStatus.Active;
      homeMainCreditContract.setActive();
      activeContractDate = now;
      emit ChangeStatus(contractStatus.Active);
      checkPayJob(32 days);
    }

    function setAppraisal() onlyAdmin {
        require(status == contractStatus.WaitApproved);
        isAppraisal = true;
        emit Appraisal(true);
    }

    function setInsurance() onlyAdmin {
        require(status == contractStatus.WaitApproved);
        isInsurance = true;
        emit Insurance(true);
    }

    function closeCredit() onlyAdmin()
    {
        if(status==contractStatus.Closed) revert();
        if(status==contractStatus.Finished) revert();

         status = contractStatus.Closed;
         emit ChangeStatus(contractStatus.Closed);
         homeMainCreditContract.closeContract(HomeCreditInterface.contractStatus.Closed);
    }
    
    function() payable {
        
    }
}
