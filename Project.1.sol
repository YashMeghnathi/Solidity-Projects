// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    // Address of the contract admin
    address public admin;
    // Flag indicating if an election is ongoing
    bool public electionOngoing;
    // Structure to represent a candidate
    struct Candidate {
        uint256 id;             // Candidate's unique ID
        string name;           // Candidate's name
        string proposal;      // Candidate's proposal or platform
        uint256 voteCount;    // Number of votes the candidate has received
    }
    // Structure to represent a voter
    struct Voter {
        bool registered;      // Whether the voter is registered
        bool hasVoted;        // Whether the voter has voted
        uint256 votedCandidateId; // ID of the candidate the voter has voted for
        address delegateTo;   // Address to which voting rights are delegated
        bool voteDelegated;   // Whether the voter's rights have been delegated
    }
    // Mappings for storing candidates and voters
    mapping(uint256 => Candidate) public candidates;
    mapping(address => Voter) public voters;
    // Counter for tracking the number of candidates
    uint256 public candidateCount;
    // Events to log important actions
    event CandidateAdded(uint256 id, string name, string proposal);
    event VoterAdded(address voter);
    event ElectionStarted();
    event ElectionEnded();
    event VoteCasted(address voter, uint256 candidateId);
    event VoteDelegated(address from, address to);
    // Modifier to restrict access to the admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    // Modifier to ensure actions are performed only during an ongoing election
    modifier onlyDuringElection() {
        require(electionOngoing, "Election is not ongoing");
        _;
    }
    // Modifier to ensure a voter has not already voted
    modifier notVoted() {
        require(!voters[msg.sender].hasVoted, "You have already voted");
        _;
    }
    // Constructor to set the admin address
    constructor() {
        admin = msg.sender;
    }
    // Function to add a new candidate
    function addCandidate(string memory name, string memory proposal) public onlyAdmin {
        require(!electionOngoing, "Cannot add candidates during an election");
        candidateCount++;
        candidates[candidateCount] = Candidate(candidateCount, name, proposal, 0);
        emit CandidateAdded(candidateCount, name, proposal);
    }
    // Function to register a new voter
    function addVoter(address voter) public onlyAdmin {
        require(!electionOngoing, "Cannot add voters during an election");
        require(!voters[voter].registered, "Voter already registered");
        voters[voter].registered = true;
        emit VoterAdded(voter);
    }
    // Function to start the election
    function startElection() public onlyAdmin {
        require(!electionOngoing, "Election already started");
        electionOngoing = true;
        emit ElectionStarted();
    }
    // Function to get details of a specific candidate
    function getCandidate(uint256 candidateId) public view returns (
        uint256 id,
        string memory name,
        string memory proposal
    ) {
        Candidate memory candidate = candidates[candidateId]; // Correctly using memory
        return (candidate.id, candidate.name, candidate.proposal); // Returning the candidate details
    }
    // Function to get the details of the winning candidate
    function getWinner() public view returns (
        string memory name,
        uint256 id,
        uint256 voteCount
    ) {
        require(!electionOngoing, "Election is ongoing");
        uint256 winningCandidateId;
        uint256 highestVoteCount = 0;
        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].voteCount > highestVoteCount) {
                highestVoteCount = candidates[i].voteCount;
                winningCandidateId = i;
            }
        }
        Candidate memory winner = candidates[winningCandidateId];
        return (winner.name, winner.id, winner.voteCount);
    }
    // Function to delegate voting rights to another registered voter
    function delegateVote(address to) public onlyDuringElection notVoted {
        require(voters[to].registered, "Delegate address is not a registered voter");
        voters[msg.sender].voteDelegated = true;
        voters[msg.sender].delegateTo = to;
        emit VoteDelegated(msg.sender, to);
    }
    // Function to cast a vote for a candidate
    function Vote(uint256 candidateId) public onlyDuringElection notVoted {
        require(candidates[candidateId].id != 0, "Candidate does not exist");
        if (voters[msg.sender].voteDelegated) {
            address delegatee = voters[msg.sender].delegateTo;
            require(voters[delegatee].hasVoted, "Delegatee has not voted yet");
            candidates[voters[delegatee].votedCandidateId].voteCount++;
        } else {
            candidates[candidateId].voteCount++;
        }
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedCandidateId = candidateId;
        emit VoteCasted(msg.sender, candidateId);
    }
    // Function to end the election
    function endElection() public onlyAdmin {
        require(electionOngoing, "Election is not ongoing");
        electionOngoing = false;
        emit ElectionEnded();
    }
    // Function to get the number of votes for a specific candidate
    function getVotes(uint256 candidateId) public view returns (
        uint256 id,
        string memory name,
        uint256 voteCount
    ) {
        Candidate memory candidate = candidates[candidateId];
        return (candidate.id, candidate.name, candidate.voteCount);
    }
    // Function to view a voter's profile
    function getVoterProfile(address voter) public view returns (
        bool registered,
        bool hasVoted,
        uint256 votedCandidateId,
        bool voteDelegated,
        address delegateTo
    ) {
        Voter memory voterDetails = voters[voter];
        return (
            voterDetails.registered,
            voterDetails.hasVoted,
            voterDetails.votedCandidateId,
            voterDetails.voteDelegated,
            voterDetails.delegateTo
        );
    }
}
