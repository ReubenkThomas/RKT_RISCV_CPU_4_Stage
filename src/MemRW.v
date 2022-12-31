/*
Module:
    Memory Read/Write (MemRW)

Description:
    Determines if the DMEM should be in read or write mode.

Inputs:
    inst_X: 32-bit instruction in the memory stage.
    ALUOutXTwoBit: 2-bit data from the ALUOutput which is useful for determining effects of the offset.

Output:
    MemRW: 4-bit write mask, where 1 allows a write in the byte, and 0 does not.

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"
`include "ControlLogicSel.vh"

module MemRW (
    input [31:0] inst_X,
    input [1:0] ALUOutXTwoBit,
    output [3:0] MemRW

);

reg [3:0] regMemRW;
assign MemRW = regMemRW;

always @(*) begin
    regMemRW <= 4'b0000;
    case(inst_X[6:0])
        `OPC_LOAD   : begin 
            regMemRW <= 4'b0000;
            
        end
        `OPC_STORE  : begin
            case (inst_X[14:12])
                `FNC_SW: regMemRW <= 4'b1111;
                `FNC_SH: begin
                    case (ALUOutXTwoBit)
                        2'b00: regMemRW <= 4'b0011;
                        2'b01: regMemRW <= 4'b0110;
                        2'b10: regMemRW <= 4'b1100;
                        2'b11: regMemRW <= 4'b1100;
                        default: regMemRW <= 4'b0011;
                    endcase
                end
                `FNC_SB: begin
                    case (ALUOutXTwoBit)
                        2'b00: regMemRW <= 4'b0001;
                        2'b01: regMemRW <= 4'b0010;
                        2'b10: regMemRW <= 4'b0100;
                        2'b11: regMemRW <= 4'b1000;
                        default: regMemRW <= 4'b0001;
                    endcase
                end
            endcase
        end
        default: regMemRW <= 4'b0000;
    endcase
end

endmodule