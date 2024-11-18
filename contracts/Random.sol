// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Random is VRFConsumerBaseV2Plus, ERC721URIStorage {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        address currentWinner
    );

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
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
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 public callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2_5.MAX_NUM_WORDS.
    uint32 public numWords = 1;

    /**
     * HARDCODED FOR SEPOLIA
     * COORDINATOR: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
     */
    // address s_owner;

    constructor(
        uint256 subscriptionId
    )
        ERC721("Ticket", "TCK")
        VRFConsumerBaseV2Plus(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B)
    {
        s_subscriptionId = subscriptionId;
    }

    mapping(address => uint256) public ticketsMint;

    address public currentWinner;

    address[] public ticketOwners;
    uint ticketPrice = 0.00001 ether;
    uint256 id = 1;

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
    function randomWinner(
        bool enableNativePayment
    ) external onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
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

    //callback function used by vrf consumer base to provide random numbr request
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");

        s_requests[_requestId].fulfilled = true;
        //  uint  randomNumber = _randomWords[0];
        s_requests[_requestId].randomWords = new uint256[](_randomWords.length);
        for (uint256 i = 0; i < _randomWords.length; i++) {
            s_requests[_requestId].randomWords[i] = _randomWords[i];
            require(ticketOwners.length > 0, "No tickets minted yet");
            uint256 winnerIndex = _randomWords[0] % ticketOwners.length;

            currentWinner = ticketOwners[winnerIndex];
            emit RequestFulfilled(_requestId, _randomWords, currentWinner);
        }
    }

    function nftTransfer(uint _id) external {
        require(ownerOf(_id) == msg.sender, "You do not own this token");
        require(
            currentWinner != address(0) && ticketsMint[currentWinner] != 0,
            "Invalid address"
        );
        _transfer(msg.sender, currentWinner, _id);
        emit Transfered(currentWinner, _id);
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
//0xfD83D2b5DDf81350513071b7fb25Fb69d5dE29FA
