// ==========================================================
//  BIPECOIN AI — ORACLE EXTENSION
//  Connects BIC to the World — Prices, Data, Intelligence
//  © 2026 Bipecoin — Built with Purpose & Truth
// ==========================================================
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BipecoinAI_Oracle {
    // ============= YOUR BIC TOKEN — ALREADY LOCKED IN =============
    address public constant BIC_ROOT = 0x7b72c5362aE7292570cD7BDdfa49652328a5Bc45;
    
    address public owner;
    address public aiOracle;
    
    struct OracleRequest {
        address requester;
        string question;
        string answer;
        bytes32 answerHash;
        uint256 timestamp;
        bool fulfilled;
        bool isWeb2;   // true = human chat / false = price & data
    }
    
    mapping(bytes32 => OracleRequest) public requests;
    mapping(address => bool) public approvedNodes;
    uint256 public totalRequests;

    // === EVENTS — Everyone sees the truth live ===
    event ChatRequested(bytes32 indexed id, address indexed user, string message);
    event DataRequested(bytes32 indexed id, address indexed user, string query);
    event AnswerFulfilled(bytes32 indexed id, string answer, bytes32 proof);
    event NodeApproved(address indexed node);

    // === PROTECTION — Only trusted eyes can write ===
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    modifier onlyOracle() {
        require(msg.sender == aiOracle || approvedNodes[msg.sender], "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
        aiOracle = msg.sender;
    }

    // ==========================================================
    //  ASK — Two ways to get answers
    // ==========================================================

    // 👤 For people: chat, questions, community messages
    function askChat(string memory _message) public returns (bytes32) {
        bytes32 id = keccak256(abi.encodePacked(
            block.timestamp, msg.sender, totalRequests, _message, "chat"
        ));
        requests[id] = OracleRequest({
            requester: msg.sender,
            question: _message,
            answer: "",
            answerHash: 0,
            timestamp: block.timestamp,
            fulfilled: false,
            isWeb2: true
        });
        totalRequests++;
        emit ChatRequested(id, msg.sender, _message);
        return id;
    }

    // 📊 For data: price, market stats, verification
    function getData(string memory _query) public returns (bytes32) {
        bytes32 id = keccak256(abi.encodePacked(
            block.timestamp, msg.sender, totalRequests, _query, "data"
        ));
        requests[id] = OracleRequest({
            requester: msg.sender,
            question: _query,
            answer: "",
            answerHash: 0,
            timestamp: block.timestamp,
            fulfilled: false,
            isWeb2: false
        });
        totalRequests++;
        emit DataRequested(id, msg.sender, _query);
        return id;
    }

    // ==========================================================
    //  ANSWER — The eyes see & write truth on chain
    // ==========================================================
    function giveAnswer(bytes32 _id, string memory _answer) public onlyOracle {
        require(!requests[_id].fulfilled, "Already answered");
        
        bytes32 proof = keccak256(abi.encodePacked(_answer, block.timestamp));
        requests[_id].answer = _answer;
        requests[_id].answerHash = proof;
        requests[_id].fulfilled = true;
        
        emit AnswerFulfilled(_id, _answer, proof);
    }

    // ==========================================================
    //  VERIFY — Anyone can check: truth or lie?
    // ==========================================================
    function isTruth(bytes32 _id, string memory _claimedAnswer) public view returns (bool) {
        bytes32 check = keccak256(abi.encodePacked(_claimedAnswer, requests[_id].timestamp));
        return check == requests[_id].answerHash;
    }

    // ==========================================================
    //  MANAGEMENT — Trusted eyes & handover
    // ==========================================================
    function setOracle(address _newOracle) public onlyOwner {
        aiOracle = _newOracle;
    }
    function addNode(address _node) public onlyOwner {
        approvedNodes[_node] = true;
        emit NodeApproved(_node);
    }
    function removeNode(address _node) public onlyOwner {
        approvedNodes[_node] = false;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    // === Read any request anytime ===
    function getRequest(bytes32 _id) public view returns (
        address, string memory, string memory, bool, uint256
    ) {
        OracleRequest storage r = requests[_id];
        return (r.requester, r.question, r.answer, r.fulfilled, r.timestamp);
    }
}
