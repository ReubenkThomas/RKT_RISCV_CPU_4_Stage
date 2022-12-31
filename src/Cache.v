`include "util.vh"
`include "const.vh"
// Cache Version 3: An attempt to do reads on posedge, writes on negedge.
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

localparam IDLE         = 4'd0;
localparam LOOKUP       = 4'd1;
localparam EVICT1       = 4'd2;
localparam EVICT2       = 4'd3;
localparam EVICT3       = 4'd4;
localparam EVICT4       = 4'd5;
localparam FETCH1       = 4'd6;
localparam FETCH2       = 4'd7;
localparam FETCH3       = 4'd8;
localparam FETCH4       = 4'd9;
localparam READ         = 4'd10;
localparam WRITE        = 4'd11;
localparam WAIT         = 4'd12;

reg cpu_req_ready_reg;
reg cpu_resp_valid_reg;
reg [CPU_WIDTH-1:0] cpu_resp_data_reg;
reg mem_req_valid_reg;
reg [WORD_ADDR_BITS-1:`ceilLog2(`MEM_DATA_BITS/CPU_WIDTH)] mem_req_addr_reg;
reg mem_req_rw_reg;
reg mem_req_data_valid_reg;
reg [`MEM_DATA_BITS-1:0] mem_req_data_bits_reg;
reg [(`MEM_DATA_BITS/8)-1:0] mem_req_data_mask_reg;

assign cpu_req_ready = cpu_req_ready_reg;
assign cpu_resp_valid = cpu_resp_valid_reg;
assign cpu_resp_data = cpu_resp_data_reg;
assign mem_req_valid = mem_req_valid_reg;
assign mem_req_addr = mem_req_addr_reg;
assign mem_req_rw = mem_req_rw_reg;
assign mem_req_data_valid = mem_req_data_valid_reg;
assign mem_req_data_bits = mem_req_data_bits_reg;
assign mem_req_data_mask = mem_req_data_mask_reg;


// State
reg [3:0] state = LOOKUP;
reg [3:0] nextstate = LOOKUP;

// dirty, valid
reg [7:0] dirty = 8'h0;
reg [7:0] valid = 8'h0;

// LOOKUP "SRAM"
reg [31:0] lookup [15:0]; //32x16 "SRAM"
reg [31:0] lookup_output;
reg [3:0] lookup_index_reg;
reg [2:0] address_index_reg;
reg [31:0] received_address_reg;

// State pos/negs
reg lookup_state = 1'b0;
reg read_state = 1'b0;
reg write_state = 1'b0;
reg evict1_state = 1'b0;
reg evict2_state = 1'b0;
reg evict3_state = 1'b0;
reg evict4_state = 1'b0;
reg fetch1_state = 1'b0;
reg fetch2_state = 1'b0;
reg fetch3_state = 1'b0;
reg fetch4_state = 1'b0;

reg lookup_pos = 1'b0;
reg read_pos = 1'b0;
reg write_pos = 1'b0;
reg evict1_pos = 1'b0;
reg evict2_pos = 1'b0;
reg evict3_pos = 1'b0;
reg evict4_pos = 1'b0;
reg fetch1_pos = 1'b0;
reg fetch2_pos = 1'b0;
reg fetch3_pos = 1'b0;
reg fetch4_pos = 1'b0;

// dataSRAM stuff:
reg [4:0] data1_address1;
reg [4:0] data1_address2;
reg [4:0] data2_address1;
reg [4:0] data2_address2;
reg [4:0] data3_address1;
reg [4:0] data3_address2;
reg [4:0] data4_address1;
reg [4:0] data4_address2;

reg data1_web1;
reg data1_web2;
reg data2_web1;
reg data2_web2;
reg data3_web1;
reg data3_web2;
reg data4_web1;
reg data4_web2;

reg [3:0] data1_bytemask1;
reg [3:0] data1_bytemask2;
reg [3:0] data2_bytemask1;
reg [3:0] data2_bytemask2;
reg [3:0] data3_bytemask1;
reg [3:0] data3_bytemask2;
reg [3:0] data4_bytemask1;
reg [3:0] data4_bytemask2;

reg [31:0] data1_input1;
reg [31:0] data1_input2;
reg [31:0] data2_input1;
reg [31:0] data2_input2;
reg [31:0] data3_input1;
reg [31:0] data3_input2;
reg [31:0] data4_input1;
reg [31:0] data4_input2;

reg [31:0] data1_output1;
reg [31:0] data1_output2;
reg [31:0] data2_output1;
reg [31:0] data2_output2;
reg [31:0] data3_output1;
reg [31:0] data3_output2;
reg [31:0] data4_output1;
reg [31:0] data4_output2;

// Cache, Mem Index
reg [1:0] C_line_index;
reg [1:0] M_line_index;

// sram_choice
reg [1:0] sram_choice;

always @(*) begin
    if (reset) begin
        // All outputs are 0 and reads.
        cpu_req_ready_reg = 1'b1; // Start ready?
        cpu_resp_valid_reg = 1'b0;
        cpu_resp_data_reg = {CPU_WIDTH{1'b0}};
        mem_req_valid_reg = 1'b0;
        mem_req_addr_reg = {WORD_ADDR_BITS-`ceilLog2(`MEM_DATA_BITS/CPU_WIDTH){1'b0}};
        mem_req_rw_reg = 1'b0;
        mem_req_data_valid_reg = 1'b0; 
        mem_req_data_bits_reg = {`MEM_DATA_BITS{1'b0}};
        mem_req_data_mask_reg = {(`MEM_DATA_BITS/8){1'b0}};
         // Set lookup to all 0s.
        lookup[0] = {32{1'b0}};
        lookup[1] = {32{1'b0}};
        lookup[2] = {32{1'b0}};
        lookup[3] = {32{1'b0}};
        lookup[4] = {32{1'b0}};
        lookup[5] = {32{1'b0}};
        lookup[6] = {32{1'b0}};
        lookup[7] = {32{1'b0}};
        lookup[8] = {32{1'b0}};
        lookup[9] = {32{1'b0}};
        lookup[10] = {32{1'b0}};
        lookup[11] = {32{1'b0}};
        lookup[12] = {32{1'b0}};
        lookup[13] = {32{1'b0}};
        lookup[14] = {32{1'b0}};
        lookup[15] = {32{1'b0}};

        state = LOOKUP;
        nextstate = LOOKUP;
        valid = 8'h00;
        dirty = 8'h00;

        lookup_state = 1'b0;
        read_state = 1'b0;
        write_state = 1'b0;
        evict1_state = 1'b0;
        evict2_state = 1'b0;
        evict3_state = 1'b0;
        evict4_state = 1'b0;
        fetch1_state = 1'b0;
        fetch2_state = 1'b0;
        fetch3_state = 1'b0;
        fetch4_state = 1'b0;
    end else begin
        /*
        States:
            LOOKUP, READ, WRITE
        
        Description:
            Let's pretend for a moment that cache was our only memory. If that is the case, then 
            anytime we get an input, then we would need to either read or write to our "main memory".

            When an address is given, we will spend the first clock cycle making sure that we actually
            have the data in the cache. If it isn't, then we will be [evicting and] fetching the correct 
            data from the real main memory (those states will then move to the read or write stage at the
            end of their occupation).

            Let's say the data is in fact in the cache. If we are doing a read, then we spend one cycle 
            getting the correct data from the SRAMs. Set up the address and web ports, so that on the 
            posedge, it will spit out data. Then prepare the output so that on the negedge, it will
            spit it out.

            If the data is in the cache, and we are doing a write, then we will spend one cycle writing
            data into the correct cache. For this one, we only need the posedge. Set up the address, web,
            bytemask, input ports, so that on the posedge, the SRAM will write data. Note that there will
            really only be one SRAM writing, so logic is needed to make sure that not all SRAMs write.
        */
        case (state)
            LOOKUP : begin //0   
                lookup_pos = 1'b0;
                read_pos = 1'b0;
                write_pos = 1'b0;
                evict1_pos = 1'b0;
                evict2_pos = 1'b0;
                evict3_pos = 1'b0;
                evict4_pos = 1'b0;
                fetch1_pos = 1'b0;
                fetch2_pos = 1'b0;
                fetch3_pos = 1'b0;
                fetch4_pos = 1'b0;

                
                cpu_resp_valid_reg = 1'b1;

                if (~lookup_state) begin
                    cpu_resp_valid_reg = 1'b0;
                    cpu_req_ready_reg = 1'b1;
                    if (cpu_req_valid) begin  // I'm valid!
                        // Setup the lookup reg
                        received_address_reg = {cpu_req_addr, 2'b00}; // This is the official instruction.
                        address_index_reg = received_address_reg[8:6]; // Here is where to look in lookup.
                        lookup_index_reg = {1'b0, address_index_reg}; // We don't utilize all spots in the lookup?
                    end 
                end else begin
                    // if (cpu_req_valid) begin
                        lookup_pos = 1'b1;
                        cpu_req_ready_reg = 1'b0; // Ok, I'm not ready for more input now.
                        
                        // Now compare and handle tags
                        lookup_output = lookup[lookup_index_reg];
                        if (received_address_reg[31:9] == lookup_output[31:9]) begin
                            if (|cpu_req_write) begin
                                nextstate = WRITE;
                            end else begin
                                nextstate = READ;
                            end
                        end else begin
                            if (~valid[address_index_reg] | ~dirty[address_index_reg]) begin
                                nextstate = FETCH1;
                            end else begin
                                nextstate = EVICT1;
                            end
                        end
                    // end 
                    
                end
            end
            READ : begin // a
                
                if (~read_state) begin
                    data1_address1 = received_address_reg[8:4];
                    data2_address1 = received_address_reg[8:4];
                    data3_address1 = received_address_reg[8:4];
                    data4_address1 = received_address_reg[8:4];
                    sram_choice = received_address_reg[3:2];
                    data1_web1 = 1'b1;
                    data2_web1 = 1'b1;
                    data3_web1 = 1'b1;
                    data4_web1 = 1'b1;
                end else begin
                    read_pos = 1'b1;
                    case (sram_choice) 
                        2'd0 : cpu_resp_data_reg = data1_output1;
                        2'd1 : cpu_resp_data_reg = data2_output1;
                        2'd2 : cpu_resp_data_reg = data3_output1;
                        2'd3 : cpu_resp_data_reg = data4_output1;
                    endcase
                    nextstate = LOOKUP;
                end
            end 
            WRITE : begin //b
                if (~write_state) begin
                    data1_address2 = received_address_reg[8:4];
                    data2_address2 = received_address_reg[8:4];
                    data3_address2 = received_address_reg[8:4];
                    data4_address2 = received_address_reg[8:4];
                    sram_choice = received_address_reg[3:2];
                    data1_web2 = 1'b0;
                    data2_web2 = 1'b0;
                    data3_web2 = 1'b0;
                    data4_web2 = 1'b0;
                    // Set all inputs to the same value, but the bytemask control it so the correct one is written.
                    data1_bytemask2 = 4'h0;
                    data2_bytemask2 = 4'h0;
                    data3_bytemask2 = 4'h0;
                    data4_bytemask2 = 4'h0;
                    sram_choice = received_address_reg[3:2];
                    case (sram_choice)
                        2'd0 : data1_bytemask2 = 4'hf;
                        2'd1 : data2_bytemask2 = 4'hf;
                        2'd2 : data3_bytemask2 = 4'hf;
                        2'd3 : data4_bytemask2 = 4'hf;
                    endcase
                    data1_input2 = cpu_req_data;
                    data2_input2 = cpu_req_data;
                    data3_input2 = cpu_req_data;
                    data4_input2 = cpu_req_data;
                    cpu_resp_valid_reg = 1'b1;

                end else begin
                    write_pos = 1'b1;
                    nextstate = LOOKUP;
                    dirty[address_index_reg] = 1'b1;
                end
            end

            /*
            States: 
                EVICT

            Description:
                We will now be trying to get data from main memory to the cache, and also 
                writing back data into main memory. The way to do this is using a posedge to read
                data from the cache, and then use the negedge to write data to both
                memory. We will need to do this for each line in the cache block, which 
                means there must be 4 states at minimum.

                Finally, we will have to deal with not evicting block if the data is clean or the
                data is invalid. However, once we finish our fetching business, then the data must
                turn valid. The dirty state is only changed during the write state. If it is invalid
                or not dirty, these 4 evict states will be skipped, and only the fetch states will
                be run. That makes sense because we only need to write the newest data to memory if
                the cache did something to it and it is in fact data that is valid.
            */
            EVICT1 : begin //2
                if (~evict1_state) begin
                    // Get Cache Block, Line 1.
                    C_line_index = 2'b00;
                    data1_address1 = {address_index_reg, C_line_index};
                    data2_address1 = {address_index_reg, C_line_index};
                    data3_address1 = {address_index_reg, C_line_index};
                    data4_address1 = {address_index_reg, C_line_index};
                    data1_web1 = 1'b1;
                    data2_web1 = 1'b1;
                    data3_web1 = 1'b1;
                    data4_web1 = 1'b1;
                end else begin
                    evict1_pos = 1'b1;
                    if (mem_req_data_ready) begin // Ok, I am ready for you to write data. What is it?
                        mem_req_data_bits_reg = {data4_output1, data3_output1, data2_output1, data1_output1};
                        mem_req_data_mask_reg = 16'hffff; // Write the entire line.
                        nextstate = EVICT2; // Ok, let's try to move to the next line.
                    end else begin
                        mem_req_data_valid_reg = 1'b1; // I want to write data
                        mem_req_valid_reg = 1'b1; // Make a transaction 
                        mem_req_rw_reg = 1'b0;
                    end
                    // Write Data to MM
                    

                end
            end

            EVICT2 : begin //3
                if (~evict2_state) begin
                    C_line_index = 2'b01;
                    data1_address1 = {address_index_reg, C_line_index};
                    data2_address1 = {address_index_reg, C_line_index};
                    data3_address1 = {address_index_reg, C_line_index};
                    data4_address1 = {address_index_reg, C_line_index};
                    data1_web1 = 1'b1;
                    data2_web1 = 1'b1;
                    data3_web1 = 1'b1;
                    data4_web1 = 1'b1;
                end else begin
                    evict2_pos = 1'b1;
                    if (mem_req_data_ready) begin // Ok, I am ready for you to write data. What is it?
                        mem_req_data_bits_reg = {data4_output1, data3_output1, data2_output1, data1_output1};
                        mem_req_data_mask_reg = 16'hffff; // Write the entire line.
                        nextstate = EVICT3; // Ok, let's try to move to the next line.
                    end else begin
                        mem_req_data_valid_reg = 1'b1; // I want to write data
                        mem_req_valid_reg = 1'b1; // Make a transaction 

                    end
                end
            end

            EVICT3 : begin //4
                if (~evict3_state) begin
                    C_line_index = 2'b10;
                    data1_address1 = {address_index_reg, C_line_index};
                    data2_address1 = {address_index_reg, C_line_index};
                    data3_address1 = {address_index_reg, C_line_index};
                    data4_address1 = {address_index_reg, C_line_index};
                    data1_web1 = 1'b1;
                    data2_web1 = 1'b1;
                    data3_web1 = 1'b1;
                    data4_web1 = 1'b1;
                end else begin
                    evict3_pos = 1'b1;
                    if (mem_req_data_ready) begin // Ok, I am ready for you to write data. What is it?
                        mem_req_data_bits_reg = {data4_output1, data3_output1, data2_output1, data1_output1};
                        mem_req_data_mask_reg = 16'hffff; // Write the entire line.
                        nextstate = EVICT4; // Ok, let's try to move to the next line.
                    end else begin
                        mem_req_data_valid_reg = 1'b1; // I want to write data
                        mem_req_valid_reg = 1'b1; // Make a transaction 
                    end
                end
            end

            EVICT4 : begin //5
                if (~evict4_state) begin
                    C_line_index = 2'b11;
                    data1_address1 = {address_index_reg, C_line_index};
                    data2_address1 = {address_index_reg, C_line_index};
                    data3_address1 = {address_index_reg, C_line_index};
                    data4_address1 = {address_index_reg, C_line_index};
                    data1_web1 = 1'b1;
                    data2_web1 = 1'b1;
                    data3_web1 = 1'b1;
                    data4_web1 = 1'b1;
                end else begin
                    evict4_pos = 1'b1;
                    if (mem_req_data_ready) begin // Ok, I am ready for you to write data. What is it?
                        mem_req_data_bits_reg = {data4_output1, data3_output1, data2_output1, data1_output1};
                        mem_req_data_mask_reg = 16'hffff; // Write the entire line.
                        nextstate = FETCH1; // Ok, we are done with the moving to mem. Now do mem->cache transactions.
                    end else begin
                        mem_req_data_valid_reg = 1'b1; // I want to write data
                        mem_req_valid_reg = 1'b1; // Make a transaction 
                    end
                end
            end

            /*
            State:
                FETCH

            Description:
                The fetch states will now go from data in memory to write it in the cache.
                The way memory is set up is that once we give it what it wants, it will use the 
                next 4 cycles giving back data. So, that means all we have to do is wait until the 
                first data appears, and then move states so that it aligns with the output of main
                memory on the following cycles.

                We will set up the address for a read to memory, so that on the posedge, we will 
                get 4 lines of information on each following cycle. 
            */

            FETCH1 : begin //6
                // if ({cpu_req_addr, 2'b00} != received_address_reg) begin
                //     nextstate = LOOKUP;
                //     state = LOOKUP;
                // end
                if (~fetch1_state) begin
                    if (mem_req_ready) begin // Ok, memory is ready, what address do you want to read from?
                        M_line_index = 2'b00;
                        mem_req_addr_reg = {received_address_reg[31:6], M_line_index}; // Here is the address
                    
                    end
                    mem_req_valid_reg = 1'b1; // I want to make some read.
                    mem_req_rw_reg = 1'b0; // Let's read.

                end else begin
                    fetch1_pos = 1'b1;
                    if (mem_resp_valid) begin
                        C_line_index = 2'b00;
                        // Where should we write to the Cache?
                        data1_address2 = {address_index_reg, C_line_index};
                        data2_address2 = {address_index_reg, C_line_index};
                        data3_address2 = {address_index_reg, C_line_index};
                        data4_address2 = {address_index_reg, C_line_index};
                        // I will write,
                        data1_web2 = 1'b0;
                        data2_web2 = 1'b0;
                        data3_web2 = 1'b0;
                        data4_web2 = 1'b0;
                        // Every spot will be written to,
                        data1_bytemask2 = 4'hf;
                        data2_bytemask2 = 4'hf;
                        data3_bytemask2 = 4'hf;
                        data4_bytemask2 = 4'hf;
                        // And this is the data I want to write.
                        data1_input2 = mem_resp_data[31:0];
                        data2_input2 = mem_resp_data[63:32];
                        data3_input2 = mem_resp_data[95:64];
                        data4_input2 = mem_resp_data[127:96];

                        nextstate = FETCH2;
                    end
                
                end
            end

            FETCH2 : begin //7
                if (~fetch2_state) begin
                    if (mem_req_ready) begin // Ok, memory is ready, what address do you want to read from?
                        M_line_index = 2'b01;
                        mem_req_addr_reg = {received_address_reg[31:6], M_line_index}; // Here is the address
                    
                    end
                    mem_req_valid_reg = 1'b1; // I want to make some read.
                    mem_req_rw_reg = 1'b0; // Let's read.
                    
                end else begin
                    fetch2_pos = 1'b1;
                    if (mem_resp_valid) begin
                        C_line_index = 2'b01;
                        // Where should we write to the Cache?
                        data1_address2 = {address_index_reg, C_line_index};
                        data2_address2 = {address_index_reg, C_line_index};
                        data3_address2 = {address_index_reg, C_line_index};
                        data4_address2 = {address_index_reg, C_line_index};
                        // I will write,
                        data1_web2 = 1'b0;
                        data2_web2 = 1'b0;
                        data3_web2 = 1'b0;
                        data4_web2 = 1'b0;
                        // Every spot will be written to,
                        data1_bytemask2 = 4'hf;
                        data2_bytemask2 = 4'hf;
                        data3_bytemask2 = 4'hf;
                        data4_bytemask2 = 4'hf;
                        // And this is the data I want to write.
                        data1_input2 = mem_resp_data[31:0];
                        data2_input2 = mem_resp_data[63:32];
                        data3_input2 = mem_resp_data[95:64];
                        data4_input2 = mem_resp_data[127:96];

                        nextstate = FETCH3;
                    end
                
                end
            end

            FETCH3 : begin //8
                if (~fetch3_state) begin
                    if (mem_req_ready) begin // Ok, memory is ready, what address do you want to read from?
                        M_line_index = 2'b10;
                        mem_req_addr_reg = {received_address_reg[31:6], M_line_index}; // Here is the address
                    
                    end 
                    mem_req_valid_reg = 1'b1; // I want to make some read.
                    mem_req_rw_reg = 1'b0; // Let's read.
                    
                end else begin
                    fetch3_pos = 1'b1;
                    if (mem_resp_valid) begin
                        C_line_index = 2'b10;
                        // Where should we write to the Cache?
                        data1_address2 = {address_index_reg, C_line_index};
                        data2_address2 = {address_index_reg, C_line_index};
                        data3_address2 = {address_index_reg, C_line_index};
                        data4_address2 = {address_index_reg, C_line_index};
                        // I will write,
                        data1_web2 = 1'b0;
                        data2_web2 = 1'b0;
                        data3_web2 = 1'b0;
                        data4_web2 = 1'b0;
                        // Every spot will be written to,
                        data1_bytemask2 = 4'hf;
                        data2_bytemask2 = 4'hf;
                        data3_bytemask2 = 4'hf;
                        data4_bytemask2 = 4'hf;
                        // And this is the data I want to write.
                        data1_input2 = mem_resp_data[31:0];
                        data2_input2 = mem_resp_data[63:32];
                        data3_input2 = mem_resp_data[95:64];
                        data4_input2 = mem_resp_data[127:96];

                        nextstate = FETCH4;
                    end
                
                end
            end

            FETCH4 : begin //9
                if (~fetch4_state) begin
                    if (mem_req_ready) begin // Ok, memory is ready, what address do you want to read from?
                        M_line_index = 2'b11;
                        mem_req_addr_reg = {received_address_reg[31:6], M_line_index}; // Here is the address
                    
                    end 
                    mem_req_valid_reg = 1'b1; // I want to make some read.
                    mem_req_rw_reg = 1'b0; // Let's read.
                    
                end else begin
                    fetch4_pos = 1'b1;
                    if (mem_resp_valid) begin
                        C_line_index = 2'b11;
                        // Where should we write to the Cache?
                        data1_address2 = {address_index_reg, C_line_index};
                        data2_address2 = {address_index_reg, C_line_index};
                        data3_address2 = {address_index_reg, C_line_index};
                        data4_address2 = {address_index_reg, C_line_index};
                        // I will write,
                        data1_web2 = 1'b0;
                        data2_web2 = 1'b0;
                        data3_web2 = 1'b0;
                        data4_web2 = 1'b0;
                        // Every spot will be written to,
                        data1_bytemask2 = 4'hf;
                        data2_bytemask2 = 4'hf;
                        data3_bytemask2 = 4'hf;
                        data4_bytemask2 = 4'hf;
                        // And this is the data I want to write.
                        data1_input2 = mem_resp_data[31:0];
                        data2_input2 = mem_resp_data[63:32];
                        data3_input2 = mem_resp_data[95:64];
                        data4_input2 = mem_resp_data[127:96];
                        valid[address_index_reg] = 1'b1;
                        if (|cpu_req_write) begin
                            nextstate = WRITE;
                        end else begin
                            nextstate = READ;
                        end
                    end
                
                end
            end

            WAIT : begin
                
            end
        endcase
    end
end



// An attempt to do reads on posedge, writes on negedge.
always @(posedge clk) begin
    case (state)

    // If lookup state. Read
    LOOKUP : begin
        if (cpu_req_valid & cpu_req_ready & ~lookup_pos) begin
            lookup_state = 1'b1;    
        
        end
        
    end

    // If read state. Set up location in cache.
    READ : begin
        if (~read_pos) begin
            read_state = 1'b1;
            cpu_resp_valid_reg = 1'b1; // Data will be output in negedge.
        end
    end

    // If write state. Set up location and input in cache.
    WRITE : begin
        if (~write_pos) write_state = 1'b1;
    end

    EVICT1 : begin
        if (~evict1_pos) evict1_state = 1'b1;
    end

    EVICT2 : begin
        if (~evict2_pos) evict2_state = 1'b1;
    end

    EVICT3 : begin
        if (~evict3_pos) evict3_state = 1'b1;
    end

    EVICT4 : begin
        if (~evict4_pos) evict4_state = 1'b1;
    end

    FETCH1 : begin
        if (~fetch1_pos) fetch1_state = 1'b1;
    end

    FETCH2 : begin
        if (~fetch2_pos) fetch2_state = 1'b1;
    end

    FETCH3 : begin
        if (~fetch3_pos) fetch3_state = 1'b1;
    end

    FETCH4 : begin
        if (~fetch4_pos) fetch4_state = 1'b1;
    end



    endcase

end

always @(negedge clk) begin
    case (state)
    // If lookup state. Write
    LOOKUP : begin
        if (lookup_state) begin
            lookup[lookup_index_reg] = received_address_reg;
            lookup_state = 1'b0;
        end
        
    end
    // If read state get output data set up.
    READ : begin
        read_state = 1'b0;       
        // cpu_req_ready_reg = 1'b1; 
    end

    // If write state. Say you are ready for the next instruction.
    WRITE : begin
        write_state = 1'b0;
        // cpu_req_ready_reg = 1'b1;
    end

    // If evict, only move on if the mem_req_data_ready
    EVICT1 : begin
        if (mem_req_data_ready) begin
            evict1_state = 1'b0;            
        end 
    end
    EVICT2 : begin
        if (mem_req_data_ready) begin
            evict2_state = 1'b0;            
        end 
    end
    EVICT3 : begin
        if (mem_req_data_ready) begin
            evict3_state = 1'b0;            
        end 
    end
    EVICT4 : begin
        if (mem_req_data_ready) begin
            evict4_state = 1'b0; 
            mem_req_valid_reg = 1'b0; // Stop my transaction.
            mem_req_data_valid_reg = 1'b0; // Stop looking at data I'm sending you.
        end 
    end

    FETCH1 : begin
        if (mem_resp_valid) begin
            fetch1_state = 1'b0;
        end
    end

    FETCH2 : begin
        if (mem_resp_valid) begin
            fetch2_state = 1'b0;
        end
    end

    FETCH3 : begin
        if (mem_resp_valid) begin
            fetch3_state = 1'b0;
        end
    end

    FETCH4 : begin
        if (mem_resp_valid) begin
            fetch4_state = 1'b0;
            mem_req_valid_reg = 1'b0; // Stop my request.
            
            
        end
    end
    

    endcase
    state = nextstate;
    
end


SRAM2RW32x32M dataSRAM1 (
  .A1(data1_address1),
  .A2(data1_address2),
  .CE1(clk),
  .CE2(~clk),
  .WEB1(data1_web1),
  .WEB2(data1_web2),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(data1_bytemask1),
  .BYTEMASK2(data1_bytemask2),
  .I1(data1_input1),
  .I2(data1_input2),
  .O1(data1_output1),
  .O2(data1_output2)
);
SRAM2RW32x32M dataSRAM2 (
  .A1(data2_address1),
  .A2(data2_address2),
  .CE1(clk),
  .CE2(~clk),
  .WEB1(data2_web1),
  .WEB2(data2_web2),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(data2_bytemask1),
  .BYTEMASK2(data2_bytemask2),
  .I1(data2_input1),
  .I2(data2_input2),
  .O1(data2_output1),
  .O2(data2_output2)
);
SRAM2RW32x32M dataSRAM3 (
  .A1(data3_address1),
  .A2(data3_address2),
  .CE1(clk),
  .CE2(~clk),
  .WEB1(data3_web1),
  .WEB2(data3_web2),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(data3_bytemask1),
  .BYTEMASK2(data3_bytemask2),
  .I1(data3_input1),
  .I2(data3_input2),
  .O1(data3_output1),
  .O2(data3_output2)
);
SRAM2RW32x32M dataSRAM4 (
  .A1(data4_address1),
  .A2(data4_address2),
  .CE1(clk),
  .CE2(~clk),
  .WEB1(data4_web1),
  .WEB2(data4_web2),
  .OEB1(1'b0),
  .OEB2(1'b0),
  .CSB1(1'b0),
  .CSB2(1'b0),
  .BYTEMASK1(data4_bytemask1),
  .BYTEMASK2(data4_bytemask2),
  .I1(data4_input1),
  .I2(data4_input2),
  .O1(data4_output1),
  .O2(data4_output2)
);

endmodule