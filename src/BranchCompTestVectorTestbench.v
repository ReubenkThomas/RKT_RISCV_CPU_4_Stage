/*
Module:  
    BranchCompTestVectorTestbench

Description:    
    Random testing of the Branch Comparator for the RISC-V Processor

Input:
    branchcomptestvectors.input generated by BranchCompTestGen.py

Authors: 
    Matthew Dharmawan and Reuben Koshy Thomas
*/


`timescale 1ns / 1ps

module BranchCompTestVectorTestbench();

    parameter Halfcycle = 5; //half period is 5ns

    localparam Cycle = 2*Halfcycle;

    reg Clock;

    // Clock Signal generation:
    initial Clock = 0; 
    always #(Halfcycle) Clock = ~Clock;

    // Wires to test the ALU
    // These are read from the input vector
    reg [31:0] inst;
    reg [2:0] funct3;
    reg [31:0] rs1;
    reg [31:0] rs2;
    reg brun;
    reg REFLT;
    reg REFEQ;

    wire DUTLT;
    wire DUTEQ;
    //wire [3:0] ImmSel
    
    

    // Task for checking output
    task checkOutput;
        input [2:0] funct3;
        input [31:0] rs1;
        input [31:0] rs2;
        input brun;
        input REFEQ;
        input REFLT;

        if ( REFLT !== DUTLT || REFEQ !== DUTEQ) begin
            $display("FAIL: Incorrect result for funct3 = %b, rs1 = %b, rs2 = %b, brun = %b, (REFEQ, DUTEQ) = (%b, %b), (REFLT, DUTLT) = (%b, %b)", funct3, rs1, rs2, brun, REFEQ, DUTEQ, REFLT, DUTLT);
        $finish();
        end
        else begin
            $display("Pass:   Correct result for funct3 = %b, rs1 = %b, rs2 = %b, brun = %b, (REFEQ, DUTEQ) = (%b, %b), (REFLT, DUTLT) = (%b, %b)", funct3, rs1, rs2, brun, REFEQ, DUTEQ, REFLT, DUTLT);

        end
    endtask


    // This is where the modules being tested are instantiated. 
    BranchComp DUT (
        .dataA(rs1),
        .dataB(rs2),
        .BrUn(brun),
        .BrEq(DUTEQ),
        .BrLT(DUTLT)
    );

    /////////////////////////////////////////////////////////////////
    // Change this number to reflect the number of testcases in your
    // testvector input file, which you can find with the command:
    // % wc -l ../sim/tests/testvectors.input
    // //////////////////////////////////////////////////////////////
    localparam loops = 1000;
    localparam testcases = loops * 6;

    reg [69:0] testvector [0:testcases-1]; // Each testcase has 70 bits:


    integer i; // integer used for looping in non-generate statement

    initial 
    begin
        $vcdpluson;
        $readmemb("/home/cc/eecs151/fa22/class/eecs151-aal/fa22_asic_team10/tests/branchcomptestvectors.input", testvector);
        for (i = 0; i < testcases; i = i + 1) begin
            // opcode = testvector[i][106:100];
            // funct = testvector[i][99:97];
            // add_rshift_type = testvector[i][96];
            // A = testvector[i][95:64];
            // B = testvector[i][63:32];
            // REFout = testvector[i][31:0];
            funct3 =    testvector[i][69:67];
            rs1 =       testvector[i][66:35];
            rs2 =       testvector[i][34:3];
            brun =      testvector[i][2];
            REFEQ =     testvector[i][1];
            REFLT =     testvector[i][0];
            #1;
            
            checkOutput(funct3, rs1, rs2, brun, REFEQ, REFLT);
        end
        $display("\n\nALL TESTS PASSED!");
        $display("\n\nNumber of testcases ran: %d\n", testcases);
        $vcdplusoff;
        $finish();
    end

endmodule
