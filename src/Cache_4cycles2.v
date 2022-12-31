`include "util.vh"
`include "const.vh"

module cache #
(
    parameter LINES = 64,
    parameter CPU_WIDTH = `CPU_INST_BITS,
    parameter WORD_ADDR_BITS = `CPU_ADDR_BITS-`ceilLog2(`CPU_INST_BITS/8)
)
(
    input clk,
    input reset,

    input                       cpu_req_valid,
    output                      cpu_req_ready,
    input [WORD_ADDR_BITS-1:0]  cpu_req_addr,
    input [CPU_WIDTH-1:0]       cpu_req_data,
    input [3:0]                 cpu_req_write,

    output                      cpu_resp_valid,
    output [CPU_WIDTH-1:0]      cpu_resp_data,

    output                      mem_req_valid,
    input                       mem_req_ready,
    output [WORD_ADDR_BITS-1:`ceilLog2(`MEM_DATA_BITS/CPU_WIDTH)] mem_req_addr,
    output                           mem_req_rw,
    output                           mem_req_data_valid,
    input                            mem_req_data_ready,
    output [`MEM_DATA_BITS-1:0]      mem_req_data_bits,
    // byte level masking
    output [(`MEM_DATA_BITS/8)-1:0]  mem_req_data_mask,

    input                       mem_resp_valid,
    input [`MEM_DATA_BITS-1:0]  mem_resp_data
);

localparam IDLE         = 5'h00;
localparam RETRIEVE     = 5'h01;
localparam EVICT1       = 5'h02;
localparam EVICT2       = 5'h03;
localparam EVICT3       = 5'h04;
localparam EVICT4       = 5'h05;
localparam EVICT5       = 5'h06;
localparam FETCH1       = 5'h07;
localparam FETCH2       = 5'h08;
localparam FETCH3       = 5'h09;
localparam FETCH4       = 5'h0a;
localparam FETCH5       = 5'h0b;
localparam READ         = 5'h0c;
localparam FINISHREAD   = 5'h0d;
localparam WRITE        = 5'h0e;
localparam FINISHWRITE  = 5'h0f;
localparam START = 5'h1f;

reg [4:0] state;
reg [4:0] nextstate;

reg [7:0] valid;
reg [7:0] dirty;

// IDLE State Declaration
reg [31:0] receivedAddressReg;
reg [2:0] addressIndexReg;
reg [3:0] lookupAddressReg;
reg [31:0] lookupInputReg;
wire [31:0] lookupInput;
assign lookupInput = lookupInputReg;

// lookupSRAM
wire [3:0] lookupAddress;
assign lookupAddress = lookupAddressReg;

wire lookupRW;
reg lookupRWReg;
assign lookupRW = lookupRWReg;

reg [3:0] lookupBytemaskReg;
wire [3:0] lookupBytemask;
assign lookupBytemask = lookupBytemaskReg;
wire [31:0] lookupOutput;

reg [1:0] CLineIndexReg;
reg [1:0] MLineIndexReg;

// dataSRAM
reg [4:0] CReadAddressReg;
wire [4:0] CReadAddress;
assign CReadAddress = CReadAddressReg;
wire [4:0] CWriteAddress;
reg CReadWEBReg;
wire CReadWEB;
assign CReadWEB = CReadWEBReg;
reg [4:0] CWriteAddressReg;
assign CWriteAddress = CWriteAddressReg;
reg CWriteWEBReg;
wire CWriteWEB;
assign CWriteWEB = CWriteWEBReg;
wire [3:0] CReadByteMask;
wire [3:0] CWriteByteMask;
wire [31:0] CReadInput1;
wire [31:0] CReadInput2;
wire [31:0] CReadInput3;
wire [31:0] CReadInput4;
wire [31:0] CReadOutput1;
wire [31:0] CReadOutput2;
wire [31:0] CReadOutput3;
wire [31:0] CReadOutput4;
wire [31:0] CWriteInput1;
wire [31:0] CWriteInput2;
wire [31:0] CWriteInput3;
wire [31:0] CWriteInput4;
wire [31:0] CWriteOutput1;
wire [31:0] CWriteOutput2;
wire [31:0] CWriteOutput3;
wire [31:0] CWriteOutput4;

assign CWriteInput1 = mem_resp_data[31:0];
assign CWriteInput2 = mem_resp_data[63:32];
assign CWriteInput3 = mem_resp_data[95:64];
assign CWriteInput4 = mem_resp_data[127:96];
reg [3:0] CWriteByteMaskReg;
assign CWriteByteMask = CWriteByteMaskReg;
// RETRIEVE State Declarations
reg [31:0] CEvictAddressReg;

// EVICT States


reg [27:0] memReqAddrReg;
reg [`MEM_DATA_BITS-1:0] memReqDataBitsReg;
reg [15:0] memReqDataMaskReg;
reg memReqDataValidReg;
reg memReqRWReg;
reg memReqValidReg;
// FETCH States

// READ State
reg cpuRespValidReg;
reg [31:0] cpuRespDataReg;
assign cpu_resp_valid = cpuRespValidReg;
assign cpu_resp_data = cpuRespDataReg;
reg [1:0] sramChoiceReg;
// WRITE State


/*
Outside perspective begin
*/
reg cpuReqReadyReg;
assign cpu_req_ready = cpuReqReadyReg;
assign mem_req_addr = memReqAddrReg;
assign mem_req_data_bits = memReqDataBitsReg;
assign mem_req_data_mask = memReqDataMaskReg;
assign mem_req_data_valid = memReqDataValidReg;
assign mem_req_rw = memReqRWReg;
assign mem_req_valid = memReqValidReg;

/*
Outside perspective end
*/
always @(*) begin
    if (reset) begin
        state = START;
        nextstate = START;
        valid = 8'h00;
        dirty = 8'h00;
        memReqValidReg = 1'b0;
        cpuRespValidReg = 1'b1;
        cpuReqReadyReg = 1'b0;
        memReqDataValidReg = 1'b0;
    end else begin
        case (state)
            START : begin
                nextstate = IDLE;
            end
            IDLE : begin // 0
                cpuRespDataReg = 1'b0;
                
                cpuRespValidReg = 1'b0;
                if (cpu_req_valid) begin
                    cpuReqReadyReg = 1'b0;
                    nextstate = RETRIEVE;
                    receivedAddressReg = {cpu_req_addr, 2'b00};
                    addressIndexReg = receivedAddressReg[8:6];

                    // read from lookup
                    lookupAddressReg = {1'b0, addressIndexReg};
                    lookupRWReg = 1'b1; // READ

                end else begin
                    nextstate = IDLE;
                    cpuReqReadyReg = 1'b1;
                end
            end

            /*
            State:
                RETRIEVE

            Description:
                Now that data has been outputted from the lookupSRAM, we will see if the tags match and 
                move to the corresponding state.
            */
            RETRIEVE : begin // 1
                if (receivedAddressReg[31:9] == lookupOutput[31:9]) begin
                    if (|cpu_req_write) nextstate = WRITE;
                    else nextstate = READ;
                end else begin
                    if (~valid[addressIndexReg])  begin
                        nextstate = FETCH1; // no need to evict if the writing data is invalid.
                        memReqDataMaskReg = 16'hffff;

                    end else begin
                        if (dirty[addressIndexReg]) begin
                            nextstate = EVICT1;
                        end else begin
                            nextstate = FETCH1;
                        end

                    CEvictAddressReg = lookupOutput;
                    end
                    // write to lookup
                    // lookupAddressReg = {1'b0, addressIndexReg};
                    // Ensure no writes happen to lookup or data
                    lookupRWReg = 1'b1;
                    CWriteWEBReg = 1'b1;
                    lookupRWReg = 1'b0;
                    lookupBytemaskReg = 4'hf;
                    lookupInputReg = receivedAddressReg;
                    // No output on a write.   
                end
            end


            /*
            State:
                Evict1
            
            Description:
                Will read cache line 1.
            */
            EVICT1 : begin //2
                


                // Get data from CLine 1. 
                CLineIndexReg = 2'b00;
                CReadAddressReg = {addressIndexReg, CLineIndexReg};
                CReadWEBReg = 1'b1;
                // CReadByteMask = 4'hf;
                // CReadInput = ;
                nextstate = EVICT2;
            end

            /*
            State:
                Evict2

            Description:
                Will read cache line 2. Will write line 1 output to MM.
            */
            EVICT2 : begin //3
                // Write C Line 1 to M
                
                memReqRWReg = 1'b1; // Write to M
                memReqDataValidReg = 1'b1; // indicates a write
                MLineIndexReg = 2'b00;
                memReqAddrReg = {CEvictAddressReg[31:6], MLineIndexReg};
                memReqDataBitsReg = {CReadOutput4, CReadOutput3, CReadOutput2, CReadOutput1};
                memReqDataMaskReg = 16'hffff;
                if (mem_req_ready) begin
                    nextstate = EVICT3;
                end else begin
                    nextstate = EVICT2;
                end
                // Read C Line 2.
                CLineIndexReg = 2'b01;
                CReadAddressReg = {addressIndexReg, CLineIndexReg};
                CReadWEBReg = 1'b1;
                // CReadByteMask = 4'hf;
                // CReadInput = ;
            end


            EVICT3 : begin //4
                // Write C Line 2 to M
                MLineIndexReg = 2'b01;
                memReqAddrReg = {CEvictAddressReg[31:6], MLineIndexReg};
                memReqDataBitsReg = {CReadOutput4, CReadOutput3, CReadOutput2, CReadOutput1};
                memReqDataMaskReg = 16'hffff;
                if (mem_req_ready) begin
                    nextstate = EVICT4;
                end else begin
                    nextstate = EVICT3;
                end

                // Read C Line 3.
                CLineIndexReg = 2'b10;
                CReadAddressReg = {addressIndexReg, CLineIndexReg};
                CReadWEBReg = 1'b1;
                // CReadByteMask = 4'hf;
                // CReadInput = ;
            end

            EVICT4 : begin //5
                // Write C Line 3 to M
                MLineIndexReg = 2'b10;
                memReqAddrReg = {CEvictAddressReg[31:6], MLineIndexReg};
                memReqDataBitsReg = {CReadOutput4, CReadOutput3, CReadOutput2, CReadOutput1};
                memReqDataMaskReg = 16'hffff;
                if (mem_req_ready) begin
                    nextstate = EVICT5;
                end else begin
                    nextstate = EVICT4;
                end

                // Read C Line 4.
                CLineIndexReg = 2'b11;
                CReadAddressReg = {addressIndexReg, CLineIndexReg};
                CReadWEBReg = 1'b1;
                // CReadByteMask = 4'hf;
                // CReadInput = ;
            end

            EVICT5 : begin //6
                // Write C Line 4 to M
                MLineIndexReg = 2'b11;
                memReqAddrReg = {CEvictAddressReg[31:6], MLineIndexReg};
                memReqDataBitsReg = {CReadOutput4, CReadOutput3, CReadOutput2, CReadOutput1};
                memReqDataMaskReg = 16'hffff;
                if (mem_req_ready) begin
                    nextstate = FETCH1;
                end else begin
                    nextstate = EVICT5;
                end
            end

            FETCH1 : begin // 7 
                // Read Line 1 from M
                MLineIndexReg = 2'b00;
                memReqDataValidReg = 1'b0; // don't write
                memReqValidReg = 1'b1; // indicates a transaction
                // prep the inputs to M
                memReqAddrReg = {receivedAddressReg[31:6], MLineIndexReg};
                memReqRWReg = 1'b0; // READ
                if (mem_resp_valid) begin
                    // the inputs to the SRAMs are wire assigned.
                    CLineIndexReg = 2'b00;
                    CWriteAddressReg = {addressIndexReg, CLineIndexReg};
                    CWriteWEBReg = 1'b0;
                    CWriteByteMaskReg = 4'hf;
                    nextstate = FETCH2;
                end else begin
                    nextstate = FETCH1;
                end
            end

            FETCH2 : begin //8 
                // Data is still coming, so just set up the new address
                CLineIndexReg = 2'b01;
                CWriteAddressReg = {addressIndexReg, CLineIndexReg};
                nextstate = FETCH3;
                
            end

            FETCH3 : begin //9
                CLineIndexReg = 2'b10;
                CWriteAddressReg = {addressIndexReg, CLineIndexReg};
                nextstate = FETCH4;
                
                
            end

            FETCH4 : begin//a
                CLineIndexReg = 2'b11;
                CWriteAddressReg = {addressIndexReg, CLineIndexReg};
                if (|cpu_req_write) begin
                    nextstate = WRITE;
                end else begin
                    nextstate = READ;
                end
                memReqValidReg = 1'b0;


            end

            FETCH5 : begin //b
                
            end 

            READ : begin // c
                // Set up a read in the cache.
                CWriteWEBReg = 1'b1;
                
                //CReadWEBReg = 1'b1; 
                CReadAddressReg = receivedAddressReg[8:4];
                sramChoiceReg = receivedAddressReg[3:2];

                nextstate = FINISHREAD;
                
            end

            FINISHREAD : begin // d
                valid[addressIndexReg] = 1'b1;
                sramChoiceReg = receivedAddressReg[3:2];
                case (sramChoiceReg) 
                    2'b00: cpuRespDataReg = CReadOutput1;
                    2'b01: cpuRespDataReg = CReadOutput2;
                    2'b10: cpuRespDataReg = CReadOutput3;
                    2'b11: cpuRespDataReg = CReadOutput4;
                endcase
                cpuRespValidReg = 1'b1;
                nextstate = IDLE;
                cpuReqReadyReg = 1'b1;

            end

            WRITE : begin // e
                // Set up a write in the cache.
                CWriteWEBReg = 1'b0;
                valid[addressIndexReg] = 1'b1;
                dirty[addressIndexReg] = 1'b1;

                nextstate = FINISHWRITE;
            end
        endcase
    end
end

always @(posedge clk) begin
    state <= nextstate;
end




SRAM2RW16x32M lookupSRAM (
  .A1(lookupAddress),
  // A2,
  .CE1(clk),
  // CE2,
  .WEB1(lookupRW),
  // WEB2,
  .OEB1(1'b0),
  // OEB2,
  .CSB1(1'b0),
  // CSB2,
  .BYTEMASK1(lookupBytemask),
  // BYTEMASK2,
  .I1(lookupInput),
  // I2,
  .O1(lookupOutput)
  // O2
);

wire [3:0] fetch_bitmask;
assign fetch_bitmask = 4'hf;

SRAM2RW32x32M dataSRAM1 (
  .A1(CReadAddress),
  .A2(CWriteAddress),
  .CE1(clk),
  .CE2(clk),
  .WEB1(CReadWEB),
  .WEB2(CWriteWEB),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(CReadByteMask),
  .BYTEMASK2(CWriteByteMask),
  .I1(CReadInput1),
  .I2(CWriteInput1),
  .O1(CReadOutput1),
  .O2(CWriteOutput1)
);

SRAM2RW32x32M dataSRAM2 (
  .A1(CReadAddress),
  .A2(CWriteAddress),
  .CE1(clk),
  .CE2(clk),
  .WEB1(CReadWEB),
  .WEB2(CWriteWEB),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(CReadByteMask),
  .BYTEMASK2(CWriteByteMask),
  .I1(CReadInput2),
  .I2(CWriteInput2),
  .O1(CReadOutput2),
  .O2(CWriteOutput2)
);
SRAM2RW32x32M dataSRAM3 (
  .A1(CReadAddress),
  .A2(CWriteAddress),
  .CE1(clk),
  .CE2(clk),
  .WEB1(CReadWEB),
  .WEB2(CWriteWEB),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(CReadByteMask),
  .BYTEMASK2(CWriteByteMask),
  .I1(CReadInput3),
  .I2(CWriteInput3),
  .O1(CReadOutput3),
  .O2(CWriteOutput3)
);

SRAM2RW32x32M dataSRAM4 (
  .A1(CReadAddress),
  .A2(CWriteAddress),
  .CE1(clk),
  .CE2(clk),
  .WEB1(CReadWEB),
  .WEB2(CWriteWEB),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(CReadByteMask),
  .BYTEMASK2(CWriteByteMask),
  .I1(CReadInput4),
  .I2(CWriteInput4),
  .O1(CReadOutput4),
  .O2(CWriteOutput4)
);



endmodule