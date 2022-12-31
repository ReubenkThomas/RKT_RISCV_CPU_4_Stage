/*
Module:
    Register Write Enable (RegWEn)

Description:
    A control signal that tells the register file to write data into it or not.

Inputs: 
    inst: 32-bit instruction in the W stage

Outputs:
    RegWEn: 1-bit number where
    - 0 indicates a disable the write
    - 1 indicate to enable the write

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"
`include "ControlLogicSel.vh"

module RegWEn (
    input [31:0] inst,

    output RegWEn
);
    reg regRegWEn;
    assign RegWEn = regRegWEn;

    always @(*) begin
        case(inst[6:0])
            `OPC_ARI_RTYPE : regRegWEn <= `RegWEn_WRITE; 
            `OPC_ARI_ITYPE : regRegWEn <= `RegWEn_WRITE; 
            `OPC_LOAD      : regRegWEn <= `RegWEn_WRITE; 
            `OPC_JAL       : regRegWEn <= `RegWEn_WRITE; 
            `OPC_JALR      : regRegWEn <= `RegWEn_WRITE; 
            `OPC_AUIPC     : regRegWEn <= `RegWEn_WRITE; 
            `OPC_LUI       : regRegWEn <= `RegWEn_WRITE; 
            default        : regRegWEn <= `RegWEn_READ; 
        endcase
    end

endmodule