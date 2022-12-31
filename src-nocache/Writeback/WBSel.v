/*
Module:
    Write Back Selector (WBSel)

Description:
    Determines what data will be written to the regfile, being the result from the ALU, PC + 4 
    or from Memory.

Inputs: 
    Inst: 32-bit instruction passed down by the IMEM to the control logic. 

Outputs:
    WBSel: 2-bit number, where
    - 0 indicates Memory (write the data that load extender outputs)
    - 1 indicates ALU    (write the data that the ALU outputs)
    - 2 indicates PC + 4 (writes the address of the next instruction)

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"
`include "ControlLogicSel.vh"

module WBSel (
    input [31:0] inst,
    output [1:0] WBSel
);

    reg [1:0] regWBSel;
    assign WBSel = regWBSel;

    always @(*) begin
        case (inst[6:0])
            `OPC_ARI_RTYPE : regWBSel <= `WBSel_ALU;
            `OPC_ARI_ITYPE : regWBSel <= `WBSel_ALU;
            `OPC_LOAD      : regWBSel <= `WBSel_MEM;

            `OPC_JAL       : regWBSel <= `WBSel_PCPLUS4;
            `OPC_JALR      : regWBSel <= `WBSel_PCPLUS4;
            `OPC_AUIPC     : regWBSel <= `WBSel_ALU;
            `OPC_LUI       : regWBSel <= `WBSel_ALU;

            default        : regWBSel <= `WBSel_ALU; // Resolve: What to do here?
        endcase
    end
    

endmodule