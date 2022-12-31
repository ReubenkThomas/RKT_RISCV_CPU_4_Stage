/*
Module: 
    B Selector (BSel)

Desc:   
    Chooses either between the register value or the immediate

Input: 
    inst_X: 32-bit instruction in the X stage
    inst_M: 32-bit instruction in the M stage

Outputs: 
    BSel: Will choose between the register value, immediate or forwarded MEM data. 
    In terms of the datapath,
        - 0 indicates that the register will be chosen
        - 1 indicates that the immediate will be chosen
        - 2 indicates that memory forwarding will be chosen.

Authors: 
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"
`include "ControlLogicSel.vh"
`include "RegNames.vh"

module BSel (
    input [31:0] inst_X,
    input [31:0] inst_M,
    output [1:0] BSel
);
    reg [1:0] regBSel;
    assign BSel = regBSel;
    wire LoadFwd;
    wire immInst;
    assign LoadFwd = (inst_X[24:20] != `x0 & (inst_M[6:0] == `OPC_LOAD) & (inst_M[11:7] == inst_X[24:20]) & ~(inst_X[6:0] == `OPC_STORE));
    assign immInst = (inst_X[6:0] == `OPC_ARI_ITYPE | inst_X[6:0] == `OPC_LOAD | inst_X[6:0] == `OPC_STORE | inst_X[6:0] == `OPC_JALR | inst_X[6:0] == `OPC_AUIPC | inst_X[6:0] == `OPC_LUI);
    wire loadBranch;
    assign loadBranch = (inst_M[6:0] == `OPC_LOAD) & (inst_X[6:0] == `OPC_BRANCH);
    always @(*) begin
        if (LoadFwd & ~immInst & ~loadBranch) begin
            regBSel <= `BSel_MEM;
        end else begin
            case(inst_X[6:0])
                `OPC_ARI_RTYPE : regBSel <= `BSel_REG;
                default        : regBSel <= `BSel_IMM;
            endcase
        end
    end
endmodule