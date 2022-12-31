/*
Module:
    Memory Data Forwarding (DataFwd)

Description: 
    Forwards the data from the post Memory stage to the pre Memory stage, specifically
    with the data port of the DMEM.

Inputs:
    inst_X: 32-bit instruction in the X stage
    inst_M: 32-bit instruction in the M stage

Outputs:
    DataFwd: 1-bit signal that says whether or not to forward data to DMEM input
    - 0 indicates to not forward the data, in other words, take the result from the RS2.
    - 1 indicates to forward the data since it was detected that a load, store happened.

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"
`include "ControlLogicSel.vh"

module DataFwd (
    input [31:0] inst_X,
    input [31:0] inst_M,

    output DataFwd
);

    wire load;
    assign load = inst_M[6:0] == `OPC_LOAD;

    wire store;
    assign store = inst_X[6:0] == `OPC_STORE;
    
    assign DataFwd = (inst_X[24:20] != `x0 & load & store & (inst_X[24:20] == inst_M[11:7])) ? `DataFwd_MEM : `DataFwd_REG;
    
endmodule