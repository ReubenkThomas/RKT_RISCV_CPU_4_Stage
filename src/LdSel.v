/*
Module:
    Load Selector (LdSel)

Description:
    Determines which of the load types will be worked on by sending a signal to the LoadExtender.

Inputs: 
    Inst: 32-bit instruction passed down by the IMEM to the control logic. 

Outputs:
    LdSel: a 3-bit selector, where
        000 indicates a signed byte extender
        001 indicates an signed halfword extender
        010 indicates a word
        011 indicates nothing and should be disregarded
        100 indicates an unsigned byte extender
        101 indicates an unsigned halfword extender
        110 indicates nothing and should be disregarded
        111 indicates nothing and should be disregarded

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"
`include "ControlLogicSel.vh"


module LdSel (
    input [31:0] inst,
    output [2:0] LdSel
);

assign LdSel = inst[14:12];
endmodule