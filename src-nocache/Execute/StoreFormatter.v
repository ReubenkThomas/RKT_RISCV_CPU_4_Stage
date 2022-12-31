/*
Module:
    Store Formatter (StoreFormatter)

Description:
    Formats the data from RS2 to be correct given RS2 value and offset.
    Send into data port in DMEM

Inputs:
    inst_X: 32-bit instruction in the X Stage
    DataIn: 32-bit RS2 value
    ALUOutXTwoBit: 2-bit value that represents the last two bits of the ALUOutput
                   Determines how data is written with the write mask.
    
Output:
    StoreFormatterOut: 32-bit value that is the correctly formatted data.

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/




`include "Opcode.vh"
`include "ControlLogicSel.vh"
module StoreFormatter (
    input [31:0] inst_X,
    input [31:0] DataIn,
    input [1:0] ALUOutXTwoBit,
    output [31:0] StoreFormatterOut
);


    reg [31:0] regStoreFormatterOut;
    assign StoreFormatterOut = regStoreFormatterOut;
    always @(*) begin
        case (ALUOutXTwoBit)
            2'b00: regStoreFormatterOut <= DataIn;
            2'b01: regStoreFormatterOut <= DataIn << 8;
            2'b10: regStoreFormatterOut <= DataIn << 16;
            2'b11: begin
                if (inst_X[14:12] == `FNC_SB) begin
                    regStoreFormatterOut <= DataIn << 24; 
                end else begin 
                    regStoreFormatterOut <= DataIn << 16;
                end
            end
        endcase
    end
endmodule