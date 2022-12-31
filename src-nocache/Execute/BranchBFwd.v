


`include "Opcode.vh"
`include "ControlLogicSel.vh"

module BranchBFwd (
    input [31:0] inst_X,
    input [31:0] inst_M,
    output BranchBFwd
);

wire loadBranch;
wire sameRS2;
assign loadBranch = (inst_M[6:0] == `OPC_LOAD & inst_X[6:0] == `OPC_BRANCH);
assign sameRS2 = (inst_M[11:7] == inst_X[24:20]);
assign BranchBFwd = loadBranch & sameRS2;

endmodule