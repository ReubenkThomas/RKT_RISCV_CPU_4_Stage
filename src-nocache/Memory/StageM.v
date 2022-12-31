/*
Module:
    Memory Stage (StageM)

Description:
    Determines the control logic bits for MemRW, LdSel

Input:
    inst_M: 32-bit instruction in the M stage

Outputs:
    LdSel: determines how the loaded data in the DMEM will be formatted.

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas

*/

module StageM (
    input [31:0] inst_M,
    
    output [2:0] LdSel
);



LdSel LDSEL (
    .inst(inst_M),
    .LdSel(LdSel)
);
endmodule