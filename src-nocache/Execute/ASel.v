/*
Module: 
    A Selector (ASel)

Desc:   
    Chooses either between the register value, the PC or forwarded data from MEM.

Input: 
    inst_X: 32-bit instruction in the X stage.
    inst_M: 32-bit instruction in the M stage.

Outputs: 
    ASel: Will choose between the register value, the PC, or forwarded data. 
          In terms of the datapath,
        - 0 indicates that the register will be chosen
        - 1 indicates that the PC will be chosen
        - 2 indicates that MEM forwarding will be chosen.

Authors: 
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"
`include "ControlLogicSel.vh"
`include "RegNames.vh"


module ASel (
    input [31:0] inst_X,
    input [31:0] inst_M,
    output [1:0] ASel
);
    reg [1:0] regASel;
    assign ASel = regASel;

    wire LoadFwd;
    assign LoadFwd = (inst_X[19:15] != `x0 & inst_M[6:0] == `OPC_LOAD & (inst_M[11:7] == inst_X[19:15]) & ~(inst_X[6:0] == `OPC_STORE));
    wire loadBranch;
    assign loadBranch = (inst_M[6:0] == `OPC_LOAD) & (inst_X[6:0] == `OPC_BRANCH);
    always @(*) begin
        // Choose the register
        if (LoadFwd & ~loadBranch) begin
            regASel <= `ASel_MEM;
        end else begin
            case(inst_X[6:0])
                `OPC_ARI_RTYPE : regASel <= `ASel_REG;
                `OPC_ARI_ITYPE : regASel <= `ASel_REG;
                `OPC_LOAD      : regASel <= `ASel_REG;
                `OPC_STORE     : regASel <= `ASel_REG;
                `OPC_JALR      : regASel <= `ASel_REG;
                `OPC_CSR       : regASel <= `ASel_REG;
                
                // Choose the PC
                `OPC_BRANCH    : regASel <= `ASel_PC;
                `OPC_JAL       : regASel <= `ASel_PC;
                `OPC_AUIPC     : regASel <= `ASel_PC;

                // Doesn't matter, just choose reg by default.
                `OPC_LUI       : regASel <= `ASel_REG;
            endcase
        end
    end

endmodule