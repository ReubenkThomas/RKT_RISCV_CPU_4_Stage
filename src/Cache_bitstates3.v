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
  O cpu_req_rdy 	      The cache is ready for a CPU memory transaction
  cpu_req_addr 	      The address of the CPU memory transaction
  cpu_req_data 	      The write data for a CPU memory write (ignored on reads)
  cpu_req_write 	    The 4-bit write mask for a CPU memory transaction (each bit corresponds to the byte address within the word). 4’b0000 indicates a read.
  
  O cpu_resp_val 	      The cache has output valid data to the CPU after a memory read
  O cpu_resp_data 	    The data requested by the CPU
  
  O mem_req_val 	      The cache is requesting a memory transaction to main memory
  mem_req_rdy 	      Main memory is ready for the cache to provide a memory address
  O mem_req_addr 	      The address of the main memory transaction from the cache. Note that this address is narrower than the CPU byte address since main memory has wider data._
  O mem_req_rw 	        1 if the main memory transaction is a write; 0 for a read.
  O mem_req_data_valid 	The cache is providing write data to main memory.
  mem_req_data_ready 	Main memory is ready for the cache to provide write data.
  O mem_req_data_bits 	Data to write to main memory from the cache (128 bits/4 words).
  O mem_req_data_mask 	Byte-level write mask to main memory. May be 16’hFFFF for a full write.
  
  mem_resp_val 	      The main memory response data is valid.
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
// yaa
wire [31:0] lookupReadData;
reg lookupSRAM_rewe;

wire [31:0] received_inst = {cpu_req_addr, 2'd0}; 
// the index for instruction to look at
wire [2:0] addr_index;
assign addr_index = received_inst[8:6];

wire [3:0] lookup_addy;
assign lookup_addy = {1'b0, addr_index}; 


// each ith bit of dirtyBits corresponds to the dirty bit of index i
reg [7:0] dirtyBits;

// valid bits
reg [7:0] validBits;


// checks if the tag in cache is the same.
wire is_tag_same;
assign is_tag_same = received_inst[31:9] == lookupReadData[31:9];


wire [1:0] sram_choice;
assign sram_choice = received_inst[3:2];

wire is_write;
wire is_read;
assign is_write = (|cpu_req_write) & cpu_req_valid;
assign is_read = ~(|cpu_req_write) & cpu_req_valid;

reg [1:0] write_SRAMSelector;


wire edge_case_stall;

// write to cache
wire [31:0] sram1_resp;
wire [31:0] sram2_resp;
wire [31:0] sram3_resp;
wire [31:0] sram4_resp;
wire we_sram1;
wire we_sram2;
wire we_sram3;
wire we_sram4;

// a 10 bit FSM that controls the state of the cache when processing evictions
reg [9:0] fetch_state;


wire [1:0] sram_write_read_choice;
wire [4:0] sram_write_read_addr;

// choice of SRAM
assign sram_write_read_choice = received_inst[3:2];

// 
assign sram_write_read_addr = received_inst[8:4];

// use as the correct data to be read from the srams during a read
reg [31:0] read_data_chosen;

// SRAM address for catch-to-memory interactions
wire [4:0] sram_fetch_addr;

// Indicates which line in the cacheblock to fetch from
wire [1:0] sram_fetch_line_index_MM;

// To write memory data into the srams
wire sram_fetch_we;

// data line that gets sent back to MM during evictions
wire [127:0] cache_eject_line_data;

reg [31:0] evicting_tag_addr; // address with tag whose block is being evicted to MM
reg [31:0] new_tag_addr; // address with tag whose block is being fetch from MM
wire [27:0] fetch_addr; // read from mem
wire [27:0] evict_addr; // write to mem

// bitmask for fetching data from MM and storing into SRAMs (should be F if reading from MM else 0)
wire [3:0] fetch_bitmask;
assign fetch_bitmask = 4'hF; // fetch_bitmask is always F since any write to that channel is to write the whole line


// data line that gets sent back to MM during evictions
reg [127:0] mem_incoming_hold;
always @(*) begin
  if (~sram_fetch_we) begin
    mem_incoming_hold <= mem_resp_data;
  end
end

reg [31:0] lastInstruction;
always @(posedge clk) begin
  // if 
  lastInstruction <= received_inst;

end

// reg resetReg;

// always @(posedge clk) begin
//   resetReg <= reset;
// end


// SRAM contains the current TAG for the cacheblocks. 
// SRAM is synchronous
// At posedge, the data is read from the datSRAM and the tag is read from lookupSRAM.
// If tag is equal, declare data as valid and read at negedge (else dont declare data as valid)
// If tag is not equal, then declare data as not valid
SRAM2RW16x32M lookupSRAM (
  .A1(lookup_addy),
  // A2,
  .CE1(clk),
  // CE2,
  .WEB1(lookupSRAM_rewe),
  // WEB2,
  .OEB1(1'b0),
  // OEB2,
  .CSB1(1'b0),
  // CSB2,
  .BYTEMASK1(4'b1111),
  // BYTEMASK2,
  .I1(received_inst),
  // I2,
  .O1(lookupReadData)
  // O2
);


// reset logic
always @(posedge clk) begin
  if (reset) begin
    // mem_to_cache_clk_index <= 2'd0;
    // TODO
    // set dirtyBits to 1s -> all data is dirty after a reset
    
    // lookupSRAM_rewe <= 0;
    // sets state to 0
    validBits <= 8'h00;
    fetch_state <= 10'd0;
    dirtyBits <= 8'hFF;
  end
  end


// TODO - CHECK 
always @(*) begin
  // if (~resetReg) begin
  if (~is_tag_same & cpu_req_valid & ~reset) begin
    // if (clk) begin
      // if (fetch_state[8]) begin
      fetch_state[9] <= 1;
      // end
      evicting_tag_addr <= lookupReadData; // throws the old tag into a holding reg
      new_tag_addr <= received_inst;
      lookupSRAM_rewe <= 0;
    // end
    end else begin
      lookupSRAM_rewe <= 1;
      fetch_state[9] <= 0;
    end  
  // end else begin
  //   fetch_state <= 10'd0;
  //   dirtyBits <= 8'hFF;
  // end
end



// for CPU to Cache
assign we_sram1 = ~(is_write & cpu_req_ready & (sram_write_read_choice == 2'b00));
assign we_sram2 = ~(is_write & cpu_req_ready & (sram_write_read_choice == 2'b01));
assign we_sram3 = ~(is_write & cpu_req_ready & (sram_write_read_choice == 2'b10));
assign we_sram4 = ~(is_write & cpu_req_ready & (sram_write_read_choice == 2'b11));

// triggered to set to dirty bit to one if any we_sram is high
// TODO, fix timing to account for all cases
always @(*) begin
  if (is_write & cpu_req_ready) begin
    dirtyBits[addr_index] <= 1;
  end
end



always @* begin
  case (sram_write_read_choice)
    2'b00: read_data_chosen <= sram1_resp;
    2'b01: read_data_chosen <= sram2_resp;
    2'b10: read_data_chosen <= sram3_resp;
    2'b11: read_data_chosen <= sram4_resp;
  endcase
end

always @(posedge clk) begin
  fetch_state = fetch_state >> 1;
end

assign mem_req_valid = (| fetch_state[8:1]);
assign mem_req_rw = (| fetch_state[8:5]) & validBits[addr_index] & dirtyBits[addr_index];
assign mem_req_data_valid = (| fetch_state[8:5]);


assign sram_fetch_line_index_MM = (fetch_state[8] | fetch_state[4]) ? 2'd0 : (fetch_state[7] | fetch_state[3]) ? 2'd1 : (fetch_state[6] | fetch_state[2]) ? 2'd2 : 2'd3;

wire [1:0] sram_fetch_line_index_cache;
assign sram_fetch_line_index_cache = (fetch_state[9] | fetch_state[3]) ? 2'd0 : (fetch_state[8] | fetch_state[2]) ? 2'd1 : (fetch_state[7] | fetch_state[1]) ? 2'd2 : 2'd3;

assign sram_fetch_addr = {addr_index, sram_fetch_line_index_cache};


// assign sram_fetch_we = (| fetch_state[3:0]);


assign mem_req_data_bits = cache_eject_line_data;



// CONTROVERSIAL AND HIGHLY PROBLEMATIC TODO
// address for memory
assign evict_addr = {evicting_tag_addr[31:6], sram_fetch_line_index_MM};
assign fetch_addr = {new_tag_addr[31:6], sram_fetch_line_index_MM};
assign mem_req_addr = mem_req_rw ? evict_addr : fetch_addr; // assign based on if the operation to MM is a write

// data_mask for MM should be FFFF if writing to memory, else 0 (for safety)
// assign mem_req_data_mask = mem_req_rw ? 16'hFFFF : 16'h0000;
assign mem_req_data_mask = 16'hFFFF;


assign sram_fetch_we = ~(| fetch_state[3:0]);

reg sram_mem_interface_we;
// always @(posedge clk) begin
//   if (~sram_fetch_we) begin
//     sram_mem_interface_we <= 1'b0;
//   end
// end
always @(negedge clk) begin
  if (sram_fetch_we) begin
    sram_mem_interface_we <= 1'b1;
  end else sram_mem_interface_we <= 1'b0;
end

// can only make a cpu request transaction if there is no writing or reading between memory or cache


// always @(posedge clk) begin
//   if (~reset) begin
  
//   end 
// end

assign cpu_req_ready = ~(| fetch_state);

// can only output valid data to CPU if the instruction is currently a read, there is no cache fetching, and the tag is equal
assign cpu_resp_valid = is_read & ~(| fetch_state) & is_tag_same;

// sets the dirty bit for the index-th cache block to 0 alongside the final write to the cache
wire fetch_0;
assign fetch_0 = fetch_state[0];
always @(posedge sram_fetch_we) begin
    dirtyBits[addr_index] <= 1'b0;
    validBits[addr_index] <= 1'b1;
end


assign edge_case_stall = (reset) ? 1'b0 : lastInstruction[8:6] != received_inst[8:6];
// always @(*) begin
//   if (reset) begin
//     edge_case_stall <= 1'b0;
//   end else begin
//     edge_case_stall <= lastInstruction[8:6] != received_inst[8:6];
//   end
// end


assign cpu_resp_data = read_data_chosen;


SRAM2RW32x32M dataSRAM1 (
  .A1(sram_fetch_addr),
  .A2(sram_write_read_addr),
  .CE1(clk),
  .CE2(~clk),
  .WEB1(sram_mem_interface_we),
  .WEB2(we_sram1),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(fetch_bitmask),
  .BYTEMASK2(cpu_req_write),
  .I1(mem_incoming_hold[31:0]),
  .I2(cpu_req_data),
  .O1(cache_eject_line_data[31:0]),
  .O2(sram1_resp)
);

SRAM2RW32x32M dataSRAM2 (
  .A1(sram_fetch_addr),
  .A2(sram_write_read_addr),
  .CE1(clk),
  .CE2(~clk),
  .WEB1(sram_mem_interface_we),
  .WEB2(we_sram2),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(fetch_bitmask),
  .BYTEMASK2(cpu_req_write),
  .I1(mem_incoming_hold[63:32]),
  .I2(cpu_req_data),
  .O1(cache_eject_line_data[63:32]),
  .O2(sram2_resp)
);

SRAM2RW32x32M dataSRAM3 (
  .A1(sram_fetch_addr),
  .A2(sram_write_read_addr),
  .CE1(clk),
  .CE2(~clk),
  .WEB1(sram_mem_interface_we),
  .WEB2(we_sram3),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(fetch_bitmask),
  .BYTEMASK2(cpu_req_write),
  .I1(mem_incoming_hold[95:64]),
  .I2(cpu_req_data),
  .O1(cache_eject_line_data[95:64]),
  .O2(sram3_resp)
);

SRAM2RW32x32M dataSRAM4 (
  .A1(sram_fetch_addr),
  .A2(sram_write_read_addr),
  .CE1(clk),
  .CE2(~clk),
  .WEB1(sram_mem_interface_we),
  .WEB2(we_sram4),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(fetch_bitmask),
  .BYTEMASK2(cpu_req_write),
  .I1(mem_incoming_hold[127:96]),
  .I2(cpu_req_data),
  .O1(cache_eject_line_data[127:96]),
  .O2(sram4_resp)
);


endmodule
