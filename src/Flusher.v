/*
Module:
    Flusher (Flusher)

Description:
    Based on the result output from the BranchChecker, it will determine if that result necessitates
    a flush to the FD registers. 

Input:
    result: 3'bit signal from the BranchChecker Read BranchChecker.v to know how the result is 
            interpreted.

Output:
    flush: 1-bit signal to say if the FD registers need to be flushed.

Authors:
    Matthew Dharmawan and Reuben Koshy Thomas
*/

module Flusher (
    input [2:0] result,

    output flush
);

assign flush = (result == 3'b100 | result == 3'b110);

endmodule