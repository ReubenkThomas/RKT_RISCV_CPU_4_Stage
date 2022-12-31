/*
Module:
    PC Selector (PCSel)

Description:
    Determines which way the program will continue flowing, either proceeding to the next
    instruction, taking the result from the ALU, or predicting its next instruction address.

Inputs: 
    inst   : 32-bit instruction passed down by the IMEM to the control logic. 
    result : 1-bit result from the Branch Checker that will change the Branch Predictor's state.
    jump   : 1-bit input that says if the BranchPredictor wants to jump or not.

Outputs:
    PCSel: 3-bit number, where
    - 0 indicates to do PC_FD + 4
    - 1 indicates to do the ALUOutput
    - 2 indicates we want to predict a jump because that is what the BranchPrediction said to
    - 3 indicates to get PC_X + 4 because there was a misprediction (it jumped but wasn't supposed to)
    - 4 indicates to jump because of the JALR instruction

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"
`include "ControlLogicSel.vh"


module PCSel (
    input [31:0] inst, // This is the FD instruction
    input [2:0] result, // From the branch checker
    input jump,
    input stall,
    output [2:0] PCSel, // Sent to MUX
    output predict // Sent to Branch Checker pipeline
    
);

    reg [2:0] regPCSel;
    assign PCSel = regPCSel;
    reg [2:0] regPredict;
    assign predict = regPredict;

    always @(*) begin
        if (stall) begin
            regPCSel <= `PCSel_SAME;
        end else begin
            case (result) 
                3'b100  : begin
                    regPCSel <= `PCSel_ALU;
                end
                3'b110  : begin
                    regPCSel <= `PCSel_PCXPLUS4;
                regPredict <= 1'b0;
                end
                default : begin
                    case(inst[6:0])
                        `OPC_JAL : begin
                            regPCSel <= `PCSel_PCPLUSIMM;
                            regPredict <= 1'b0;
                        end
                        `OPC_BRANCH : begin
                            if (jump) begin
                                regPCSel <= `PCSel_PCPLUSIMM;
                                regPredict <= 1'b1;
                            end else begin
                                regPCSel <= `PCSel_PCPLUS4;
                                regPredict <= 1'b0;
                            end
                        end
                        `OPC_JALR : begin
                            regPCSel <= `PCSel_JALR;
                            regPredict <= 1'b0;
                        end
                        
                        default: begin
                            regPCSel <= `PCSel_PCPLUS4;
                            regPredict <= 1'b0;
                        end
                    endcase
                end
            endcase

        end
    end

endmodule