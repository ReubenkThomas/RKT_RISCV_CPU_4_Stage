`timescale 1ns / 1ps


`include "RegNames.vh"

module RegFileTestbench();

    parameter Halfcycle = 5; //half period is 5ns
    
    localparam Cycle = 2*Halfcycle;
    
    reg Clock;
    
    // Clock Signal generation:
    initial Clock = 0; 
    always #(Halfcycle) Clock = ~Clock;
    
    // Register and wires to test the ALU
    reg [31:0] DUTout;
    reg [31:0] REFout; 


    // Task for checking output
    task checkOutput;
        // input [6:0] opcode;
        // input [2:0] funct;
        // input add_rshift_type;
        if ( REFout !== DUTout ) begin
            $display("\t FAIL i:%d, DUTout: 0x%h, REFout: 0x%h", i, DUTout, REFout);
            $finish();
        end
        else begin
            $display("\t PASS i:%d, DUTout: 0x%h, REFout: 0x%h", i, DUTout, REFout);
        end
    endtask


    //This is where the modules being tested are instantiated. 
    // ALUdec DUT1(
    //     .opcode(opcode),
    //     .funct(funct),
    //     .add_rshift_type(add_rshift_type),
    //     .ALUop(ALUop));

    // ALU DUT2( .A(A),
    //     .B(B),
    //     .ALUop(ALUop),
    //     .Out(DUTout));
    reg [31:0] RegWriteData;
    reg [4:0] RegWriteIndex;
    reg [4:0] RegReadIndex1;
    reg [4:0] RegReadIndex2;
    reg RegWEn;
    reg writeRdy;
    reg writeVal;
    // reg readRdy1;
    // reg readVal1;
    // reg readRdy2;
    // reg readVal2;
    wire read_val;
    reg reset;
    wire [31:0] RegReadData1;
    wire [31:0] RegReadData2;
    reg [31:0] testVector [31:0];


    RegFile REG(
        .RegWriteData(RegWriteData),
        .RegWriteIndex(RegWriteIndex),
        .RegReadIndex1(RegReadIndex1),
        .RegReadIndex2(RegReadIndex2),
        .RegWEn(RegWEn),
        .clk(Clock),
        // .write_rdy1(writeRdy),
        // .write_val1(writeVal),
        // // .read_rdy1(readRdy1),
        // .read_val1(readVal1),
        // // .read_rdy2(readRdy2),
        // .read_val2(readVal2),
        // .read_val(read_val),
        .reset(reset),
        .RegReadData1(RegReadData1),
        .RegReadData2(RegReadData2)
    );

    integer i;
    initial i = 0;
    localparam loops = 32; // number of times to run the tests for

    // Testing logic:

    
    
    initial begin
        $vcdpluson;
        RegWEn = 0;
        @(posedge Clock)
        reset = 0;
        @(posedge Clock)
        reset = 1;
        @(posedge Clock)
        reset = 0;
        @(posedge Clock)
        @(posedge Clock)
        

        $display("\t Testing all are zeros after reset : Read1");
        for(i = 0; i < loops; i = i + 1)
        begin

            RegReadIndex1 = i;
            DUTout = RegReadData1;
            REFout = 0;
            #1;
            checkOutput();
    
        end

        $display("\t Testing all are zeros after reset : Read2");
        for(i = 0; i < loops; i = i + 1)
        begin
            RegReadIndex2 = i;
            DUTout = RegReadData2;
            REFout = 0;
            #1;
            checkOutput();
        end

        $display("\t\t Testing all are fives after writing 5 to every register, except for x0");
        RegWEn = 1;
        RegWriteData = 32'd5;

        for(i = 0; i < loops; i = i + 1) begin
            RegWriteIndex = i;
            @(posedge Clock);
        end

        @(posedge Clock);
        for(i = 0; i < loops; i = i + 1) begin
            RegReadIndex1 = i;
            @(negedge Clock);
            DUTout = RegReadData1;
            if (i == 0) REFout = 0;
            else REFout = 32'd5;
            checkOutput();
        end


        
        for (i = 0; i < loops; i = i + 1)
        begin 
            testVector[i] = 5; 
        end
        testVector[0] = 0;

        $display("\t\t Testing random assignments, testing reading different registers at once.");
        @(posedge Clock);
        RegWriteData = 32'd17;
        RegWriteIndex = 5'd4;
        RegWEn = 1;
        #1;
        RegWEn = 0;
        testVector[4] = 32'd17; 
        @(posedge Clock);
        RegWriteData = 32'd174;
        RegWriteIndex = 5'd7;
        RegWEn = 1;
        #1;
        RegWEn = 0;
        testVector[7] = 32'd174;
        @(posedge Clock);
        RegWriteData = 32'd256;
        RegWriteIndex = 5'd25;
        RegWEn = 1;
        #1;
        RegWEn = 0;
        testVector[25] = 32'd256;
        @(posedge Clock);
        RegWriteData = 32'd111;
        RegWriteIndex = 5'd22;
        RegWEn = 1;
        #1;
        RegWEn = 0;
        testVector[22] = 32'd111;
        @(posedge Clock);
        RegWriteData = 32'd32342;
        RegWriteIndex = 5'd31;
        RegWEn = 1;
        #1;
        RegWEn = 0;
        testVector[31] = 32'd32342;

        for(i = 0; i < loops / 2; i = i + 1)
        begin
            RegReadIndex1 = i * 2;
            RegReadIndex2 = i * 2 + 1;

            DUTout = RegReadData1;
            REFout = testVector[i*2];
            checkOutput();
            DUTout = RegReadData2;
            REFout = testVector[i*2 + 1];
            checkOutput();
        end
        for(i = 0; i < loops / 2; i = i + 1)
        begin
            RegReadIndex2 = i * 2;
            RegReadIndex1 = i * 2 + 1;

            DUTout = RegReadData2;
            REFout = testVector[i*2];
            checkOutput();
            DUTout = RegReadData1;
            REFout = testVector[i*2 + 1];
            checkOutput();
        end

        $display("\t\t Testing writing and reading from the same register.");
        
        RegWriteData = 32'd111;
        RegWriteIndex = 5'd4;
        testVector[4] = 32'd111;
        RegReadIndex1 = 5'd4;
        RegReadIndex2 = 5'd4;
        RegWEn = 1;
        #1;
        RegWEn = 0;
        DUTout = RegReadData1;
        REFout = testVector[4];
        checkOutput();
        DUTout = RegReadData2;
        REFout = testVector[4];
        checkOutput();

        RegWriteData = 32'd166;
        RegWriteIndex = 5'd7;
        testVector[7] = 32'd166;
        RegReadIndex1 = 5'd4;
        RegReadIndex2 = 5'd7;
        RegWEn = 1;
        #1;
        RegWEn = 0;
        DUTout = RegReadData1;
        REFout = testVector[4];
        checkOutput();
        DUTout = RegReadData2;
        REFout = testVector[7];
        checkOutput();
        RegWriteData = 32'd111;
        RegWriteIndex = 5'd0;
        RegReadIndex1 = 5'd0;
        RegReadIndex2 = 5'd0;
        RegWEn = 1;
        #1;
        RegWEn = 0;
        DUTout = RegReadData1;
        REFout = testVector[0];
        checkOutput();
        DUTout = RegReadData2;
        REFout = testVector[0];
        checkOutput();




        $display("\n\nALL TESTS PASSED!");
        $vcdplusoff;
        $finish();
    end

  endmodule
