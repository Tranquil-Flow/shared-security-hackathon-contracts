// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

abstract contract ReentrancyGuard {
    bool private _locked;

    modifier nonReentrant() {
        require(!_locked, "Reentrant call");
        _locked = true;
        _;
        _locked = false;
    }
}

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

// TODO: Implement Fees for Auctions
// TODO: Implement Rewards for Attestors

/// @title AuctionReward
/// @author Tranquil-Flow
/// @notice A contract for P2P transferring of tokens across multiple chains using Dutch Auctions
/// @dev Verification of auctions is done by AVS attestors
contract AuctionReward is ReentrancyGuard {
    /// @notice Struct for created auctions
    struct CreatedAuction {
        bool auctionOpen;            // True = Auction is open, False = Auction is closed
        address seller;              // Address of the auction creator
        address buyer;               // Address of the auction buyer
        address tokenForSale;        // Token being sold on auctionChainID
        address tokenForPayment;     // Token address being used as payment on acceptingOfferChainID
        uint amountForSale;          // Amount of tokenForSale being sold
        uint startingPrice;          // Starting price of the auction in token amount of tokenForPayment
        uint endPrice;               // Ending price of the auction in token amount of tokenForPayment
        uint startAt;                // Timestamp of when the auction started
        uint expiresAt;              // Timestamp of when the auction ends
        uint auctionChainID;         // Chain ID of where the auction is created
        uint acceptingOfferChainID;  // Chain ID of where the auction is accepted
    }
    
    uint public createdAuctionCounter;
    mapping(uint => CreatedAuction) public createdAuctions;

    /// @notice Struct for auction acceptance offers
    struct AcceptedAuction {
        bool auctionAccepted;        // True = Auction offer is finalized, False = Auction offer is not finalized
        uint auctionId;              // Auction ID of the accepted auction
        uint createdAuctionChainId;  // Chain ID of where the created auction is
        address seller;              // Address of the auction seller
        address buyer;               // Address of the auction buyer
        address tokenForAccepting;   // Token being used as payment to accept auction
        uint amountPaying;           // Amount of tokenForAccepting being paid
        uint acceptOfferTimestamp;   // Timestamp of when the auction was accepted
    }
    
    uint public acceptanceCounter;
    mapping(uint => AcceptedAuction) public acceptedAuctions;

    /// @notice Mapping to check if an offer has been made for an auction (only 1 offer allowed per auction)
    mapping(uint => mapping(uint => bool)) public offerMade;

    event AuctionCreated(
        uint indexed auctionId,
        address seller,
        address tokenForSale,
        address tokenForPayment,
        uint amountForSale,
        uint startingPrice,
        uint endPrice,
        uint startAt,
        uint expiresAt,
        uint indexed auctionChainId,
        uint indexed acceptingOfferChainId
    );
    event AuctionAccepted(
        uint indexed acceptanceId,
        uint indexed auctionId,
        uint indexed createdAuctionChainId,
        address buyer,
        address tokenForAccepting,
        uint amountPaying,
        uint acceptOfferTimestamp
    );
    event AuctionResumed(uint auctionId, uint createdAuctionChainId);
    event AuctionClosed(uint auctionId, address buyer, address tokenForSale, uint amountForSale);
    event OfferFinalized(uint acceptanceId, address seller, address tokenForAccepting, uint amountPaying);
    event ExpiredAuctionWithdraw(uint auctionId, address seller, address tokenForSale, uint amountForSale);
    event FailedOfferWithdraw(uint acceptanceId, address buyer, address tokenForAccepting, uint amountPaying);

    error InvalidPriceRange();
    error InsufficientTokensForSale();
    error InvalidAuctionID();
    error OfferAlreadyMade(uint auctionId, uint chainId);
    error NoOfferMade(uint auctionId, uint chainId);
    error OfferAlreadyFinalized(uint acceptanceId);
    error AuctionAlreadyClosed(uint auctionId);
    error AuctionExpired(uint auctionId);
    error AuctionNotExpired(uint _auctionId);
    error UnauthorizedWithdrawal(uint _auctionId, address _withdrawer);
    error InsufficientAllowance();

    constructor() {
    }

    /// @notice Sets up a Dutch auction
    /// @dev Param inputs defined in documentation of CreatedAuction struct
    function createAuction(
        address _tokenForSale,
        address _tokenForPayment,
        uint _startingPrice,
        uint _endPrice,
        uint _duration,
        uint _amountForSale,
        uint _auctionChainID,
        uint _acceptingOfferChainID
    ) external nonReentrant {
        // Check if the starting price is greater than the end price
        if (_startingPrice < _endPrice) {
            revert InvalidPriceRange();
        }

        // Check if the seller has enough tokens to sell
        if (IERC20(_tokenForSale).balanceOf(msg.sender) < _amountForSale) {
            revert InsufficientTokensForSale();
        }

        // Check if the contract has enough allowance to transfer the tokens, if not, approve the contract to transfer the tokens
        if (IERC20(_tokenForSale).allowance(msg.sender, address(this)) < _amountForSale) {
            bool success = IERC20(_tokenForSale).approve(address(this), _amountForSale);
            if (!success) {
                revert InsufficientAllowance();
            }
        }

        // Transfer the tokens to the contract
        IERC20(_tokenForSale).transferFrom(msg.sender, address(this), _amountForSale);
        uint timeNow = block.timestamp;
        uint createdAuctionID = createdAuctionCounter;

        // Create the auction
        createdAuctions[createdAuctionID] = CreatedAuction({
            auctionOpen: true,
            seller: msg.sender,
            buyer: address(0),
            tokenForSale: _tokenForSale,
            tokenForPayment: _tokenForPayment,
            amountForSale: _amountForSale,
            startingPrice: _startingPrice,
            endPrice: _endPrice,
            startAt: timeNow,
            expiresAt: timeNow + _duration,
            auctionChainID: _auctionChainID,
            acceptingOfferChainID: _acceptingOfferChainID
        });

        // Increment the auction counter
        createdAuctionCounter++;

        emit AuctionCreated(
            createdAuctionID,
            msg.sender,
            _tokenForSale,
            _tokenForPayment,
            _amountForSale,
            _startingPrice,
            _endPrice,
            timeNow,
            timeNow + _duration,
            _auctionChainID,
            _acceptingOfferChainID
        );
    }

    /// @notice Accepts an auction that has been created on another chain
    /// @dev Param inputs defined in documentation of AcceptedAuction struct
    function acceptAuction(
        uint _auctionId,
        uint _createdAuctionChainId,
        address _tokenForAccepting,
        uint _amountPaying
        ) external nonReentrant {
        // Check if an offer has already been made for the auction
        if (offerMade[_auctionId][_createdAuctionChainId]) {
            revert OfferAlreadyMade(_auctionId, _createdAuctionChainId);
        }

        // Check if the contract has enough allowance to transfer the tokens, if not, approve the contract to transfer the tokens
        if (IERC20(_tokenForAccepting).allowance(msg.sender, address(this)) < _amountPaying) {
            bool success = IERC20(_tokenForAccepting).approve(address(this), _amountPaying);
            if (!success) {
                revert InsufficientAllowance();
            }
        }

        // Transfer the tokens to the contract
        IERC20(_tokenForAccepting).transferFrom(msg.sender, address(this), _amountPaying);
        uint timeNow = block.timestamp;
        uint acceptedOfferID = acceptanceCounter;

        // Create the acceptance offer
        acceptedAuctions[acceptedOfferID] = AcceptedAuction({
            auctionAccepted: false,
            auctionId: _auctionId,
            createdAuctionChainId: _createdAuctionChainId,
            seller: address(0),
            buyer: msg.sender,
            tokenForAccepting: _tokenForAccepting,
            amountPaying: _amountPaying,
            acceptOfferTimestamp: timeNow
        });
        
        // Increment the acceptance counter
        acceptanceCounter++;

        // Set the offer as made, so that no more offers can be made for the auction
        offerMade[_auctionId][_createdAuctionChainId] = true;
        
        emit AuctionAccepted(
            acceptedOfferID,
            _auctionId,
            _createdAuctionChainId,
            msg.sender,
            _tokenForAccepting,
            _amountPaying,
            timeNow
        );

    }

    /// @notice Resumes an auction if the proposed offer was determined to not be valid by AVS attestors
    /// @param _auctionId The ID of the auction
    /// @param _createdAuctionChainId The chain ID of the created auction
    function resumeAuction(uint _auctionId, uint _createdAuctionChainId) external {
        // Check if an offer has been made for the auction
        if (!offerMade[_auctionId][_createdAuctionChainId]) {
            revert NoOfferMade(_auctionId, _createdAuctionChainId);
        }

        // Set the offer as not made, so that a new offer can be made for the auction
        offerMade[_auctionId][_createdAuctionChainId] = false;

        emit AuctionResumed(_auctionId, _createdAuctionChainId);
    }

    /// @notice Closes an auction once a valid offer has been made and AVS attestors have validated the transaction
    /// @param _auctionId The ID of the auction
    /// @param _buyer The address of the buyer of the auction
    function closeAuction(uint _auctionId, address _buyer) external nonReentrant {
        CreatedAuction storage createdAuction = createdAuctions[_auctionId];
        
        // Check if the auction has expired
        if (createdAuction.expiresAt <= block.timestamp) {
            revert AuctionExpired(_auctionId);
        }

        // Check if the auction is already closed
        if (!createdAuction.auctionOpen) {
            revert AuctionAlreadyClosed(_auctionId);
        }
        
        // Set the auction as closed and set the buyer
        createdAuction.auctionOpen = false;
        createdAuction.buyer = _buyer;

        // Transfer the tokenForSale to the buyer
        IERC20(createdAuction.tokenForSale).transferFrom(address(this), _buyer, createdAuction.amountForSale);

        emit AuctionClosed(_auctionId, _buyer, createdAuction.tokenForSale, createdAuction.amountForSale);
    }

    /// @notice Finalizes an auction offer once the AVS attestors have validated the auction
    /// @param _acceptanceId The ID of the acceptance
    /// @param _seller The address of the seller of the auction
    function finalizeOffer(uint _acceptanceId, address _seller) external nonReentrant {
        AcceptedAuction storage acceptedAuction = acceptedAuctions[_acceptanceId];
        
        // Check if the offer has already been finalized
        if (acceptedAuction.auctionAccepted) {
            revert OfferAlreadyFinalized(_acceptanceId);
        }
        
        // Set the offer as finalized and set the seller
        acceptedAuction.auctionAccepted = true;
        acceptedAuction.seller = _seller;

        // Transfer the tokenForAccepting to the seller
        IERC20(acceptedAuction.tokenForAccepting).transferFrom(address(this), _seller, acceptedAuction.amountPaying);

        emit OfferFinalized(_acceptanceId, _seller, acceptedAuction.tokenForAccepting, acceptedAuction.amountPaying);
    }

    /// @notice Withdraws the tokenForSale from an expired auction
    /// @param _auctionId The ID of the auction
    function withdrawExpiredAuction(uint _auctionId) external nonReentrant {
        CreatedAuction storage createdAuction = createdAuctions[_auctionId];
        
        // Check if the auction has expired
        if (createdAuction.auctionOpen) {
            revert AuctionNotExpired(_auctionId);
        }
        
        // Check if the auction is already closed
        if (createdAuction.buyer != address(0)) {
            revert AuctionAlreadyClosed(_auctionId);
        }
        
        // Check if the seller is the one withdrawing
        if (createdAuction.seller != msg.sender) {
            revert UnauthorizedWithdrawal(_auctionId, msg.sender);
        }
        
        // Transfer the tokenForSale to the seller
        uint amountToWithdraw = createdAuction.amountForSale;
        IERC20(createdAuction.tokenForSale).transferFrom(address(this), msg.sender, amountToWithdraw);

        emit ExpiredAuctionWithdraw(_auctionId, msg.sender, createdAuction.tokenForSale, amountToWithdraw);
    }

    /// @notice Withdraws the tokenForAccepting from a failed offer acceptance
    /// @param _acceptanceId The ID of the acceptance offer
    function withdrawFailedOffer(uint _acceptanceId) external nonReentrant {
        AcceptedAuction storage acceptedAuction = acceptedAuctions[_acceptanceId];
        
        // Check if the offer has already been finalized
        if (acceptedAuction.auctionAccepted) {
            revert OfferAlreadyFinalized(_acceptanceId);
        }
        
        // Check if the buyer is the one withdrawing
        if (acceptedAuction.buyer != msg.sender) {
            revert UnauthorizedWithdrawal(_acceptanceId, msg.sender);
        }
        
        // Transfer the tokenForAccepting to the buyer
        uint amountToWithdraw = acceptedAuction.amountPaying;
        IERC20(acceptedAuction.tokenForAccepting).transferFrom(address(this), msg.sender, amountToWithdraw);

        emit FailedOfferWithdraw(_acceptanceId, msg.sender, acceptedAuction.tokenForAccepting, amountToWithdraw);
    }

    /// @notice Claims rewards for AVS attestors
    function claimRewards() external {
    }

    /// @notice Gets the current price of a created auction
    /// @param _auctionId The ID of the auction
    /// @return The current price of the auction in token amount of tokenForPayment
    function getPrice(uint _auctionId) public view returns (uint) {
        // Check if the auction ID is valid
        if (_auctionId >= createdAuctionCounter) {
            revert InvalidAuctionID();
        }

        CreatedAuction storage auction = createdAuctions[_auctionId];

        // Check if the auction has expired, if so, return the end price
        if (block.timestamp >= auction.expiresAt) {
            return auction.endPrice;
        }

        // Calculate the current price of the auction
        uint timeElapsed = block.timestamp - auction.startAt;
        uint priceDifference = auction.startingPrice - auction.endPrice;
        uint duration = auction.expiresAt - auction.startAt;
        uint discount = (priceDifference * timeElapsed) / duration;
        uint currentPrice = auction.startingPrice - discount;

        return currentPrice < auction.endPrice ? auction.endPrice : currentPrice;
    }

    /// @notice Gets the price of an auction at a specified timestamp
    /// @param _auctionId The ID of the auction
    /// @param _timestamp The timestamp to calculate the price at
    /// @return The price of the auction at the specified timestamp in token amount of tokenForPayment
    function getPriceAtTime(uint _auctionId, uint _timestamp) public view returns (uint) {
        // Check if the auction ID is valid
        if (_auctionId >= createdAuctionCounter) {
            revert InvalidAuctionID();
        }

        CreatedAuction storage auction = createdAuctions[_auctionId];

        // Check if the auction has not started yet, if so, return the starting price
        if (_timestamp <= auction.startAt) {
            return auction.startingPrice;
            // Check if the auction has expired, if so, return the end price
        } else if (_timestamp >= auction.expiresAt) {
            return auction.endPrice;
        } else {
            // Calculate the price of the auction at the specified timestamp
            uint timeElapsed = _timestamp - auction.startAt;
            uint priceDifference = auction.startingPrice - auction.endPrice;
            uint duration = auction.expiresAt - auction.startAt;
            uint discount = (priceDifference * timeElapsed) / duration;
            uint price = auction.startingPrice - discount;

            return price < auction.endPrice ? auction.endPrice : price;
        }
    }

    /// @notice Gets a created auctions information
    /// @param _auctionId The ID of the auction
    /// @return The auction information
    function getCreatedAuctionInfo(uint _auctionId) external view returns (CreatedAuction memory) {
        return createdAuctions[_auctionId];
    }

    /// @notice Gets an accepted auctions information
    /// @param _acceptanceId The ID of the acceptance
    /// @return The acceptance information
    function getAcceptedAuctionInfo(uint _acceptanceId) external view returns (AcceptedAuction memory) {
        return acceptedAuctions[_acceptanceId];
    }

}