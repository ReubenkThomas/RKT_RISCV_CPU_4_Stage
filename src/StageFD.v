/*
Module:
    Fetch and Decode Stage (StageFD)

Description:
    Determines the control logic bits for PCSel, RegWEn, AFwd, and BFwd.

Input:
    inst_FD: 32-bit instruction in the FD stage
    inst_X : 32-bit instruction in the X  stage
    inst_M : 32-bit instruction in the M  stage
    inst_W : 32-bit instruction in the W  stage

Outputs:
    AFwd: 8-bit signal that determines A forwarding
    BFwd: 8-bit signal that determines B forwarding

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas

*/
`include "Opcode.vh"
`include "ControlLogicSel.vh"

module StageFD (
    input [31:0] inst_FD,
    input [31:0] inst_X,
    input [31:0] inst_M,
    input [31:0] inst_W,


    output [2:0] AFwd,
    output [2:0] BFwd
);

AFwd AFWD (
    .inst_FD(inst_FD), // Resolve it to be sent the register bits instead
    .inst_X(inst_X),
    .inst_M(inst_M),
    .inst_W(inst_W),

    .AFwd(AFwd)
);

BFwd BFWD (
    .inst_FD(inst_FD), // Resolve it to be sent the register bits instead
    .inst_X(inst_X),
    .inst_M(inst_M),
    .inst_W(inst_W),

    .BFwd(BFwd)
);

endmodule