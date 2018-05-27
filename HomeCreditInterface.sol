pragma solidity ^0.4.23;

contract HomeCreditInterface {
     struct Pay{
        uint256 day;
        uint256 amount;
        bool isTime;
        rating ratingPay;
    }

    enum contractStatus { Wait, WaitApproved, Active, Finished, Closed }

   enum rating {New, WithoutDelay, Delat1to29, Delay30to59, Delay60to89, DelayMore120, RCP, RofPbyP, BadDebt}
}
