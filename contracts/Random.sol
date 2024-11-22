// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;
import {ConfirmedOwner} from "@chainlink/contracts@1.2.0/src/v0.8/shared/access/ConfirmedOwner.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Random is VRFConsumerBaseV2Plus, ERC721URIStorage {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        address[] currentWinner
    );

    struct RequestStatus {
        bool fulfilled; // whether the request has been fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    // Your subscription ID.
    uint256 public s_subscriptionId;

    // Past request IDs.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    event Minted(address from, address to, uint tokenId);
    event Transfered(address to, uint id);
    bytes32 public keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    uint32 public callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2_5.MAX_NUM_WORDS.
    uint32 public numWords;

    constructor(
        uint256 subscriptionId
    )
        ERC721("Ticket", "TCK")
        VRFConsumerBaseV2Plus(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B)
    {
        s_subscriptionId = subscriptionId;
    }

    mapping(address => uint256) public ticketsMint;

    address[] public currentWinner;

    address[] public ticketOwners;
    uint ticketPrice = 0.00001 ether;
    uint256 public id = 1;

    function mintTicket(address _to, string memory _uri) public payable {
        require(ticketsMint[_to] == 0, " already owns a ticket");
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
    function randomWinner(
        uint32 _numOfWinners
    ) external onlyOwner returns (uint256 requestId) {
        require(ticketOwners.length > 1, "less ticket minted than required");
        require(
            _numOfWinners > 1 && _numOfWinners < ticketOwners.length,
            "Invalid number of winners"
        );
        numWords = _numOfWinners;
        // Will revert if subscription is not set and funded.
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);

        return requestId;
    }

    mapping(uint256 => bool) public winnerSelected;

    //callback function used by vrf consumer base to provide random numbr request
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        // require(ticketOwners.length > numWords, "less tickets minted than required");

        // Clear previous winners
        delete currentWinner;

        // Select winners using random numbers
        for (uint256 i = 0; i < numWords; i++) {
            uint256 index = _randomWords[i] % ticketOwners.length;

            while (winnerSelected[index]) {
                //check if already selected, it moves to the next
                index = (index + 1) % ticketOwners.length; // Ensure no duplicates
            }
            winnerSelected[index] = true;
            currentWinner.push(ticketOwners[index]);
        }

        emit RequestFulfilled(_requestId, _randomWords, currentWinner);
    }

    function nftTransfer(uint256[] calldata _ids) external {
        require(
            _ids.length == currentWinner.length,
            "Token IDs count must match winners count"
        );
        require(currentWinner.length > 0, "No winners selected");

        for (uint i = 0; i < currentWinner.length; i++) {
            address winner = currentWinner[i];
            uint tokenId = _ids[i];

            // require(ownerOf(tokenId) == msg.sender, "You do not own this token");
            require(winner != address(0), "Invalid winner address");

            // Transfer the token to the current winner
            _transfer(msg.sender, winner, tokenId);

            emit Transfered(winner, tokenId);
        }
    }

    // Get the list of current winners
    function getCurrentWinners() external view returns (address[] memory) {
        return currentWinner;
    }

    //provides the status of a randomness request.
    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

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
