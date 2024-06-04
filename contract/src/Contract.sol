// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import {IVRFCoordinatorV2Plus} from "@chainlink/contracts@1.1.1/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
// import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.1.1/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
// import {VRFV2PlusClient} from "@chainlink/contracts@1.1.1/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import { IVRFCoordinatorV2Plus } from "@chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";

struct ProbabilityItem {
    string name;
    uint256 p;
}

struct Rule {
    uint256 ruleId;
    address owner;
    ProbabilityItem[] lotteryProbabilities;
    uint256 createTime;
    bool available;
}

struct RequestStatus {
    bool fulfilled; // whether the request has been successfully fulfilled
    bool exists; // whether a requestId exists
    uint256[] randomWords;
    address user;
    uint256 ruleId;
    string reward;
}

struct Result {
    string reward;
    uint256 ruleId;
    uint256 randomWord;
    uint256 requestId;
}

contract Lottery is VRFConsumerBaseV2Plus {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords
    );
    event RewardSelected(address user, uint256 requestId, string reward);
    event ResultStored(address user, uint256 requestId, Result result);

    uint256 nextRuleId = 1;
    mapping(uint256 => Rule) ruleset;
    mapping(address => uint256[]) owner2rules;
    mapping(address => Result[]) user2results;

    Result[] allResults;

    bytes32 keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint256 internal fee;

    uint256 public lastRequestId;

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    // Your subscription ID.
    uint256 s_subscriptionId;

    uint32 callbackGasLimit = 400000;

    IVRFCoordinatorV2Plus COORDINATOR;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
    uint32 numWords = 1;

    // address WRAPPER - hardcoded for Sepolia
    address wrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

    constructor(
        uint256 subscriptionId
    )
        VRFConsumerBaseV2Plus(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B)
    {
        COORDINATOR = IVRFCoordinatorV2Plus(
            0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
        );
        s_subscriptionId = subscriptionId;

    }

    // rewardNames:  ["Phone", "Laptop", "Mouse", "Nothing, Damn!"]
    // rewardProbabilitis:  [20, 10, 30, 40]
    function createRule(
        string[] memory rewardNames,
        uint256[] memory rewardProbabilitis
    ) public returns (uint256) {
        require(rewardNames.length == rewardProbabilitis.length);
        uint256 totalProbability = 0;

        for (uint256 i = 0; i < rewardProbabilitis.length; i++) {
            if (bytes(rewardNames[i]).length == 0) {
                revert("Reward cannot be empty");
            }
            totalProbability += rewardProbabilitis[i]; 
        }

        require(
            totalProbability == 100,
            "The total probability should be 100!"
        );

        uint256 ruleId = nextRuleId++;
        ruleset[ruleId].ruleId = ruleId;
        ruleset[ruleId].owner = msg.sender;
        ruleset[ruleId].createTime = block.timestamp;
        ruleset[ruleId].available = true;

        for (uint256 i = 0; i < rewardProbabilitis.length; i++) {
            ProbabilityItem memory newItem = ProbabilityItem(
                rewardNames[i],
                rewardProbabilitis[i]
            );
            ruleset[ruleId].lotteryProbabilities.push(newItem);
        }

        owner2rules[msg.sender].push(ruleId);
        return ruleId;
    }

    function getRules() public view returns (uint256[] memory) {
        return owner2rules[msg.sender];
    }

    function getRule(uint256 ruleId) public view returns (Rule memory) {
        return ruleset[ruleId];
    }

    function select(uint256 randomResult, ProbabilityItem[] memory probabilities)
        external
        pure
        returns (string memory)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < probabilities.length; i++) {
            sum += probabilities[i].p;
            if (randomResult < sum) {
                return probabilities[i].name;
            }
        }

        return "";
    }

    function getReward(uint256 ruleId)
        external
        onlyOwner
        returns (uint256 requestId)
    {
        requestId = COORDINATOR.requestRandomWords(
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
            fulfilled: false,
            user: msg.sender,
            ruleId: ruleId,
            reward: ""
        });
        lastRequestId = requestId; 
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(
            _requestId,
            _randomWords
        );
        // this.pickReward(_requestId, _randomWords[0]);

        uint256 randomResult = _randomWords[0] % 100;
        // Use the random number to select a reward
        Rule storage rule = ruleset[s_requests[_requestId].ruleId];
        string memory reward = this.select(randomResult, rule.lotteryProbabilities);
        s_requests[_requestId].reward = reward;
        emit RewardSelected(s_requests[_requestId].user, _requestId, reward);
        user2results[s_requests[_requestId].user].push(Result({
            requestId: _requestId,
            randomWord: _randomWords[0],
            ruleId: rule.ruleId,
            reward: reward
        }));
    }

    function pickReward(uint256 _requestId, uint256 _randomWord) external  {
        uint256 randomResult = _randomWord % 100;
        // Use the random number to select a reward
        Rule storage rule = ruleset[s_requests[_requestId].ruleId];
        string memory reward = this.select(randomResult, rule.lotteryProbabilities);
        s_requests[_requestId].reward = reward;
        emit RewardSelected(s_requests[_requestId].user, _requestId, reward);
        user2results[s_requests[_requestId].user].push(Result({
            requestId: _requestId,
            randomWord: _randomWord,
            ruleId: rule.ruleId,
            reward: reward
        }));
        emit ResultStored(s_requests[_requestId].user, _requestId, Result({
            requestId: _requestId,
            randomWord: _randomWord,
            ruleId: rule.ruleId,
            reward: reward
        }));
        allResults.push(Result({
            requestId: _requestId,
            randomWord: _randomWord,
            ruleId: rule.ruleId,
            reward: reward
        }));
    }

    function getResults() public view returns(Result[] memory results) {
        return user2results[msg.sender];
    }

    function getLastResult() public view returns(Result memory result) {
        Result[] memory results = this.getResults();
        require(results.length > 0, "The current user has no lottery results");
        return results[results.length - 1];
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    fallback() external {
        revert("something wrong");
    }
}