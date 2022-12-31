/*
Control Signals.
*/

`ifndef ControlLogicSel
`define ControlLogicSel

// PCSel
`define PCSel_PCPLUS4       3'b000
`define PCSel_ALU           3'b001
`define PCSel_PCPLUSIMM     3'b010
`define PCSel_PCXPLUS4      3'b011
`define PCSel_JALR          3'b100
`define PCSel_SAME          3'b101

// RegWEn
`define RegWEn_READ         1'b0
`define RegWEn_WRITE        1'b1


// ImmSel is determined by Opcode.vh


// AFwd
`define AFwd_REG            3'b000
`define AFwd_ALUX           3'b001
`define AFwd_ALUM           3'b010
`define AFwd_MEM            3'b011
`define AFwd_JX             3'b100
`define AFwd_JM             3'b101
`define AFwd_WB             3'b110



// BFwd
`define BFwd_REG            3'b000
`define BFwd_ALUX           3'b001
`define BFwd_ALUM           3'b010
`define BFwd_MEM            3'b011
`define BFwd_JX             3'b100
`define BFwd_JM             3'b101
`define BFwd_WB             3'b110

// ASel 
`define ASel_REG            2'b00
`define ASel_PC             2'b01
`define ASel_MEM            2'b10

// BSel
`define BSel_REG            1'b0
`define BSel_IMM            1'b1
`define BSel_MEM            2'b10


// BrUn 
`define BrUn_UNSIGNED       1'b1
`define BrUn_SIGNED         1'b0

// AddrFwd
`define AddrFwd_REG         1'b0
`define AddrFwd_MEM         1'b1

// DataFwd
`define DataFwd_REG         1'b0
`define DataFwd_MEM         1'b1

// ALUSel determined by ALUdec.v, ALUop.vh

// MemRW determined by MemRW.v

// LdSel
`define LdSel_LB            3'b000
`define LdSel_LBU           3'b001
`define LdSel_LH            3'b010
`define LdSel_LHU           3'b011
`define LdSel_LW            3'b100


// WBSel
`define WBSel_MEM           2'b00
`define WBSel_ALU           2'b01
`define WBSel_PCPLUS4       2'b10

// CSRSel
`define CSR_ZERO            2'b00
`define CSR_REG             2'b01
`define CSR_IMM             2'b10

`endif //OPCODE
