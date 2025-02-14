// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract Quiz{
    struct Quiz_item {
        uint id;
        string question;
        string answer;
        uint min_bet;
        uint max_bet;
    }
    
    mapping(uint => mapping(address => uint256)) public bets;
    uint public vault_balance;
    mapping(address => uint256) public reward;
    
    address public owner;
    Quiz_item[] private quizzes;

    constructor () {
        owner = msg.sender;
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    modifier checkBound(uint quizId) {
        require(quizId > 0 && quizId <= quizzes.length);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function addQuiz(Quiz_item memory q) public onlyOwner {
        quizzes.push(q);
    }

    function getAnswer(uint quizId) public view onlyOwner checkBound(quizId) returns (string memory){
        Quiz_item storage q = quizzes[quizId - 1];
        return q.answer;
    }

    function getQuiz(uint quizId) public view checkBound(quizId) returns (Quiz_item memory) {
        Quiz_item memory q = quizzes[quizId - 1];
        q.answer = '';
        return q;
    }

    function getQuizNum() public view returns (uint){
        return quizzes.length;
    }
    
    function betToPlay(uint quizId) public payable checkBound(quizId) {
        // console.log(msg.value / 1e18, msg.value);
        Quiz_item memory quiz = quizzes[quizId - 1];
        require(quiz.min_bet <= msg.value && msg.value <= quiz.max_bet);
        mapping(address => uint256) storage bet = bets[quizId - 1];
        require(bet[msg.sender] + msg.value <= quiz.max_bet);
        bet[msg.sender] += msg.value;
    }

    function solveQuiz(uint quizId, string memory ans) public checkBound(quizId) returns (bool) {
        Quiz_item memory quiz = quizzes[quizId - 1];
        mapping(address => uint256) storage bet = bets[quizId - 1];
        vault_balance += bet[msg.sender];
        if (keccak256(bytes(quiz.answer)) == keccak256(bytes(ans))) {
            reward[msg.sender] += bet[msg.sender] * 2;
            bet[msg.sender] = 0;
            return true;
        }
        bet[msg.sender] = 0;
        return false;
    }

    function claim() public {
        require(reward[msg.sender] > 0);
        uint256 value = reward[msg.sender];
        reward[msg.sender] = 0;
        payable(msg.sender).transfer(value);
    }

    receive() external payable {
        vault_balance += msg.value;
    }
}
