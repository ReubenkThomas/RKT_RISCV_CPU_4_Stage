/*
Module:
    Write Stage (StageW)

Description:
    Determines the control logic bits for RegWEn, WBSel, CSRSel

Input:
    inst_W: 32-bit instruction in the W stage.

Outputs:
   WBSel : 2-bit signal to determine which data to be written into a register.
   RegWEn: 1-bit signal to determine if data should be written to the RegFile.
   CSRSel: 2-bit signal to determine if data should be written to CSR.

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

module StageW (
    input [31:0] inst_W,
    output [1:0] WBSel,
    output RegWEn,
    output [1:0] CSRSel
);

WBSel WBSEL (
    .inst(inst_W),
    .WBSel(WBSel)
);

RegWEn REGWEN (
    .inst(inst_W),
    .RegWEn(RegWEn)
);

CSRSel CSRSEL (
    .inst_W(inst_W),
    .CSRSel(CSRSel)
);

endmodule