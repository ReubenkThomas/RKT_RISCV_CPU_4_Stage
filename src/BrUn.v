/*
Module:
    Branch Unsigned (BrUn)

Description:
    Indicates to the branch comparator whether to make a signed or unsigned comparison.

Input:
    inst: 32-bit instruction sent along through the control logic.

Output:
    BrUn: 1-bit indicator, where
        - 0 indicates an unsigned comparison
        - 1 indicates a signed comparison

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"
`include "ControlLogicSel.vh"

module BrUn (
    input [31:0] inst,
    output BrUn
);
    reg regBrUn;
    assign BrUn = regBrUn;

    always @(*) begin
        case(inst[6:0])
            `OPC_BRANCH : begin
                case(inst[14:12])
                    `FNC_BGEU : regBrUn <= `BrUn_UNSIGNED;
                    `FNC_BLTU : regBrUn <= `BrUn_UNSIGNED;
                    default   : regBrUn <= `BrUn_SIGNED;
                endcase
            end
            default     : regBrUn <= `BrUn_SIGNED;
            
        endcase
    end

endmodule