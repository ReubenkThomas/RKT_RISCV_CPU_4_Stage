/*
Module:
    Register File (RegFile)

Desc: 
    All 32, 32-bit registers for the RISC-V Processor.

Inputs:
    RegWriteData: The 32-bit data being written to a register.
    RegWriteIndex: The register that the RegWriteData will be written to.
    RegReadIndex1: The register rs1 that will be read from
    RegReadIndex2: The register rs2 that will be read from
    RegWEn: Control signal that determines if data should be written to it.
    clk: clock
    reset: if on, resets all registers to 0.

Outputs:
    RegReadData1: 32-bit data read from the register specified at RegReadIndex1
    RegReadData2: 32-bit data read from the register specified at RegReadIndex2

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

`include "RegNames.vh"

module RegFile(
    input [31:0] RegWriteData,
    input [4:0] RegWriteIndex,
    input [4:0] RegReadIndex1,
    input [4:0] RegReadIndex2,
    input RegWEn,
    input clk,
    input reset,
    output [31:0] RegReadData1,
    output [31:0] RegReadData2


    // Ready-Valid Handshake
    // input read_val1,
    // input read_val2,
    // output read_rdy1,
    // output read_rdy2,
    // output read_val,
    // input read_inputs_val,

    // input write_val1,
    // input write_rdy1
);

    localparam DEPTH = 32;
    reg [31:0] mem [DEPTH-1:0];
    // wire [31:0] debugx0;
    // wire [31:0] debugx1;
    // wire [31:0] debugx2;
    // wire [31:0] debugx25;

    // read after write DONE
        // have write_done value DONE
        // write_ready is high when value is written in 
    // reg write_done;
    
    // assign read_val = write_done & read_inputs_val;
    // TODO: add a outputs_val mem
        // make this 1 after write_done is 1 and value has been read

    // does the index inputs need rdy values


    assign RegReadData1 = mem[RegReadIndex1];
    assign RegReadData2 = mem[RegReadIndex2];

    always @(posedge clk) begin
        if (RegWriteIndex == 0) begin
            mem[RegWriteIndex] <= 0;
        end else if (RegWEn) mem[RegWriteIndex] <= RegWriteData;
    end
    
    always @(posedge reset) begin
        mem[0]  <= 0;
        mem[1]  <= 0;
        mem[2]  <= 0;
        mem[3]  <= 0;
        mem[4]  <= 0;
        mem[5]  <= 0;
        mem[6]  <= 0;
        mem[7]  <= 0;
        mem[8]  <= 0;
        mem[9]  <= 0;
        mem[10] <= 0;
        mem[11] <= 0;
        mem[12] <= 0;
        mem[13] <= 0;
        mem[14] <= 0;
        mem[15] <= 0;
        mem[16] <= 0;
        mem[17] <= 0;
        mem[18] <= 0;
        mem[19] <= 0;
        mem[20] <= 0;
        mem[21] <= 0;
        mem[22] <= 0;
        mem[23] <= 0;
        mem[24] <= 0;
        mem[25] <= 0;
        mem[26] <= 0;
        mem[27] <= 0;
        mem[28] <= 0;
        mem[29] <= 0;
        mem[30] <= 0;
        mem[31] <= 0;
    end


endmodule