/* 
Module
    Execute Stage (StageX)

Description:
    This is the segment of the control logic that determines BrUn, ASel, BSel, 
    ALUop, ADDrFwd, DataFwd, and MemRW.

Inputs:
    inst_X: 32-bit instruction in the Xvstage
    inst_M: 32-bit instruction in the M stage 
    ALUOutXTwoBit: 2-bit value that represents the last two values in the ALUOutput.
                   This is to determine offsets for MemRW mask

Output:
    ASel: choose between data in the register (0) 
          or data from the PC (1) 
          or Forwarded MEM data (2)
    BSel: choose between data in the register (0) 
          or data from the immediate generator (1) 
          or Forwarded MEM data (2)
    BrUn: make an unsigned comparison (1) 
          or not (0)
    ALUop: determines which arithmetic operation should be used.
    AddrFwd: choose between ALUOutput (0)
             or Forwarded MEM Address (1)
    DataFwd: choose between RS2 (0)
             or Forwarded MEM Data (1)
    MemRW: determines the write mask to DMEM
    

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

module StageX (
    input [31:0] inst_X,
    input [31:0] inst_M,
    input [1:0] ALUOutXTwoBit,

    output [1:0] ASel,
    output [1:0] BSel,
    output [3:0] ALUop,
    output BrUn,
    output AddrFwd,
    output DataFwd,
    output [3:0] MemRW,
    output BranchAFwd,
    output BranchBFwd
);

    ASel ASEL (
        .inst_X(inst_X),
        .inst_M(inst_M),

        .ASel(ASel)
    );

    BSel BSEL (
        .inst_X(inst_X),
        .inst_M(inst_M),

        .BSel(BSel)
    );

    ALUdec aludec (
        .opcode(inst_X[6:0]),
        .funct(inst_X[14:12]),
        .add_rshift_type(inst_X[30]),
        
        .ALUop(ALUop)
    );
    
    BrUn BRUN (
        .inst(inst_X),

        .BrUn(BrUn)
    );

    AddrFwd ADDRFWD (
        .inst_X(inst_X),
        .inst_M(inst_M),

        .AddrFwd(AddrFwd)
    );

    DataFwd DATAFWD (
        .inst_X(inst_X),
        .inst_M(inst_M),

        .DataFwd(DataFwd)
    );

    MemRW MEMRW (
        .inst_X(inst_X),
        .ALUOutXTwoBit(ALUOutXTwoBit),

        .MemRW(MemRW)
    );

    BranchAFwd BRANCHAFWD (
        .inst_X(inst_X),
        .inst_M(inst_M),
        .BranchAFwd(BranchAFwd)
    );

    BranchBFwd BRANCHBFWD (
        .inst_X(inst_X),
        .inst_M(inst_M),
        .BranchBFwd(BranchBFwd)
    );

endmodule