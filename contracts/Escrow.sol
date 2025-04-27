//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _id) external;
}

contract Escrow {
    address public nftAddress;
    address payable public seller;
    address public inspector;
    address public lender;

    mapping(uint256 => bool) public isListed;
    mapping(uint256 => uint256) public purchasePrice;
    mapping(uint256 => uint256) public escrowAmount;
    mapping(uint256 => address) public buyer;
    mapping(uint256 => bool) public inspectionPassed;
    mapping(uint256 => mapping(address => bool)) public approval;

    modifier onlySeller() {
        require(msg.sender == seller, "Only sender can call this method");
        _;
    }

    modifier onlyBuyer(uint256 _nftID) {
        require(msg.sender == buyer[_nftID], "Only buyer can call this method");
        _;
    }

    modifier payableEscrow(uint256 _nftID) {
        require(msg.value >= escrowAmount[_nftID], "Not enough escrow");
        _;
    }

    modifier onlyInspector() {
        require(msg.sender == inspector, "Only inspector can call this method");
        _;
    }

    modifier hasBuyerApproval(uint256 _nftID) {
        require(approval[_nftID][buyer[_nftID]] == true);
        _;
    }

    modifier hasSellerApproval(uint256 _nftID) {
        require(approval[_nftID][seller] == true);
        _;
    }

    modifier hasLenderApproval(uint256 _nftID) {
        require(approval[_nftID][lender] == true);
        _;
    }

    modifier hasPassedInspection(uint256 _nftID) {
        require(inspectionPassed[_nftID] == true);
        _;
    }

    modifier hasEnoughBalance(uint256 _nftID) {
        require(address(this).balance >= purchasePrice[_nftID]);
        _;
    }

    constructor(
        address _nftAddress,
        address payable _seller,
        address _inspector,
        address _lender
    ) {
        nftAddress = _nftAddress;
        seller = _seller;
        inspector = _inspector;
        lender = _lender;
    }

    function list(
        uint256 _nftID,
        address _buyer,
        uint256 _purchasePrice,
        uint256 _escrowAmount
    ) public payable onlySeller {
        // Transfer NFT from seller to this contract
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftID);

        isListed[_nftID] = true;
        purchasePrice[_nftID] = _purchasePrice;
        escrowAmount[_nftID] = _escrowAmount;
        buyer[_nftID] = _buyer;
    }

    // Put under contract (only buyer - payable escrow)
    function depositEarnest(
        uint256 _nftID
    ) public payable onlyBuyer(_nftID) payableEscrow(_nftID) {}

    // Update inspection status (only inspector)
    function updateInspectionStatus(
        uint256 _nftID,
        bool _passed
    ) public onlyInspector {
        inspectionPassed[_nftID] = _passed;
    }

    // Approve sale
    function approveSale(uint256 _nftID) public {
        approval[_nftID][msg.sender] = true;
    }

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function finalizeSale(
        uint256 _nftID
    )
        public
        hasBuyerApproval(_nftID)
        hasSellerApproval(_nftID)
        hasLenderApproval(_nftID)
        hasPassedInspection(_nftID)
        hasEnoughBalance(_nftID)
    {
        isListed[_nftID] = false;

        (bool success, ) = payable(seller).call{value: address(this).balance}(
            ""
        );
        require(success);

        IERC721(nftAddress).transferFrom(address(this), buyer[_nftID], _nftID);
    }

    function cancelSale(uint256 _nftID) public {
        if (inspectionPassed[_nftID] == false) {
            payable(buyer[_nftID]).transfer(address(this).balance);
        } else {
            payable(seller).transfer(address(this).balance);
        }
    }
}
