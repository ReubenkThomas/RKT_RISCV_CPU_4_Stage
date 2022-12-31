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

  // Implement your cache here, then delete this comment
  /*************************************************************************************
  Cache implemented is a 512-Byte direct-mapped cache with write-through policy. Below is the explanation of all the I/O for the module. 

  clk 	              clock
  reset 	            reset
  cpu_req_valid 	    The CPU is requesting a memory transaction
  O cpu_req_ready 	      The cache is ready for a CPU memory transaction
  cpu_req_addr 	      The address of the CPU memory transaction
  cpu_req_data 	      The write data for a CPU memory write (ignored on reads)
  cpu_req_write 	    The 4-bit write mask for a CPU memory transaction (each bit corresponds to the byte address within the word). 4’b0000 indicates a read.
  
  O cpu_resp_valid 	      The cache has output valid data to the CPU after a memory read
  O cpu_resp_data 	    The data requested by the CPU
  
  O mem_req_valid 	      The cache is requesting a memory transaction to main memory
  mem_req_ready 	      Main memory is ready for the cache to provide a memory address
  O mem_req_addr 	      The address of the main memory transaction from the cache. Note that this address is narrower than the CPU byte address since main memory has wider data._
  O mem_req_rw 	        1 if the main memory transaction is a write; 0 for a read.
  O mem_req_data_valid 	The cache is providing write data to main memory.
  mem_req_data_ready 	Main memory is ready for the cache to provide write data.
  O mem_req_data_bits 	Data to write to main memory from the cache (128 bits/4 words).
  O mem_req_data_mask 	Byte-level write mask to main memory. May be 16’hFFFF for a full write.
  
  mem_resp_valid	      The main memory response data is valid.
  mem_resp_data 	    Main memory response data to the cache (128 bits/4 words).

  Planning:
  clk 	              clock
  reset 	            reset
  cpu_req_valid 	    given, should be ucache_re | (|ucache_we)
  cpu_req_rdy 	      use this to stall the cpu; required to be high to write into cache and mem; if the cache is not in fetch-from-memory mode, i.e. cache is fully valid
  cpu_req_addr 	      given
  cpu_req_data 	      The write data for a CPU memory write (ignored on reads)
  cpu_req_write 	    The 4-bit write mask for a CPU memory transaction (each bit corresponds to the byte address within the word). 4’b0000 indicates a read.
  cpu_resp_val 	      The cache has output valid data to the CPU after a memory read
  cpu_resp_data 	    The data requested by the CPU
  mem_req_val 	      The cache is requesting a memory transaction to main memory
  mem_req_rdy 	      Main memory is ready for the cache to provide a memory address
  mem_req_addr 	      The address of the main memory transaction from the cache. Note that this address is narrower than the CPU byte address since main memory has wider data._
  mem_req_rw 	        1 if the main memory transaction is a write; 0 for a read.
  mem_req_data_valid 	The cache is providing write data to main memory.
  mem_req_data_ready 	Main memory is ready for the cache to provide write data.
  mem_req_data_bits 	Data to write to main memory from the cache (128 bits/4 words).
  mem_req_data_mask 	Byte-level write mask to main memory. May be 16’hFFFF for a full write.
  mem_resp_val 	      The main memory response data is valid.
  mem_resp_data 	    Main memory response data to the cache (128 bits/4 words).

  *************************************************************************************/

localparam LOOKUP      = 5'h0;
localparam READSTART   = 5'h1; 
localparam WRITESTART  = 5'h2;
localparam EVICT1      = 5'h3;
localparam EVICT2      = 5'h4;
localparam EVICT3      = 5'h5;
localparam EVICT4      = 5'h6;
localparam EVICTDONE   = 5'h7;
localparam FETCH1      = 5'h8;
localparam WAIT1       = 5'h9;
localparam WAIT2       = 5'ha;
localparam WAIT3       = 5'hb;
localparam FETCH2      = 5'hc;
localparam FETCH3      = 5'hd;
localparam FETCH4      = 5'he;
localparam FETCHDONE   = 5'hf;
localparam FINISHREAD  = 5'h10;
localparam FINISHWRITE = 5'h11;
localparam IDLE        = 5'h12;
reg [4:0] state;
reg [4:0] nextstate;
reg [7:0] valid;
reg [7:0] dirty;


// Useful regs/wires
reg [31:0] receivedInstructionReg;
wire [31:0] receivedInstruction;
assign receivedInstruction = receivedInstructionReg;

reg [2:0] addrIndexReg;
wire [2:0] addrIndex;
assign addrIndex = addrIndexReg;

reg exitState;
//LOOKUP SRAM I/Os
reg [3:0] lookupAddressReg;
wire [3:0] lookupAddress;
assign lookupAddress = lookupAddressReg;

reg lookupRWReg;
wire lookupRW;
assign lookupRW = lookupRWReg;

reg [3:0] lookupBytemaskReg;
wire [3:0] lookupBytemask;
assign lookupBytemask = lookupBytemaskReg;

reg [31:0] lookupInputReg;
wire [31:0] lookupInput;
assign lookupInput = lookupInputReg;

wire [31:0] lookupOutput;
reg [31:0] lookupEvictAddr;
reg [31:0] lookupNewAddr;

// START READ/WRITE STATES
reg [1:0] sramChoiceReg;
wire [1:0] sramChoice;
assign sramChoice = sramChoiceReg;

// EVICT/FETCH REGS/WIRES
reg [1:0] CLineIndexReg;
wire [1:0] CLineIndex;
assign CLineIndex = CLineIndexReg;

reg [1:0] MLineIndexReg;
wire [1:0] MLineIndex;
assign MLineIndex = MLineIndexReg;

reg memReqRWReg;
assign mem_req_rw = memReqRWReg;

reg memReqDataValidReg;
assign mem_req_data_valid = memReqDataValidReg;

reg [3:0] memReqDataMaskReg;
assign mem_req_data_mask = 16'hffff;

reg memReqValidReg;
assign mem_req_valid = memReqValidReg;

reg [127:0] memRespDataReg;
wire [127:0] memRespData;
assign memRespData = memRespDataReg;

reg [27:0] MEvictAddr;
reg [27:0] MFetchAddr;

// wire [27:0] evict_addr;
// wire [27:0] fetch_addr;
// assign evict_addr = {lookupEvictAddr[31:6], MLineIndex};
// assign fetch_addr = {lookupNewAddr[31:6], MLineIndex};
// assign mem_req_addr = mem_req_rw ? evict_addr : fetch_addr; // assign based on if the operation to MM is a write

// assign mem_req_addr = mem_req_rw ? MEvictAddr : MFetchAddr;
reg [27:0] memReqAddrReg;
assign mem_req_addr = memReqAddrReg;

wire [127:0] cacheEjectLineData;
// FINISHREAD State
reg [4:0] sramAddrReg;
wire [4:0] sramAddr;
assign sramAddr = sramAddrReg;

reg cpuRespValidReg;
assign cpu_resp_valid = cpuRespValidReg;

reg [31:0] cpuRespDataReg;
assign cpu_resp_data = cpuRespDataReg;

reg cpuReqReadyReg;
// assign cpu_req_ready = cpuReqReadyReg;

wire [31:0] sramResp1;
wire [31:0] sramResp2;
wire [31:0] sramResp3;
wire [31:0] sramResp4;
wire sramMEn1;
wire sramMEn2;
wire sramMEn3;
wire sramMEn4;

wire sramCEn;
reg sramMEnReg1;
reg sramMEnReg2;
reg sramMEnReg3;
reg sramMEnReg4;

reg sramCEnReg;
assign sramCEn = sramCEnReg;
assign sramMEn1 =  sramMEnReg1;
assign sramMEn2 =  sramMEnReg2;
assign sramMEn3 =  sramMEnReg3;
assign sramMEn4 =  sramMEnReg4;


assign cpu_req_ready = state == LOOKUP;

// assign sramMEn1 = ~(|cpu_req_write & cpu_req_ready & (sramChoice == 2'b00));
// assign sramMEn2 = ~(|cpu_req_write & cpu_req_ready & (sramChoice == 2'b01));
// assign sramMEn3 = ~(|cpu_req_write & cpu_req_ready & (sramChoice == 2'b10));
// assign sramMEn4 = ~(|cpu_req_write & cpu_req_ready & (sramChoice == 2'b11));

reg [`MEM_DATA_BITS-1:0] memReqDataBitsReg;
assign mem_req_data_bits = memReqDataBitsReg;


always @(*) begin
    nextstate = state;
    // Set other initial states.
    if (reset) begin
        state <= LOOKUP;
        nextstate <= LOOKUP;
        valid <= 8'h00;
        dirty <= 8'h00; 
    end else begin
        case (state) 
            IDLE : begin
                nextstate = LOOKUP;
            end
            /*
            State:
                LOOKUP
            
            Description:
                We want to set up the LookupSRAM so that on the posedge clk, we will get a tag. 
                In addition, we will be moving to either the read/write state.
            */
            LOOKUP: begin // 0
                cpuRespValidReg = 1'b0;
                memReqValidReg = 1'b0; // Request a transaction
                sramMEnReg1 = 1'b1;
                sramMEnReg2 = 1'b1;
                sramMEnReg3 = 1'b1;
                sramMEnReg4 = 1'b1;
                if (cpu_req_valid) begin
                    // Determine the next state based on cpu_req_write.
                    if (|cpu_req_write) begin
                        nextstate <= WRITESTART;
                        exitState <= 1'b1; // Write
                    end else begin
                        nextstate <= READSTART;
                        exitState <= 1'b0; // Read
                    end

                    // Now set up the ports for the LookupSRAM
                    // A
                    receivedInstructionReg = {cpu_req_addr, 2'b00};
                    addrIndexReg = receivedInstruction[8:6];
                    lookupAddressReg = {1'b0, addrIndex};
                    sramChoiceReg = receivedInstruction[3:2];
                    sramAddrReg = receivedInstruction[8:4];

                    // I. No input
                    // WEn. Read mode
                    lookupRWReg = 1'b1; // READ MODE.
                    // O will output it to lookupOutput, so nothing to do here.
                end else nextstate = LOOKUP;
            end

            /*
            State:
                READSTART
            
            Description:
                Now that the lookupSRAM has given an output, it it time to see if the
                receivedInstruction agrees with the output.
            */
            READSTART: begin //1
                
                if (receivedInstruction[31:9] == lookupOutput[31:9]) begin
                    // They match. 
                    nextstate = FINISHREAD;
                    // Get the SRAM the instruction belongs to.

                end else begin
                    // memReqValidReg = 1'b1; // Request a transaction

                    // If they do not match.
                    nextstate = EVICT1;
                    
                    // Here is the eviction tag. So begin by writing a new entry to the
                    // LookupSRAM.
                    lookupEvictAddr <= lookupOutput; // For MM things. If needed to writeback.
                    lookupNewAddr <= receivedInstruction; // This is the new A
                    lookupAddressReg <= {1'b0, addrIndex};
                     lookupBytemaskReg <= 4'hf;
                    lookupInputReg <= receivedInstruction; // This is the new I.
                    lookupRWReg <= 1'b0; // WRITE MODE.         

                    // Data is now written in the LookupSRAM 
                end
                
            end
            /*
            WRITESTART means we noticed that we are doing a write (handled by |cpu_req_write = 1'b1).

            If we are writing, then what will happen is that we will have gotten the tag from the 
            lookupSRAM, since that was done in the IDLE state. Now it will see if it needs to go
            through the eviction/fetching process.

            If the tags do match, it will go to finishwrite state, where it will write and dirty the
            cache line.

            Otherwise, it will have to go through the E.F process, and then go to finishwrite at the end
            of it.
            */
            WRITESTART: begin // 2
            
                if (receivedInstruction[31:9] == lookupOutput[31:9]) begin
                    nextstate <= FINISHWRITE;
                end else begin
                    nextstate <= EVICT1;
                end
            end
            /*
            State:
                EVICT1
            
            Description:
                This one will start evicting a block of data from the cache. A block of data is 4 lines,
                so there will need to be 4 total reads. This will be spread out on each EVICT state
                (EVICT1, EVICT2, EVICT3, EVICT4). At the end of this cycle, there should be a data output 
                in the dataSRAMs. A line of data is 128 bits, or 4 words. By the end of the evict
                states, these words will be written to MM in EVICTDONE.
            */
            EVICT1: begin // 3 Read cache 
                CLineIndexReg = 2'b00; // First line
                sramCEnReg = 1'b1; // Read
                nextstate = EVICT2;
            end

            /*
            State:
                EVICT2
            
            Description:
                While the reading is happening from the cache, we will start writing the data to MM.
                Note that we only will write if the data is valid and dirty (you might not even have
                to check for dirty). The valid bit is for when the cache starts cold and there is
                garbage in the caches. Once new data has been fetched, then the value becomes valid
                and will remain like that for the rest of the program. Valid data means that it can
                and should write to MM.
            */
            EVICT2: begin // 4 Read cache, Write to MM if valid
                // MM Writing. Make a write transaction with MM.

                memReqRWReg = valid[addrIndex[2:0]] & dirty[addrIndex[2:0]]; // WRITE MODE.
                if (mem_req_ready) begin
                    MLineIndexReg = 2'b00; // Location to write to main memory.
                    memReqAddrReg = {lookupEvictAddr[31:6], MLineIndex};
                end 

                if (mem_req_data_ready) begin
                    memReqDataBitsReg = cacheEjectLineData;
                end
                
                // Cache Reading
                CLineIndexReg = 2'b01; // Second Line

                // Moving to the next state.
                if (mem_req_ready & (mem_req_data_ready | exitState == 1'b0)) begin
                    nextstate = EVICT3;
                end else begin
                    nextstate = EVICT2;
                end
                

            end
            EVICT3: begin // 5 Read cache, Write to MM if valid
                // MM Writing. Make a write transaction with MM.
                memReqDataValidReg = 1'b0;
                memReqRWReg = valid[addrIndex[2:0]] & dirty[addrIndex[2:0]]; // WRITE MODE
                MLineIndexReg = 2'b01; // Location to write to main memory.
                memReqAddrReg = {lookupEvictAddr[31:6], MLineIndex};

                if (mem_req_data_ready) begin
                    memReqDataBitsReg = cacheEjectLineData;
                    memReqDataValidReg = 1'b1;
                end
                
                // Cache Reading
                CLineIndexReg = 2'b10; // Second Line

                // Moving to the next state.
                if (mem_req_ready & (mem_req_data_ready | exitState == 1'b0)) begin
                    nextstate = EVICT4;
                end else begin
                    nextstate = EVICT3;
                end
            end
            EVICT4: begin // 6 Read cache, Write to MM if valid
                memReqDataValidReg = 1'b0;
                memReqRWReg = valid[addrIndex[2:0]] & dirty[addrIndex[2:0]]; // WRITE MODE
                MLineIndexReg = 2'b10; // Location to write to main memory.
                memReqAddrReg = {lookupEvictAddr[31:6], MLineIndex};
                
                if (mem_req_data_ready) begin
                    memReqDataBitsReg = cacheEjectLineData;
                    memReqDataValidReg = 1'b1;
                end
                
                // Cache Reading
                CLineIndexReg = 2'b11; // Second Line

                // Moving to the next state.
                if (mem_req_ready & (mem_req_data_ready | exitState == 1'b0)) begin
                    nextstate = EVICTDONE;
                end else begin
                    nextstate = EVICT4;
                end
            end
            EVICTDONE: begin // 7 Write to MM if valid
                memReqDataValidReg = 1'b0;
                memReqRWReg = valid[addrIndex[2:0]] & dirty[addrIndex[2:0]]; // WRITE MODE
                MLineIndexReg = 2'b11; // Location to write to main memory.
                memReqAddrReg = {lookupEvictAddr[31:6], MLineIndex};
                if (mem_req_data_ready) begin
                    memReqDataBitsReg = cacheEjectLineData;
                    memReqDataValidReg = 1'b1;
                end

                // Moving to the next state.
                if (mem_req_ready & (mem_req_data_ready | exitState == 1'b0)) begin
                    nextstate = FETCH1;
                end else begin
                    nextstate = EVICTDONE;
                end

                // Any other things before Fetch?
            end
            /*
            State:
                Fetch1
            
            Description:
                The fetching state will use the new tag and pull it from memory, and write it to the cache.
                By writing to the cache, the data at that block will now be valid.

            */
            FETCH1: begin // 8 Read MM

                memReqValidReg = 1'b1; // Request a transaction
                memReqRWReg = 1'b1; // READ MODE
                if (mem_resp_valid) begin
                    MLineIndexReg = 2'b00;
                    memReqAddrReg = {lookupNewAddr[31:6], MLineIndex};
                    memRespDataReg = mem_resp_data;
                    nextstate = WAIT1;
                end else begin
                    nextstate = FETCH1;
                end
            end
            WAIT1: begin // 9
                nextstate = WAIT2;
            end
            

            WAIT2: begin // a
                nextstate = WAIT3;
            end

            WAIT3: begin // b
                nextstate = FETCH2;
            end

            


            /*
            State:
                Fetch2
            
            Description:
                This fetching state will now write to the caches, and then request another read to MM.
            */
            FETCH2: begin // c Read MM, Write to cache
                MLineIndexReg = 2'b01;
                

                MFetchAddr = {lookupNewAddr[31:6], MLineIndex};
                memRespDataReg = mem_resp_data;
                nextstate = FETCH3;


                sramCEnReg = 1'b0;// Write

                // Now write to Cache.

                CLineIndexReg = 2'b00; // addr_index,

                
                
            end
            FETCH3: begin // d Read MM, Write to cache
                MLineIndexReg = 2'b10;
                MFetchAddr = {lookupNewAddr[31:6], MLineIndex};
                memRespDataReg = mem_resp_data;
                nextstate = FETCH4;

                // Now write to Cache.

                CLineIndexReg = 2'b01;

            end
            FETCH4: begin // e Read MM, Write to cache
                MLineIndexReg = 2'b11;
                MFetchAddr = {lookupNewAddr[31:6], MLineIndex};
                memRespDataReg = mem_resp_data;
                nextstate = FETCHDONE;

                // Now write to Cache.
                CLineIndexReg = 2'b10;

            end
            FETCHDONE: begin // f Write to cache
                // Now write to Cache.
                CLineIndexReg = 2'b11;

                if (exitState) begin
                    nextstate = FINISHWRITE;
                end else begin
                    nextstate = FINISHREAD;
                end
                memReqRWReg = 1'b0;
                memReqValidReg = 1'b0;
                
            end

            /*
            State:
                FINISHREAD
            
            Description:
                Either the tags were the same, or the new block is fetched. Either way, this state will do the same thing.
                It knows that the received address will give the right data in the cache, so just make a read and output
                it to the CPU. Move the state to LOOKUP. 
            */
            FINISHREAD: begin // 10
                // Get the right locations in the SRAMs
                sramCEnReg = 1'b1;
                // Set the thing to ready
                cpuRespValidReg = 1'b1;
                // Set the output data.
                valid[addrIndex] <= 1'b1;
                // Set next state.
                nextstate = LOOKUP;
                // cpuReqReadyReg = 1'b1;

            end
            FINISHWRITE: begin // 11
                // Write
                // dirty the location 
                dirty[addrIndex] <= 1'b1;
                // Set the thing to ready
                cpuRespValidReg <= 1'b1;
                // Set output data (to what?)
                // Set next state
                
                nextstate = LOOKUP;
            end
        endcase
    end
end

always @(*) begin
    case (sramChoice)
        2'b00 : cpuRespDataReg <= sramResp1; 
        2'b01 : cpuRespDataReg <= sramResp2;
        2'b10 : cpuRespDataReg <= sramResp3;
        2'b11 : cpuRespDataReg <= sramResp4;
    endcase
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

// 1 is cache reads
// 2 is cache writes
SRAM2RW32x32M dataSRAM1 (
  .A1({addrIndex, CLineIndex}),
  .A2(sramAddr),
  .CE1(clk),
  .CE2(clk),
  .WEB1(sramCEn),
  .WEB2(sramMEn1),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(fetch_bitmask),
  .BYTEMASK2(cpu_req_write),
  .I1(memRespData[31:0]),
  .I2(cpu_req_data),
  .O1(cacheEjectLineData[31:0]),
  .O2(sramResp1)
);

SRAM2RW32x32M dataSRAM2 (
  .A1({addrIndex, CLineIndex}),
  .A2(sramAddr),
  .CE1(clk),
  .CE2(clk),
  .WEB1(sramCEn),
  .WEB2(sramMEn2),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(fetch_bitmask),
  .BYTEMASK2(cpu_req_write),
  .I1(memRespData[63:32]),
  .I2(cpu_req_data),
  .O1(cacheEjectLineData[63:32]),
  .O2(sramResp2)
);
SRAM2RW32x32M dataSRAM3 (
  .A1({addrIndex, CLineIndex}),
  .A2(sramAddr),
  .CE1(clk),
  .CE2(clk),
  .WEB1(sramCEn),
  .WEB2(sramMEn3),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(fetch_bitmask),
  .BYTEMASK2(cpu_req_write),
  .I1(memRespData[95:64]),
  .I2(cpu_req_data),
  .O1(cacheEjectLineData[95:64]),
  .O2(sramResp3)
);
SRAM2RW32x32M dataSRAM4 (
  .A1({addrIndex, CLineIndex}),
  .A2(sramAddr),
  .CE1(clk),
  .CE2(clk),
  .WEB1(sramCEn),
  .WEB2(sramMEn4),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(fetch_bitmask),
  .BYTEMASK2(cpu_req_write),
  .I1(memRespData[127:96]),
  .I2(cpu_req_data),
  .O1(cacheEjectLineData[127:96]),
  .O2(sramResp4)
);
endmodule