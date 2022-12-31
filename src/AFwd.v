/* 
Module:
    A Forwarding (AFwd)

Description:
    Determines whether it should take the forwarded data from the ALU, MEM or the RegFile

    Observations based on our datapath:
    - The priority should be the information found after the ALU. Specifically, we need to
      first check if the data would be written to the register that will be invoked through
      checking the opcode and instruction type.
    - If the data being written to is x0, we can automatically signal to take from the RegFile
    - Due to the forwarding being placed at the end of decode, it must be the case that
      we are looking for if inst_m is equivalent to inst_FD registers for ALU-ALU forwarding, 
      and if inst_w is equivalent to inst_FD registers for Load-ALU forwarding. Then possibly
      WB forwarding. Note this priority.
    - PC values are forwarded sometimes, since JAL and JALR instructions will write a PC
      value into the return address. X must be forwarded before M, like the data.

Inputs:
    inst_FD:   The instruction found in the FD stage
    inst_X:    The instruction found in the X  stage
    inst_M:    The instruction found in the M  stage
    inst_W:    The instruction found in the W  stage

Outputs:
    AFwd: 3-bit signal, where
    - 0 indicates to take the data from the RegFile
    - 1 indicates to take the data from the ALUX
    - 2 indicates to take the data from the ALUM
    - 3 indicates to take the MEM data
    - 4 indicates to take the JX data (PC_X + 4)
    - 5 indicates to take the JM data (PC_M)
    - 6 indicates to take the WB data 

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"
`include "ControlLogicSel.vh"
`include "RegNames.vh"
module AFwd (
    input [31:0] inst_FD, // Resolve it to be sent the register bits instead
    input [31:0] inst_X,
    input [31:0] inst_M,
    input [31:0] inst_W,

    output [2:0] AFwd
);

    
    reg [2:0] regAFwd;
    assign AFwd = regAFwd;

    wire [6:0] op_FD;
    wire [6:0] op_X;
    wire [6:0] op_M;
    wire [6:0] op_W;
    assign op_FD = inst_FD[6:0];
    assign op_X = inst_X[6:0];
    assign op_M = inst_M[6:0];
    assign op_W = inst_W[6:0];


    wire ALUFwdX;
    wire ALUFwdM;
    wire MemFwd;
    wire JFwdX;
    wire JFwdM;


    assign ALUFwdX = op_X == `OPC_ARI_RTYPE | op_X == `OPC_ARI_ITYPE | op_X == `OPC_AUIPC | op_X == `OPC_LUI;
    assign ALUFwdM = op_M == `OPC_ARI_RTYPE | op_M == `OPC_ARI_ITYPE | op_M == `OPC_AUIPC | op_M == `OPC_LUI;
    assign JFwdX = op_X == `OPC_JAL | op_X == `OPC_JALR;
    assign JFwdM = op_M == `OPC_JAL | op_M == `OPC_JALR;

    assign MemFwd = op_M == `OPC_LOAD;

    wire RDX;
    wire RDM;
    wire RDW;

    assign RDX = ~(op_X == `OPC_STORE | op_X == `OPC_BRANCH);
    assign RDM = ~(op_M == `OPC_STORE | op_M == `OPC_BRANCH);
    assign RDW = ~(op_W == `OPC_STORE | op_W == `OPC_BRANCH);

    wire sameX;
    wire sameM;
    wire sameW;

    assign sameX = inst_FD[19:15] == inst_X[11:7];
    assign sameM = inst_FD[19:15] == inst_M[11:7];
    assign sameW = inst_FD[19:15] == inst_W[11:7];

    always @(*) begin
        // outer case statement checks for opcodes in the M stage that write.
        if (inst_FD[19:15] != `x0) begin
            if (RDX & ALUFwdX & sameX) begin
                regAFwd <= `AFwd_ALUX;
            end else if (RDX & JFwdX & sameX) begin
                regAFwd <= `AFwd_JX;
            end else if (RDM & ALUFwdM & sameM) begin
                regAFwd <= `AFwd_ALUM;
            end else if (RDM & JFwdM & sameM) begin
                regAFwd <= `AFwd_JM;
            end else if (RDM & MemFwd & sameM) begin
                regAFwd <= `AFwd_MEM;
            end else if (RDW & sameW) begin
                regAFwd <= `AFwd_WB;
            end else begin
                regAFwd <= `AFwd_REG;
            end
        end else begin
            regAFwd <= `AFwd_REG;
        end
    end

endmodule