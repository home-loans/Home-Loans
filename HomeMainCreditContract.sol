import './HomeCreditInterface.sol';
import "./usingOraclize.sol";

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
    string public URL = "json(http://home-loans.io/wp-admin/admin-ajax.php?action=getCourse).usd";
 

    function HomeMainCreditContract() payable {
      
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        update(60);
    }

    function update(uint delay) payable {
         if (oraclize_getPrice("URL") > this.balance) {
            emit LogInfo("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit LogInfo("Oraclize query was sent, standing by for the answer..");

            // Using XPath to to fetch the right element in the JSON response
            oraclize_query(delay, "URL", URL);
        }
    }

    function __callback(bytes32 id, string result, bytes proof) public {
        require(msg.sender == oraclize_cbAddress());

        courseHome = parseInt(result, 18);
        emit LogPriceUpdate(courseHome);
        update(1 days);
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
            Credit memory credit = Credit(create, borrower, allSum, creditMonth, creditPercent, creditMonthPay, amountSum, collectionEndTime, msg.sender, contractStatus.Wait, 0);
            contracts[msg.sender] = credit;
        }

    function addPay(address borrower, uint256 day, uint256 amount, bool isTime, rating ratingPay){
        if(contracts[msg.sender].creditAddress != msg.sender) revert();
        if(contracts[msg.sender].status != contractStatus.Active) revert();
        if(contracts[msg.sender].borrower != borrower) revert();
        Pay memory pay = Pay(day, amount, isTime, ratingPay);
        pays[borrower][msg.sender].push(pay);

        contracts[msg.sender].paySize++;
        emit Payed(borrower, msg.sender, day, amount, isTime);
    }

    function changeStatusAwait()
    {
         if(contracts[msg.sender].creditAddress != msg.sender) revert();
         if(contracts[msg.sender].borrower == address(0)) revert();
         if(contracts[msg.sender].status == contractStatus.Active) revert();
         if(contracts[msg.sender].status == contractStatus.Finished) revert();
         if(contracts[msg.sender].status == contractStatus.Closed) revert();

        contracts[msg.sender].status = contractStatus.WaitApproved;

        emit ChangeStatus(msg.sender, contractStatus.WaitApproved);
    }

    function setActive() {
         if(contracts[msg.sender].creditAddress != msg.sender) revert();
         if(contracts[msg.sender].borrower == address(0)) revert();
         if(contracts[msg.sender].collectionEndTime < now) revert();
         if(contracts[msg.sender].status == contractStatus.Active) revert();
         
         contracts[msg.sender].status = contractStatus.Active;

        emit ChangeStatus(msg.sender, contractStatus.Active);
    }

    function closeContract(contractStatus status){
        if(contracts[msg.sender].creditAddress != msg.sender) revert();
        if(contracts[msg.sender].status == contractStatus.Finished) revert();
        if(contracts[msg.sender].status == contractStatus.Closed) revert();

        contracts[msg.sender].status=status;

        emit ChangeStatus(msg.sender, status);
    }
    
}
