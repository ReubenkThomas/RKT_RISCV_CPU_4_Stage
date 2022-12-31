`include "RegNames.vh"

module RegFile(
    input RegWriteData,
    input RegWriteIndex,
    input RegReadIndex1,
    input RegReadIndex2,
    input RegWEn,
    input clk,
    input reset,
    output reg RegReadData1,
    output reg RegReadData2
);

    REGISTER_R_CE #(.N(32), .INIT(0)) x0 (
        .q(RegWriteData),
        .d(regOut00),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x1 (
        .q(RegWriteData),
        .d(regOut01),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x2 (
        .q(RegWriteData),
        .d(regOut02),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x3 (
        .q(RegWriteData),
        .d(regOut03),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x4 (
        .q(RegWriteData),
        .d(regOut04),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x5 (
        .q(RegWriteData),
        .d(regOut05),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x6 (
        .q(RegWriteData),
        .d(regOut06),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x7 (
        .q(RegWriteData),
        .d(regOut07),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x8 (
        .q(RegWriteData),
        .d(regOut08),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x9 (
        .q(RegWriteData),
        .d(regOut09),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x10 (
        .q(RegWriteData),
        .d(regOut10),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x11 (
        .q(RegWriteData),
        .d(regOut11),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x12 (
        .q(RegWriteData),
        .d(regOut12),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x13 (
        .q(RegWriteData),
        .d(regOut13),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x14 (
        .q(RegWriteData),
        .d(regOut14),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x15 (
        .q(RegWriteData),
        .d(regOut15),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x16 (
        .q(RegWriteData),
        .d(regOut16),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x17 (
        .q(RegWriteData),
        .d(regOut17),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x18 (
        .q(RegWriteData),
        .d(regOut18),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x19 (
        .q(RegWriteData),
        .d(regOut19),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x20 (
        .q(RegWriteData),
        .d(regOut20),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x21 (
        .q(RegWriteData),
        .d(regOut21),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x22 (
        .q(RegWriteData),
        .d(regOut22),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x23 (
        .q(RegWriteData),
        .d(regOut23),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x24 (
        .q(RegWriteData),
        .d(regOut24),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x25 (
        .q(RegWriteData),
        .d(regOut25),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x26 (
        .q(RegWriteData),
        .d(regOut26),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x27 (
        .q(RegWriteData),
        .d(regOut27),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x28 (
        .q(RegWriteData),
        .d(regOut28),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x29 (
        .q(RegWriteData),
        .d(regOut29),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );


    REGISTER_R_CE #(.N(32), .INIT(0)) x30 (
        .q(RegWriteData),
        .d(regOut30),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    REGISTER_R_CE #(.N(32), .INIT(0)) x31 (
        .q(RegWriteData),
        .d(regOut31),
        .ce(RegWen),
        .rst(rst),
        .clk(clk)
    );

    always @(*) begin
        case(RegReadIndex1)
            `x0  : RegReadData1 <= regOut00;
            `x1  : 
            `x2  :
            `x3  :
            `x4  :
            `x5  :
            `x6  :
            `x7  :
            `x8  :
            `x9  :
            `x10 :
            `x11 :
            `x12 :
            `x13 :
            `x14 :
            `x15 :
            `x16 :
            `x17 :
            `x18 :
            `x19 :
            `x20 :
            `x21 :
            `x22 :
            `x23 :
            `x24 :
            `x25 :
            `x26 :
            `x27 :
            `x28 :
            `x29 :
            `x30 :
            `x31 :

        endcase
    end

endmodule