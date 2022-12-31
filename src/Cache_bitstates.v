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

localparam READ = 1'b1;
localparam WRITE = 1'b0;

wire [31:0] lookupReadData;

wire [31:0] received_instruction;
assign received_instruction = {cpu_req_addr, 2'b00};

// The received instruction is made up of 32 bits, however, 8:6 is the index
wire [2:0] addr_index;
assign addr_index = received_instruction[8:6];

// The lookup address is a 4 byte value, where the last 3 is the index of the lookup SRAM
wire [3:0] lookup_addy;
assign lookup_addy = {1'b0, addr_index};

// comparison of the tags. Note that before a clock, is_tag_same might be garbage.
wire is_tag_same;
assign is_tag_same = received_instruction[31:9] == lookupReadData[31:9];

// 1 is Read, 0 is Write
wire lookupSRAM_rewe;
assign lookupSRAM_rewe = (is_tag_same == 1'b0 & cpu_req_valid & ~reset) ? WRITE : READ;

// This is the lookupSRAM
// Inputs
// - A1: lookup_addy: 4-bit value that says 
// - CE1: clk
// - WEB1: Will only write to this SRAM if the tags are not the same and the CPU is making a request.
//         Means that there will be a new transaction made (eviction + fetch).
// - BYTEMASK1: Will be set to 4 indicating to write everything, always.
// - I1: 32-bit instruction that is received.
// - O1: 32-bit instruction outputted. 

SRAM2RW16x32M lookupSRAM (
    .A1(lookup_addy),
    .CE1(clk),
    .WEB1(lookupSRAM_rewe),
    .OEB1(1'b0),
    .CSB1(1'b0),
    .BYTEMASK1(4'b1111),
    .I1(received_instruction),
    .O1(lookupReadData)
);

// Now let's show the setup and state machine.
// At reset all are dirtied and invalid.
// At reset there is nothing in the state.
reg [7:0] dirty_bits;
reg [7:0] valid_bits;
reg [9:0] fetch_state;
reg [31:0] evicted_tag_reg;
reg [31:0] new_tag_reg;

wire [31:0] evicted_tag;
wire [31:0] new_tag;
assign evicted_tag = evicted_tag_reg;
assign new_tag = new_tag_reg;


reg [127:0] mem_incoming_hold_reg;
wire [127:0] mem_incoming_hold;
assign mem_incoming_hold = mem_incoming_hold_reg;


wire sram_fetch_we;
assign sram_fetch_we = ~(| fetch_state[3:0]);
wire sram_mem_interface_we;
reg sram_mem_interface_we_reg;
assign sram_mem_interface_we = sram_mem_interface_we_reg;


wire is_write;
wire is_read;
assign is_write = (|cpu_req_write) & cpu_req_valid;
assign is_read = ~(|cpu_req_write) & cpu_req_valid;


always @(negedge clk) begin
    if (sram_fetch_we) begin
        sram_mem_interface_we_reg <= 1'b1;
    end else begin
        sram_mem_interface_we_reg <= 1'b0;
    end
end





// The state will always move, and whenever there is a 1, then we are doing an eviction/fetch combo.
// This will finish once there is no 1. 
// If there is a 1, alot of the things will stall until there is not.
// The sequential clock also keeps track of the last instruction
wire [31:0] last_instruction;
reg [31:0] last_instruction_reg;
assign last_instruction = last_instruction_reg;

always @(posedge clk) begin
    fetch_state = fetch_state >> 1;
    last_instruction_reg <= received_instruction;
end


wire edge_case_stall;
assign edge_case_stall =  cpu_req_valid & (last_instruction[8:6] != received_instruction[8:6]);

assign cpu_req_ready = ~(| fetch_state[8:0]) & ~edge_case_stall;
// Logic for the initialization and start of the state machine.
always @(*) begin
    if (~sram_fetch_we) begin
      mem_incoming_hold_reg <= mem_resp_data;
    end
    // reset logic.
    if (reset) begin 
        dirty_bits <= 8'hff;
        valid_bits <= 8'h00;
        fetch_state <= 10'b0;
    end else begin
    // NOT RESET THEN DO THIS.
        // if (fetch_state[9]) begin
        // end else if (fetch_state[8]) begin
        // end else if (fetch_state[7]) begin
        // end else if (fetch_state[6]) begin
        // end else if (fetch_state[5]) begin
        // end else if (fetch_state[4]) begin
        // end else if (fetch_state[3]) begin
        // end else if (fetch_state[2]) begin
        // end else if (fetch_state[1]) begin
        // end else if (fetch_state[0]) begin
        // end 




        // Making a write will dirty the location, but only once the request is ready.

        // DIRTY BIT LOGIC
        if (is_write & cpu_req_ready) begin
          dirty_bits[addr_index[2:0]] <= 1'b1;
        end else if (fetch_state[0]) begin
          dirty_bits[addr_index[2:0]] <= 1'b1;
        end

        // VALID BIT LOGIC
        if (fetch_state[0]) begin
          valid_bits[addr_index[2:0]] <= 1'b1;
        end

        // BEGIN THE STATE MACHINE
        // If the tag is not the same, and the request is valid, start the state machine.
        // In addition, get the new and evicted tags.
        if (~is_tag_same & cpu_req_valid) begin
            fetch_state[9] <= 1;
            evicted_tag_reg <= lookupReadData; // The address gives the evicted tag.
            new_tag_reg <= received_instruction; // The cpu gives the new tag.
        end else begin
            fetch_state[9] <= 0;
        end
        // When are we setting dirtybits to 0? Valid bits to 1?
        
    end
end



// Now, let's tap into the SRAMs for the cache and main memory things.
// First, let's have all the outputs of the sram.


wire [31:0] sram1_resp;
wire [31:0] sram2_resp;
wire [31:0] sram3_resp;
wire [31:0] sram4_resp;
wire we_sram1;
wire we_sram2;
wire we_sram3;
wire we_sram4;

wire [1:0] sram_choice;
assign sram_choice = received_instruction[3:2];
assign we_sram1 = ~(is_write & cpu_req_ready & (sram_choice == 2'b00));
assign we_sram2 = ~(is_write & cpu_req_ready & (sram_choice == 2'b01));
assign we_sram3 = ~(is_write & cpu_req_ready & (sram_choice == 2'b10));
assign we_sram4 = ~(is_write & cpu_req_ready & (sram_choice == 2'b11));

// Which of the 4 SRAMs we will choose from. It is the index of the CPU instruction.


// Also, choose the address associated with the choice.
wire [4:0] sram_address;
assign sram_address = received_instruction[8:4];

reg [31:0] read_data_chosen_reg;
wire [31:0] read_data_chosen;
assign read_data_chosen = read_data_chosen_reg;

always @(*) begin
  case (sram_choice)
    2'b00: read_data_chosen_reg <= sram1_resp;
    2'b01: read_data_chosen_reg <= sram2_resp;
    2'b10: read_data_chosen_reg <= sram3_resp;
    2'b11: read_data_chosen_reg <= sram4_resp;
  endcase
end

// Let's work on memory prerequsites now.

// data line that gets sent back to MM during evictions
// Created piece, by piece from the 4 SRAMs.
wire [127:0] cache_eject_line_data;



// Indicates which line in cacheblock to fetch from.
wire [1:0] sram_fetch_line_index_MM;
assign sram_fetch_line_index_MM = (fetch_state[8] | fetch_state[4]) ? 2'd0 : (fetch_state[7] | fetch_state[3]) ? 2'd1 : (fetch_state[6] | fetch_state[2]) ? 2'd2 : 2'd3;

wire [1:0] sram_fetch_line_index_cache;
assign sram_fetch_line_index_cache = (fetch_state[9] | fetch_state[3]) ? 2'd0 : (fetch_state[8] | fetch_state[2]) ? 2'd1 : (fetch_state[7] | fetch_state[1]) ? 2'd2 : 2'd3;

// SRAM address for catch-to-memory interactions
wire [4:0] sram_fetch_addr;
assign sram_fetch_addr = {addr_index, sram_fetch_line_index_cache};

// Eviction and Fetch from MM
wire [27:0] fetch_address;
wire [27:0] evict_addr;
assign evict_addr = {evicted_tag[31:6], sram_fetch_line_index_MM};
assign fetch_addr = {new_tag[31:6], sram_fetch_line_index_MM};

// Output to arbiter things
assign mem_req_valid = (|fetch_state[8:1]);
assign mem_req_addr = mem_req_rw ? evict_addr : fetch_addr;
assign mem_req_rw = (| fetch_state[8:5]) & valid_bits[addr_index[2:0]] & dirty_bits[addr_index[2:0]];
assign mem_req_data_valid = (| fetch_state[8:5]);
assign mem_req_data_bits = cache_eject_line_data;
assign mem_req_data_mask = 16'hFFFF;



wire [3:0] fetch_bitmask;
assign fetch_bitmask = 4'hf;
// SRAM transactions
SRAM2RW32x32M dataSRAM1 (
  .A1(sram_fetch_addr),
  .A2(sram_address),
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
  .A2(sram_address),
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
  .A2(sram_address),
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
  .A2(sram_address),
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

assign cpu_resp_data = read_data_chosen;
assign cpu_resp_valid = is_read & ~(| fetch_state) & is_tag_same;

endmodule
