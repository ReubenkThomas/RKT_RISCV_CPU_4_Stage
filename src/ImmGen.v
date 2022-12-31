/*
Module: 
    Immediate Generator (ImmGen)

Desc:   
    32-bit Immediate Generator for the RISC-V Processor

Inputs: 
    inst: The 32-Bit Instruction 
						
Outputs:
    imm: 32-bit Immediate for correct instruction type

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"

module ImmGen (
    input [31:0] inst,
    output [31:0] imm
);

    wire[31:0] I_imm;
    wire[31:0] S_imm;
    wire[31:0] B_imm;
    wire[31:0] U_imm;
    wire[31:0] J_imm;

    assign I_imm = {{21{inst[31]}}, inst[30:20]};
    assign S_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    assign B_imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign U_imm = {inst[31:12], 12'b0};
    assign J_imm = {{12{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};



    reg[31:0] Out_R;
    assign imm = Out_R;

    // CSR makes no sense pls help

    always @* begin
        case (inst[6:0])
            `OPC_BRANCH: Out_R <= B_imm;
            `OPC_STORE: Out_R <= S_imm;
            `OPC_JAL: Out_R <= J_imm;
            `OPC_LUI, `OPC_AUIPC: Out_R <= U_imm; 
            default: Out_R <= I_imm;
        endcase
    end

    
endmodule
