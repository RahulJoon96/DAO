// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract DAO{
    
    struct Proposal{
         uint id;
         string description;
         uint amount;
         uint votes;
         uint end; 
         bool isExecuted; 
    }

    mapping(address=>bool) private isInvestor; 
    mapping(address=>uint) public numOfshares; 
    mapping(address=>mapping(uint=>bool)) public isVoted; 
    address[] public investorsList; 
    mapping(uint=>Proposal) public proposals; 

    uint public totalShares;
    uint public availableFunds;
    uint public contributionTimeEnd;
    uint public nextProposalId;
    uint public voteTime;
    uint public quorum;
    address public manager;



    constructor(uint _contributionTimeEnd,uint _voteTime,uint _quorum){
        require(_quorum>0 && _quorum<100,"not valid values"); 
        contributionTimeEnd = block.timestamp+_contributionTimeEnd; 
        voteTime = _voteTime;
        quorum = _quorum;
        manager = msg.sender; 
    }

    modifier onlyInvestor(){
        require(isInvestor[msg.sender]==true,"You are not an investor");
        _;
    }
    modifier onlyManager(){
        require(manager==msg.sender,"You are not a manager"); 
        _;
    }



    function contribution() public payable{ 
       require(contributionTimeEnd >= block.timestamp,"contribution time ended");
       require(msg.value>0,"send more than 0 ether");

       
       isInvestor[msg.sender] = true; 
       numOfshares[msg.sender] = numOfshares[msg.sender] + msg.value; 
       totalShares = totalShares + msg.value;
       availableFunds = availableFunds + msg.value;

       
       investorsList.push(msg.sender);
    }



    function reedemShares(uint amount) public onlyInvestor(){ 
       require(numOfshares[msg.sender] >= amount,"You don't have enough shares");  
       require(availableFunds>=amount,"Not enough funds");

       numOfshares[msg.sender] = numOfshares[msg.sender] - amount;
       if(numOfshares[msg.sender]==0){ 
           isInvestor[msg.sender] = false;  
       }
       availableFunds = availableFunds - amount;
       payable(msg.sender).transfer(amount); 
     
    }



    function transferShare(uint amount, address to) public onlyInvestor(){  
      require(numOfshares[msg.sender] >= amount,"You do not have enough shares");
      require(availableFunds>=amount,"Not enough funds");

      numOfshares[msg.sender] = numOfshares[msg.sender] - amount;
      if(numOfshares[msg.sender]==0){ 
           isInvestor[msg.sender] = false; 
       }
      numOfshares[to] = numOfshares[to] + amount;
      isInvestor[to] = true;
      investorsList.push(to);
    }


    function createProposal(string calldata description,uint amount,address payable receipient) public onlyManager {
        require(availableFunds>=amount,"Not enough funds");

        proposals[nextProposalId]=Proposal(nextProposalId,description,amount,receipient,0,block.timestamp+voteTime,false); 
        
        nextProposalId++;
    }



    function voteProposal(uint proposalId) public onlyInvestor(){
       require(isVoted[msg.sender][proposalId]==false,"You have already voted for this proposal");
       require(proposals[proposalId].end>=block.timestamp,"voting time ended for this proposal"); 
       require(proposals[proposalId].isExecuted==false,"This proposal is already executed");

       isVoted[msg.sender][proposalId] = true;  
       proposals[proposalId].votes = proposals[proposalId].votes + numOfshares[msg.sender]; 
    }



    function executeProposal(uint proposalId) public onlyManager(){
        require((((proposals[proposalId].votes)*100)/totalShares)>=quorum,"Majority does not support");
        proposals[proposalId].isExecuted = true; 
        _transfer(proposals[proposalId].amount, proposals[proposalId].receipient); 
            
    }



    function _transfer(uint amount,address payable receipient) private {
        receipient.transfer(amount);
    }

   
    function ProposalList() public view returns(Proposal[] memory){ 
       Proposal[] memory arr = new Proposal[](nextProposalId-1); 
       
       for(uint i=0;i<nextProposalId;i++){
           arr[i] = proposals[i];
       }
    return arr;
    }

}