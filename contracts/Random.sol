// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Random is VRFConsumerBaseV2, ERC721URIStorage {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256 randomWord);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256 randomWord;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    VRFCoordinatorV2Interface immutable COORDINATOR;

    uint64 immutable s_subscriptionId;

    bytes32 immutable s_keyHash;

    uint32 constant CALLBACK_GAS_LIMIT = 100000;

    uint16 constant REQUEST_CONFIRMATIONS = 3;

    uint32 constant NUM_WORDS = 1;

    // uint256[] public s_randomWords;

    uint256 public requestId;
    address s_owner;
    uint256[] public requestIds;
    uint256 public lastRequestId;

    event Minted(address from, address to, uint tokenId);
    event Transfered(address to, uint id);

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) ERC721("Ticket", "TCK") VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    mapping(address => uint256) public ticketsMint;

    address currentWinner;

    address[] public ticketOwners;
    uint ticketPrice = 0.000001 ether;
    uint256 id = 1;

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    function mintTicket(address _to, string memory _uri) public payable {
        require(_to != address(0), "invalid Address");
        require(msg.value >= ticketPrice, "Insufficient funds to redeem");

        _safeMint(_to, id);
        _setTokenURI(id, _uri);
        ticketsMint[_to] = id;
        ticketOwners.push(_to);
        emit Minted(msg.sender, _to, id);
        id++;
    }

    // Assumes the subscription is funded sufficiently.
    //Sends a request to the Chainlink VRF Oracle
    function randomWinner() external onlyOwner returns (uint256) {
        // requestId unique identifier for this randomness request
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash, //identifies which Chainlink VRF configuration to use.
            s_subscriptionId,
            REQUEST_CONFIRMATIONS, //Number of block confirmations to wait for additional security
            CALLBACK_GAS_LIMIT, // maximum gas limit for the callback function
            NUM_WORDS //number of random numbers requested
        );

        s_requests[requestId] = RequestStatus({
            randomWord: 0,
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, NUM_WORDS);

        return requestId;
    }

    //callback function used by vrf consumer base to provide random numbr request
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords // An array containing the random numbers provided by the VRF.
    ) internal virtual override {
        require(s_requests[requestId].exists, "request not found");
        s_requests[requestId].fulfilled = true;
        uint randomNumber = randomWords[0];
        s_requests[requestId].randomWord = randomNumber;
        emit RequestFulfilled(requestId, randomNumber);
        uint256 winnerIndex = randomNumber % ticketOwners.length;

        currentWinner = ticketOwners[winnerIndex];
    }

    function nftTransfer(uint _id) external {
        require(ownerOf(_id) == msg.sender, "You do not own this token");
        require(currentWinner != address(0), "Invalid address");
        _transfer(msg.sender, currentWinner, _id);
        emit Transfered(currentWinner, _id);
    }

    //provides the status of a randomness request.
    // function getRequestStatus(
    //     uint256 _requestId
    // ) external view returns (bool fulfilled, uint256 randomWord) {
    //     require(s_requests[_requestId].exists, "request not found");
    //     RequestStatus memory request = s_requests[_requestId];
    //     return (request.fulfilled, request.randomWord);
    // }

    //The following functions are overrides required by Solidity.
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

//retrieving random data, hashing it, and then collectively generating a random number
