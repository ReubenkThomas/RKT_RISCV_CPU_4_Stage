/*
Module: 
     Branch Comparator (BranchComp)

Desc:   
     Branch Comparator, takes 2 input and compares values; Combinational

Inputs: 
     dataA: 32-bit input A
     dataB: 32-bit input B
     BrUn: Unsigned Comparasion

Outputs: 
     BrEq: == check 
     BrLT: < check

Authors: 
     Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"

module BranchComp(
    input [31:0] dataA,
    input [31:0] dataB,
    input BrUn, 
    output BrEq, BrLT
);

wire unsignedEq;
wire signedEq;
wire unsignedLT;
wire signedLT;

assign unsignedEq = dataA == dataB; // do i need to enforce unsigned?
assign unsignedLT = dataA < dataB;
assign signedEq = $signed(dataA) == $signed(dataB);
assign signedLT = $signed(dataA) < $signed(dataB);

assign BrEq = BrUn ? unsignedEq : signedEq;
assign BrLT = BrUn ? unsignedLT : signedLT;

endmodule