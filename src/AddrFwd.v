/*
Module:
    Memory Address Forwarding (AddrFwd)

Description: 
    Forwards the data from the post Memory stage to the pre Memory stage, specifically
    with the address port of the DMEM. This happens in a case of a load then store where
    the rs1 value needs to be forwarded.

Inputs:
    inst_X: 32-bit instruction in the X stage
    inst_M: 32-bit instruction in the M stage

Outputs:
    AddrFwd: 1-bit signal, where
    - 0 indicates to not forward the address, in other words, take the result from the ALU.
    - 1 indicates to forward the address since it was detected that a load, store happened.

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"
`include "ControlLogicSel.vh"

module AddrFwd (
    input [31:0] inst_X,
    input [31:0] inst_M,

    output AddrFwd
);

    wire load;
    assign load = inst_M[6:0] == `OPC_LOAD;

    wire store;
    assign store = inst_X[6:0] == `OPC_STORE;
    
    assign AddrFwd = (inst_X[19:15] != `x0 & load & store & (inst_X[19:15] == inst_M[11:7])) ? `AddrFwd_MEM : `AddrFwd_REG;
    
endmodule