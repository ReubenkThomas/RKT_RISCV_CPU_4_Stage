/*
Module: 
    Arithmetic Logic Unit (ALU)

Desc:   
    32-bit ALU for the RISC-V Processor

Inputs: 
    A: 32-bit value
    B: 32-bit value
    ALUop: Selects the ALU's operation 
						
Outputs:
    Out: The chosen function mapped to A and B.

 Authors: 
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"
`include "ALUop.vh"

module ALU(
    input [31:0] A,B,
    input [3:0] ALUop,
    output[31:0] Out
);

    wire[31:0] add_opt;
    wire[31:0] sub_opt;
    wire[31:0] and_opt;
    wire[31:0] or_opt;
    wire[31:0] xor_opt;
    wire[31:0] sltu_opt;
    wire[31:0] slt_opt;
    wire[31:0] sll_opt;
    wire[31:0] sra_opt;
    wire[31:0] srl_opt;
    wire[31:0] copy_b_opt;
    wire[31:0] copy_a_opt;
    wire[31:0] xxx_opt;

    assign add_opt = A + B;
    assign sub_opt = A - B;
    assign and_opt = A & B;
    assign or_opt = A | B;
    assign xor_opt = A ^ B;
    assign sltu_opt = A < B;
    assign slt_opt = $signed(A) < $signed(B);
    assign sll_opt = A << B[4:0];
    assign sra_opt = $signed(A) >>> B[4:0];
    assign srl_opt = A >> B[4:0];
    assign copy_a_opt = A;
    assign copy_b_opt = B;
    assign xxx_opt = 0;

    reg [31:0] Out_R;
    assign Out = Out_R;


    always @(*) begin
        case (ALUop)
            `ALU_ADD: Out_R <= add_opt;
            `ALU_SUB: Out_R <= sub_opt;
            `ALU_AND: Out_R <= and_opt;
            `ALU_OR: Out_R <= or_opt;
            `ALU_XOR: Out_R <= xor_opt;
            `ALU_SLL: Out_R <= sll_opt;
            `ALU_SLT: Out_R <= slt_opt;
            `ALU_SLTU: Out_R <= sltu_opt;
            `ALU_SRA: Out_R <= sra_opt;
            `ALU_SRL: Out_R <= srl_opt;
            `ALU_COPY_B: Out_R <= copy_b_opt;
            `ALU_COPY_A: Out_R <= copy_a_opt;
            `ALU_XXX: Out_R <= xxx_opt;
            default: Out_R <= xxx_opt;
        endcase
    end

   
endmodule
