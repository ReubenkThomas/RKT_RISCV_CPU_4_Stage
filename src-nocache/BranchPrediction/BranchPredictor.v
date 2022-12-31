/*
Module: 
    Branch Predictor (BranchPredictor)

Description:   
    Configurable n-bit branch predictor what will communicate with PCSel to make jumps based on the core fetching a branch instruction.
    The n-bit branch predictor will be split evenly, where the former half are areas of predicting a branch miss, and the latter half
    predicts a branch hit. Read the description on BranchChecker to know how the result is interpreted.

    The branch predictor will be told whether a branch instruction was a miss or a hit. On a miss, it will move a special branch register
    1 spot towards the lower spectrum, and on a correct prediction, it will move the special register 1 spot towards the higher
    spectrum. 

    The branch predictor is not given any information related to what is in the PC register or the immediate jump. That is handled by the
    datapath itself

Input: 
    result: 3-bit input where result[0] = 1 signifies a correct prediction, and a result[0] = 0 is a misprediction.
    rst: 1-bit reset signal to restart the state register.

Outputs: 
    jump: 1-bit input where 1 communicates to PCSel that it wants to predict a branch, and 0 communicates to not jump

Authors: 
    Matthew Dharmawan and Reuben Koshy Thomas
*/

localparam HIT = 1'b1;
localparam MISS = 1'b0;

module BranchPredictor #(parameter N=4) (
    input clk,
    input [2:0] result,
    input rst,
    input [1:0] forcer,
    output jump
);

    reg [N-1:0] state = {N{1'b0}};
    reg [N-1:0] nextstate = {N{1'b0}};

    // assign jump = (state >= (2 ** (N - 1)));
    assign jump = (forcer == 2'b00) ? 1'b0 : (forcer == 2'b11) ? 1'b1 : (state >= (2 ** (N - 1)));

    always @(*) begin
        if (result[2]) begin
            if (~(result[1] ^ result[0])) begin
                // If the state is at its maximum edge of the spectrum, do not add 1 to it (or else it overflows to {N{1'b10}})
                if (state == {N{1'b1}}) begin 
                    nextstate <= state;
                end else begin
                    nextstate <= state + 1; // Otherwise, add 1 to the state.
                end
            end
            else begin
                // If the state is at its minimum edge of the spectrum, do not subtract 1 to it (or else it overflows to {N{1'b1}})
                if (state == {N{1'b0}}) begin 
                    nextstate <= state;
                end else begin
                    nextstate <= state - 1; // Otherwise, subtract 1 to the state.
                end
            end
        end 
    end



    always @(posedge clk) begin
        state <= nextstate;
    end

    always @(rst) begin
        state <= {N{1'b0}};
        nextstate <= {N{1'b0}};
    end
endmodule