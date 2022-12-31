/*
Module: 
    LoadExtenderTestVectorTestbench

Description:   
    Randomized vector testbench for the RISC-V Processor Load Extender

Input:
    loadextendertestvectors.input generated by LoadExtenderTestGen.py

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas

 */

`timescale 1ns / 1ps

module LoadExtenderTestVectorTestbench();

    parameter Halfcycle = 5; //half period is 5ns

    localparam Cycle = 2*Halfcycle;

    reg Clock;

    // Clock Signal generation:
    initial Clock = 0; 
    always #(Halfcycle) Clock = ~Clock;


    wire [31:0] DUTout;
    reg [2:0] f3;
    reg [31:0] REFout;
    reg [31:0] DataR;


    // Task for checking output
    task checkOutput;
        input [31:0] DataR;
        input [2:0] f3;
        input [31:0] REFout;
        if ( REFout !== DUTout ) begin
            $display("FAIL: Incorrect result for DataR: %b, f3: %b, REFout: %b, DUTout: %b", DataR, f3, REFout, DUTout);
        $finish();
        end
        else begin
            $display("Pass:   Correct result for DataR: %b, f3: %b, REFout: %b, DUTout: %b", DataR, f3, REFout, DUTout);       
        end
    endtask


    // This is where the modules being tested are instantiated. 
    LoadExtender DUT1(
        .DataR(DataR),
        .LdSel(f3),
        .Output(DUTout)
    );

    /////////////////////////////////////////////////////////////////
    // Change this number to reflect the number of testcases in your
    // testvector input file, which you can find with the command:
    // % wc -l ../sim/tests/testvectors.input
    // //////////////////////////////////////////////////////////////
    localparam loops = 1000;
    localparam testcases = loops * 5;

    reg [66:0] testvector [0:testcases-1]; // Each testcase has 67 bits:


    integer i; // integer used for looping in non-generate statement

    initial 
    begin
        $vcdpluson;
        $readmemb("/home/cc/eecs151/fa22/class/eecs151-aal/fa22_asic_team10/tests/loadextendertestvectors.input", testvector);
        for (i = 0; i < testcases; i = i + 1) begin
            // opcode = testvector[i][106:100];
            // funct = testvector[i][99:97];
            // add_rshift_type = testvector[i][96];
            // A = testvector[i][95:64];
            // B = testvector[i][63:32];
            // REFout = testvector[i][31:0];
            
            DataR =     testvector[i][66:35];
            f3 =        testvector[i][34:32];
            REFout =    testvector[i][31:0];
            #1;
            
            checkOutput(DataR, f3, REFout);
        end
        $display("\n\nALL TESTS PASSED!");
        $display("\n\nNumber of testcases ran: %d\n", testcases);
        $vcdplusoff;
        $finish();
    end

endmodule
