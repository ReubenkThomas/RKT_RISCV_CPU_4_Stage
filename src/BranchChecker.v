/*
Module:
    Branch Checker (BranchChecker)

Description:
    A module in the datapath that determines if the correct choice of a prediction was made.
    Sends the result to the BranchPredictor and PCSel.

    Note that the correct and incorrect bit is able to be determined by an XNOR.
    This is because the signal will state if the current branch instruction will hit, and 
    the predict bit tells if the PC predicted or not. If these conflict, then a result of
    incorrect (1'b0) will be passed, and if they do not conflict, then correct (1'b1)
    will be passed.

Inputs:
    inst    : 32-bit instruction in the X Stage.
    predict : 1-bit pipelined input from PCSel that says if PCSel predicted a hit or miss.
    BrLT    : 1-bit result from the BranchComp that states if the rs1 was less than rs2
    BrEq    : 1-bit result from the BranchComp that states if the rs1 was equal to rs2

Output
    result  : 3-bit signal, where the result[2] is a bit to ignore the result, and 
              result[1:0] is a state of how the PCSel should choose its next PC value.
              Specifically, for these two bits, result[1] is the signal of predicting or 
              not, sendt by the pipielined PCSel input, where 1 is a predict, and 0 is
              a no predict. result[0] is the actual value that the BranchChecker found
              out the result was based on the inst, BrLt, and BrEq; 0 indicates it was
              incorrect and 1 indicates it was correct.

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"
`include "ControlLogicSel.vh"

module BranchChecker (
    input [31:0] inst,
    input predict,
    input BrLT,
    input BrEq,

    output [2:0] result
);
    
    reg regResult;
    reg signal;
        
    always @(*) begin
        case(inst[6:0])
            `OPC_BRANCH : begin
                case(inst[14:12])
                    `FNC_BEQ             :  signal <= BrEq;
                    `FNC_BGE, `FNC_BGEU  :  signal <= BrEq | ~BrLT;
                    `FNC_BLT, `FNC_BLTU  :  signal <= BrLT;
                    `FNC_BNE             :  signal <= ~BrEq;
                endcase
            end
            default : regResult <= 3'b000;
        endcase

    end

    assign result = {inst[6:0] == `OPC_BRANCH, predict, ~(signal ^ predict)};
endmodule
