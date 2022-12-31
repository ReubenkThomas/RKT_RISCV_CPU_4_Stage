/*
Module:
    CSRSel

Description:
    Determines if a value needs to be written in the CSR register.

Input:
    inst_W: 32-bit instruction in the W stage

Output:
    CSRSel: 2-bit output that determines if data needs to be written to CSR.
    - 0 indicates nothing should be written.
    - 1 indicates register data needs to be written
    - 2 indicates immediate data needs to be written

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "ControlLogicSel.vh"
`include "Opcode.vh"

module CSRSel (
    input [31:0] inst_W,
    output [1:0] CSRSel
);

    reg [1:0] regCSRSel;
    assign CSRSel = regCSRSel;

    always @(*) begin
        if (inst_W[6:0] == `OPC_CSR) begin
            case(inst_W[14:12]) 
                `FNC_RW  : regCSRSel <= `CSR_REG;
                `FNC_RWI : regCSRSel <= `CSR_IMM;
                default  : regCSRSel <= `CSR_ZERO;
            endcase
        end else begin
            regCSRSel <= `CSR_ZERO;
        end
    end


endmodule