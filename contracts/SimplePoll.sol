// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimplePoll
 * @dev A basic on-chain polling contract where users can vote Yes or No.
 * Each contract instance represents a single poll.
 */
contract SimplePoll {
    // The question for the poll
    string public question;

    // Vote counters
    uint256 public yesVotes;
    uint256 public noVotes;

    // Mapping to track who has already voted
    mapping(address => bool) public hasVoted;

    // Event to announce a new vote
    event Voted(address indexed voter, bool vote, uint256 totalYes, uint256 totalNo);

    /**
     * @dev Sets the poll question upon deployment.
     * @param _question The question for this poll.
     */
    constructor(string memory _question) {
        require(bytes(_question).length > 0, "Question cannot be empty");
        question = _question;
    }

    /**
     * @dev Allows a user to cast their vote.
     * A user can only vote once.
     * @param _vote The user's vote: true for Yes, false for No.
     */
    function vote(bool _vote) public {
        require(!hasVoted[msg.sender], "You have already voted.");

        hasVoted[msg.sender] = true;

        if (_vote) {
            yesVotes++;
        } else {
            noVotes++;
        }

        emit Voted(msg.sender, _vote, yesVotes, noVotes);
    }

    /**
     * @dev Retrieves the current poll results.
     * @return _yesVotes The total number of Yes votes.
     * @return _noVotes The total number of No votes.
     */
    function getResults() public view returns (uint256 _yesVotes, uint256 _noVotes) {
        return (yesVotes, noVotes);
    }
}
