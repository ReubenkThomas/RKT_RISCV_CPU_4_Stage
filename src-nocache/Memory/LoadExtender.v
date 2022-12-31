/*
Module:
    Load Extender (LoadExtender)

Description:
    Given a word of data from the DMEM, the load extender will format the word into the appropriate form given LdSel

Inputs:
    LdIn: 32-bit data output by the DMEM. The DMEM will deal with all the possible data formatting that goes along
           with pulling the word from memory.
    LdSel: 3-bit control signal that determines the load type and tells the LoadExtender how to cnostruct the data.
    ALUOutMTwoBit: 2-bit value from the ALUOutput in the M stage useful for determining the affect of the offset.

Output:
    LdOut: 32-bit correctly extended data. 

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "Opcode.vh"

module LoadExtender(
    input [31:0] LdIn,
    input [2:0] LdSel,
    input [1:0] ALUOutMTwoBit,
    output [31:0] LdOut
);

    wire [31:0] signed_byte;
    wire [31:0] unsigned_byte;
    wire [31:0] signed_halfword;
    wire [31:0] unsigned_halfword;
    wire [31:0] word;
    wire [31:0] data;


    wire [4:0] off;


    
    assign data = LdIn >> off;
    assign signed_byte = (data[7]) ? {{24{1'b1}}, {data[7:0]}} : {{24{1'b0}}, {data[7:0]}};
    assign unsigned_byte = {{24{1'b0}}, data[7:0]};
    assign signed_halfword = (data[15]) ? {{16{1'b1}}, {data[15:0]}} : {{16{1'b0}}, {data[15:0]}};
    assign unsigned_halfword = {{16{1'b0}}, {data[15:0]}};
    assign word = data;
    assign off = (ALUOutMTwoBit[1:0] == 2'b11 & (LdSel == `FNC_LH | LdSel == `FNC_LHU)) ? ALUOutMTwoBit[1] << 3'b100 : ALUOutMTwoBit[1:0] << 2'b11; 

    reg[31:0] Out_R;
    assign LdOut = Out_R;

    always @(*) begin
        case(LdSel) 
            `FNC_LB   : Out_R <= signed_byte;
            `FNC_LBU  : Out_R <= unsigned_byte;
            `FNC_LH   : Out_R <= signed_halfword;
            `FNC_LHU  : Out_R <= unsigned_halfword;
            `FNC_LW   : Out_R <= word;
            default   : Out_R <= word;
        endcase


        
    end


endmodule
