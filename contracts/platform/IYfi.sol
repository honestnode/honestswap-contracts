pragma solidity 0.5.16;

interface IyToken {

    function withdraw(uint256 _shares) external;
    function deposit(uint256 _amount) external;

    function balance() external view returns (uint256);
}

//interface IyDAI {
//    function withdraw(uint256 _shares) external;
//    function deposit(uint256 _amount) external;
//    function balance() external view returns (uint256);
//}
//interface IyTUSD {
//    function withdraw(uint256 _shares) external;
//    function deposit(uint256 _amount) external;
//    function balance() external view returns (uint256);
//}
//interface IyUSDC {
//    function withdraw(uint256 _shares) external;
//    function deposit(uint256 _amount) external;
//    function balance() external view returns (uint256);
//}
//interface IyUSDT {
//    function withdraw(uint256 _shares) external;
//    function deposit(uint256 _amount) external;
//    function balance() external view returns (uint256);
//}

//interface IyUSDT {
//
//    function withdraw(uint256 _shares) external;
//    function deposit(uint256 _amount) external;
//
//    function balance() external view returns (uint256);
//    function balanceDydx() external view returns (uint256);
//    function balanceCompound() external view returns (uint256);
//    function balanceCompoundInToken() external view returns (uint256);
//    function balanceFulcrumInToken() external view returns (uint256);
//    function balanceFulcrum() external view returns (uint256);
//    function balanceAave() external view returns (uint256);
//
//    function recommend() external view returns (uint256);
//    function rebalance() external;
//
//    function calcPoolValueInToken() external view returns (uint256);
//    function getPricePerFullShare() external view returns (uint256);
//}
