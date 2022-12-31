`include "Opcode.vh"
`include "ControlLogicSel.vh"

module BranchAFwd (
    input [31:0] inst_X,
    input [31:0] inst_M,
    output BranchAFwd
);

wire loadBranch;
wire sameRS1;
assign loadBranch = (inst_M[6:0] == `OPC_LOAD) & (inst_X[6:0] == `OPC_BRANCH);
assign sameRS1 = inst_M[11:7] == inst_X[19:15];
assign BranchAFwd = loadBranch & sameRS1;

endmodule