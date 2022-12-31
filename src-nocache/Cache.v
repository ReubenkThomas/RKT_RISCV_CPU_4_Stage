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


wire [2:0] addr_index;
assign addr_index = cpu_req_addr[8:6];

wire [32:0] lookupReadData;
reg lookupSRAM_rewe;
SRAM2RW16x32M lookupSRAM (
  .A1(cpu_req_addr),
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
  .I1(addr_index),
  // I2,
  .O1(lookupReadData),
  // O2
);


// reset logic
always @(posedge clk) begin
  if (reset) begin
    mem_to_cache_clk_index <= 2'd0;
    // TODO
  end
end



// checks if the tag in cache is the same.
wire is_tag_same;
assign is_tag_same = cpu_req_addr[31:9] == lookupReadData[31:9];


wire [1:0] sram_choice;
assign sram_choice = cpu_req_addr[3:2];


// currently fetching from memory to cache?
wire currently_fetching;

// this should start at 00 and increment every clock cycle
reg [1:0] mem_to_cache_clk_index;
// it is possible that we increment any cycle when currently_fetching == 1
// it is possible that we increment till we reach 00 again and then add the tag
// we can update tag while the first data is being fetched, then stop fetching when tag is 00 again NOT GOOD IDEA


wire is_write;
wire is_read;
assign is_write = (|cpu_req_write) & cpu_req_valid;
assign is_read = ~(|cpu_req_write) & cpu_req_valid;

reg [1:0] write_SRAMSelector;
reg []


wire [1:0] sram_write_read_choice;
wire [4:0] sram_write_read_addr;
assign sram_write_read_choice = cpu_req_addr[3:2];
assign sram_write_read_addr = cpu_req_addr[8:4];


// pass the writemask (cpu_req_write) onto the cpu 
always @* begin
  if(is_write & cpu_req_rdy) begin
    


  end 

end






always @* begin
  if (!is_tag_same & is_read) begin
    currently_fetching <= 1;

  end else begin
    currently_fetching <= 0;

  end

  // dubious line TODO
  if ((mem_to_cache_clk_index == 2'b10 || mem_to_cache_clk_index == 2'b11) && currently_fetching) begin
    lookupSRAM_rewe <= 0;
  end else begin
    lookupSRAM_rewe <= 1; 
  end  
end


// always @(posedge clk) begin
//   if (currently_fetching) begin
//     mem_to_cache_clk_index = mem_to_cache_clk_index + 1;
//   end
// end

// // fetch 
// wire [`MEM_ADDR_BITS-1:0] fetch_addr_mem;
// assign fetch_addr_mem = {cpu_req_addr[31:6], mem_to_cache_clk_index}; // TODO assign this to mem_req_data_addr


// assign mem_req_addr = mem_req_rw ? TODO : fetch_addr_mem;
// assign mem_req_dat_valid = !(currently_fetching ); // TODO

// assign mem_req_rw 
// assign 

// the address passed into all the SRAMs for reading
// wire [4:0] sram_read_addr;
// assign sram_read_addr = {addr_index,cpu_req_addr[5:4]};


// wire [4:0] sram_chunk_load_addr;
// assign sram_read_addr = {addr_index, 2'b00} | {3'd0, mem_to_cache_clk_index};





// write to cache
wire [31:0] sram1_resp;
wire [31:0] sram2_resp;
wire [31:0] sram3_resp;
wire [31:0] sram4_resp;
wire we_sram1;
wire we_sram2;
wire we_sram3;
wire we_sram4;

assign we_sram1 = ~(is_write & cpu_req_ready & mem_req_ready & mem_req_data_ready & (sram_write_read_choice == 2'b00));
assign we_sram2 = ~(is_write & cpu_req_ready & mem_req_ready & mem_req_data_ready & (sram_write_read_choice == 2'b01));
assign we_sram3 = ~(is_write & cpu_req_ready & mem_req_ready & mem_req_data_ready & (sram_write_read_choice == 2'b10));
assign we_sram4 = ~(is_write & cpu_req_ready & mem_req_ready & mem_req_data_ready & (sram_write_read_choice == 2'b11));

// write to mem
reg [5:0] mem_write_mask_shift;
always @* begin 
  case (sram_write_read_choice)
    2'b00: mem_write_mask_shift <= 5'b0;
    2'b01: mem_write_mask_shift <= 5'b8;
    2'b10: mem_write_mask_shift <= 5'b16;
    2'b11: mem_write_mask_shift <= 5'b24;
  endcase
end
assign mem_req_data_mask = {24'd0, cpu_req_write} << mem_write_mask_shift; 

assign mem_req_valid = ~we_sram1 | ~we_sram2 | ~we_sram3 | ~we_sram4 | read_from_mem; // TODO
assign mem_req_addr = currently_fetching ? : cpu_req_addr[31:7]; // TODO, also check if length is correct
assign mem_req_rw = ~we_sram1 | ~we_sram2 | ~we_sram3 | ~we_sram4;
assign mem_req_data_valid = mem_req_rw; // TODO, ????? is this right ?????

assign mem_req_data_bits = cpu_req_data << mem_write_mask_shift;

reg [31:0] read_data_chosen;
always @* begin
  case (sram_write_read_choice)
    2'b00: read_data_chosen <= sram1_resp;
    2'b01: read_data_chosen <= sram2_resp;
    2'b10: read_data_chosen <= sram3_resp;
    2'b11: read_data_chosen <= sram4_resp;
  endcase
end

assign cpu_resp_data = read_data_chosen;

SRAM2RW32x32M dataSRAM1 (
  .A1(sram_read_addr),
  .A2(sram_write_read_addr),
  CE1,
  .CE2(clk),
  WEB1,
  .WEB2(we_sram1),
  OEB1,
  .OEB2(0),
  CSB1,
  .CSB2(0),
  BYTEMASK1,
  .BYTEMASK2(cpu_req_write),
  I1,
  .I2(cpu_req_data),
  O1,
  O2(sram1_resp)
);

SRAM2RW32x32M dataSRAM2 (
  .A1(sram_read_addr),
  .A2(sram_write_read_addr),
  CE1,
  .CE2(clk),
  WEB1,
  .WEB2(we_sram2),
  OEB1,
  .OEB2(0),
  CSB1,CSB2,BYTEMASK1,
  .BYTEMASK2(cpu_req_write),
  I1,
  .I2(cpu_req_data),
  O1,
  O2(sram2_resp)
);

SRAM2RW32x32M dataSRAM3 (
  .A1(sram_read_addr),
  .A2(sram_write_read_addr),
  CE1,
  .CE2(clk),
  WEB1,
  .WEB2(we_sram3),
  OEB1,
  .OEB2(0),
  CSB1,
  .CSB2(0),
  BYTEMASK1,
  .BYTEMASK2(cpu_req_write),
  I1,
  .I2(cpu_req_data),
  O1,
  O2(sram3_resp)
);

SRAM2RW32x32M dataSRAM4 (
  .A1(sram_read_addr),
  .A2(sram_write_read_addr),
  CE1,
  .CE2(clk),
  WEB1,
  .WEB2(we_sram4),
  OEB1,
  .OEB2(0),
  CSB1,
  .CSB2(0),
  BYTEMASK1,
  .BYTEMASK2(cpu_req_write),
  I1,
  .I2(cpu_req_data),
  O1,
  O2(sram4_resp)
);


endmodule
