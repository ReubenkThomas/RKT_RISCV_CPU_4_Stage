`include "const.vh"
`include "Opcode.vh"
`include "ALUop.vh"
`include "ControlLogicSel.vh"
 
module Riscv151(
 input clk,
 input reset,
 
 // Memory system ports
 output [31:0] dcache_addr, // This is the address bits to the DMEM?
 output [31:0] icache_addr, // This is the PCRegister that is sent here?
 output [3:0] dcache_we, // Write enable DMEM?
 output dcache_re, // Read enable DMEM?
 output icache_re, // Read enable IMEM?
 output [31:0] dcache_din, // 
 input [31:0] dcache_dout, // This is the data that the DMEM will output.
 input [31:0] icache_dout, // This is the data that the IMEM will output. 
 input stall,
 output [31:0] csr
 
);


    /**************************************************************************************
    ALL REG AND WIRE DECLARATIONS
    **************************************************************************************/
    // FD->X Pipeline
    reg [31:0] inst_X;
    reg [31:0] immediateRegDtoX;
    reg [31:0] ADataRegDtoX;
    reg [31:0] BDataRegDtoX;
    reg [31:0] PCRegDtoX;
    reg predictionRegDtoX;

    // X->M Pipeline
    reg [31:0] inst_M;
    reg [31:0] ALUOutRegXtoM;
    reg [31:0] PCRegXtoM;
    
    reg [31:0] BDataRegXtoM;
    reg [31:0] AddrRegXtoM;

    // M->W Pipeline
    reg [31:0] inst_W;
    reg [31:0] MemResultRegMtoW;
    reg [31:0] ALUOutRegMtoW;
    reg [31:0] PCRegMtoW;
    
    // PC Register
    reg [31:0] PCReg;
    wire [31:0] PCPlus4;
    wire [31:0] PCPlusImm;
    wire [31:0] JalrWire; 
    wire [31:0] newPC;

    // Branch Prediction Related Wires
    wire [2:0] PCSel;
    wire jump;
    wire prediction;
    wire [2:0] result;

    // Control FD
    wire [2:0] AFwd;
    wire [2:0] BFwd;
    wire [31:0] newMemAddr;
    wire [31:0] PCXPlus4; // This is post addition. 
    wire flush;
    
    // Datapath FD
    wire [31:0] immediate;
    wire [31:0] ADataWire;
    wire [31:0] BDataWire;
    
    wire [31:0] RegReadData1;
    wire [31:0] RegReadData2;

    // Control X
    wire BrUn;
    wire BrEq;
    wire BrLT;
    wire [1:0] ASel;
    wire [1:0] BSel;
    wire AddrFwd;
    wire DataFwd;
    wire [3:0] MemRW;
    wire BranchAFwd;
    wire BranchBFwd;

    // Datapath X
    wire [31:0] ALUInA;
    wire [31:0] ALUInB;
    wire [3:0] ALUop;
    wire [31:0] ALUOutput;
    wire [31:0] DataIn;
    wire [31:0] StoreFormatterOut;

    // Control M
    wire [2:0] LdSel;

    // Datapath M
    wire [31:0] DMEMOut;
    wire [31:0] LdOut;
    

    // Control W
    wire [1:0] CSRSel;
    wire [1:0] WBSel;
    wire RegWEn;

    // Datapath W
    wire [31:0] RegWriteData;

    /**************************************************************************************
    Register Declaration and Propagation:
    This section of the core will propagate information to the next stage in the 
    pipeline. In our design, there are 4 stages to consider, and each have a certain
    amount of registers based on the data it needs to propagate. Here are the names
    and purpose that they serve. 

    Pipeline Register Names and Purpose:
    - Instruction Registers: These simply propagate the instruction down, so that the 
    appropriate control signal can determine what it needs to emit. Although there is
    a inst_FD, this is propagated out of the IMEM, so it will be known as icache_dout.
    - inst_X: This propagates the instruction from FD to X
    - inst_M: This propagates the instruction from X to M
    - inst_W: This propagates the instruction from M to W
    
    - FD -> X Pipeline Registers: These will take data from the forwarding mux as well
    as from the branch predictor so that the appropriate action can take place in the
    execute stage
    - immediateRegDtoX: This propagates the immediate to the X stage
    - ADataRegDtoX: This propagates the appropriate register or forwarded value to 
    the X stage
    - BDataRegDtoX: Same thing, but for the second register.
    - PCRegDtoX: This propagates the PC value to the X stage.
    - predictionRegDtoX: This is a 1-bit signal sent from PCSel to BranchChecker.
    
    - X -> M Pipeline Registers: These will take data from the ALU to be acted upon in 
    the memory stage. 
    - ALUOutRegXtoM: This propagates the result of the ALU to the memory stage
    - BDataRegXtoM: This propagates the value in rs2 to the DMEM for stores
    - PCRegXtoM: This propagates the PC value to the M stage (at this point it is 
    PC + 4)
    
    - M -> W Pipeline Registers: These will take the ALU, MEM, PC values, which will be
    chosen from later in the W stage
    - MemResultRegMtoW: This is the result from the DMEM
    - ALUOutRegMtoW: This is the result from the ALU
    - PCRegMtoW: This is the PC value from the M stage (PC + 4, as compared to 
    the FD stage)
    **************************************************************************************/
    
    // Logic to determine if FD needs to
    Flusher flusher (
    .result(result),
    .flush(flush)
    );

    // Here is the propagation of registers in the pipeline.
    always @(posedge clk) begin
        if (~stall & ~reset) begin
            if (flush) begin // Flushing Logic.
                PCReg <= newPC;
                inst_X <= 32'h00000013;
                PCRegDtoX <= 0;
                immediateRegDtoX <= 0;
                predictionRegDtoX <= 0;
                ADataRegDtoX <= 0;
                BDataRegDtoX <= 0;
            end else begin
                PCReg <= newPC;

                inst_X <= icache_dout;
                PCRegDtoX <= PCReg;
                immediateRegDtoX <= immediate;
                predictionRegDtoX <= prediction;
                ADataRegDtoX <= ADataWire;
                BDataRegDtoX <= BDataWire;
                // X -> M propagation
                inst_M <= inst_X;
                PCRegXtoM <= PCXPlus4;
                ALUOutRegXtoM <= ALUOutput;
                BDataRegXtoM <= BDataRegDtoX;
                AddrRegXtoM <= dcache_addr;

                // M -> W propagation
                inst_W <= inst_M;
                PCRegMtoW <= PCRegXtoM;
                ALUOutRegMtoW <= ALUOutRegXtoM;
                MemResultRegMtoW <= LdOut;
            end
        end 
        // else if (icache_dout[6:0] == inst_X[6:0] & (inst_X[6:0] == `OPC_LOAD | inst_X[6:0] == `OPC_STORE)) begin
        //     inst_X <= 32'h00000013;
        //     PCRegDtoX <= 0;
        //     PCRegDtoX <= 0;
        //     immediateRegDtoX <= 0;
        //     predictionRegDtoX <= 0;
        //     ADataRegDtoX <= 0;
        //     BDataRegDtoX <= 0;

        //     inst_M <= inst_X;
        //     PCRegXtoM <= PCXPlus4;
        //     ALUOutRegXtoM <= ALUOutput;
        //     BDataRegXtoM <= BDataRegDtoX;
        //     AddrRegXtoM <= dcache_addr;

        //     // M -> W propagation
        //     inst_W <= inst_M;
        //     PCRegMtoW <= PCRegXtoM;
        //     ALUOutRegMtoW <= ALUOutRegXtoM;
        //     MemResultRegMtoW <= LdOut;
        
        // end
    end
    
    /**************************************************************************************
    Fetch and Decode Stage:
    This stage will be responsible for fetching the instruction as well as decoding 
    what instruction it is. 

    Modules in the FD Stage:
    - RegFile: Register File that supports asynchronous reads and synchronous writes. The
    value will be written to on the posedge of the clk, and can be read at any time. 
    It will only write if RegWEn is ON. 
    - ImmGen: Will create an immediate based on the instruction passed into it.
    - BranchPredictor: Will choose the next PC value
    - AFwdMux: Will decide how to send rs1 to the X stage if it will forward or not.
    - BFwdMux: Will decide how to send rs2 to the X stage if it will forward or not.
    
    Control Signals:
    - PCSel: Chooses between 5 possible signals. Its decision is based on the 
    BranchPredictor. This code is located right after the Execute stage.
    - AFwd: Chooses what data will be passed on to the X stage in rs1.
    - BFwd: Chooses what data will be passed on to the X stage in rs2.
    (Note that RegWEn signal is chosen in the W stage)

    TODO:
    - Ensure the data is forwarded properly
    - Dealing with the IMEM
    - JALR
    **************************************************************************************/
    
    assign icache_re = ~(dcache_re | (|dcache_we));

    // Determine the Control signals for FD Forwarding.
    StageFD controlFD( 
        .inst_FD(icache_dout),
        .inst_X(inst_X),
        .inst_M(inst_M),
        .inst_W(inst_W),

        .AFwd(AFwd),
        .BFwd(BFwd)
    );
    
    RegFile rf (
        .RegWriteData(RegWriteData),
        .RegWriteIndex(inst_W[11:7]),
        .RegReadIndex1(icache_dout[19:15]),
        .RegReadIndex2(icache_dout[24:20]),
        .RegWEn(RegWEn),
        .clk(clk),
        .reset(reset),
        .RegReadData1(RegReadData1),
        .RegReadData2(RegReadData2)
    );
    
    // Develop the immediate
    ImmGen ImmGen(
        .inst(icache_dout),
        .imm(immediate)
    );
    
    // Determine if FD Forwarding is needed.
    reg [31:0] regADataWire;
    assign ADataWire = regADataWire;
    reg [31:0] regBDataWire;
    assign BDataWire = regBDataWire;
    always @(*) begin
        case(AFwd)
            `AFwd_REG : regADataWire <= RegReadData1;
            `AFwd_ALUX : regADataWire <= ALUOutput;
            `AFwd_ALUM : regADataWire <= ALUOutRegXtoM;
            `AFwd_MEM : regADataWire <= LdOut;
            `AFwd_JX : regADataWire <= PCXPlus4;
            `AFwd_JM : regADataWire <= PCRegXtoM;
            `AFwd_WB : regADataWire <= RegWriteData;

            // `AFwd_ALU : regADataWire <= ALUOutput;
            // `AFwd_MEM : regADataWire <= LdOut;
            // `AFwd_REG : regADataWire <= RegReadData1;
            // `AFwd_PCX : regADataWire <= PCXPlus4;
            // `AFwd_PCM : regADataWire <= PCRegXtoM;
        endcase

        case(BFwd)
            `BFwd_REG : regBDataWire <= RegReadData2;
            `BFwd_ALUX : regBDataWire <= ALUOutput;
            `BFwd_ALUM : regBDataWire <= ALUOutRegXtoM;
            `BFwd_MEM : regBDataWire <= LdOut;
            `BFwd_JX : regBDataWire <= PCXPlus4;
            `BFwd_JM : regBDataWire <= PCRegXtoM;
            `BFwd_WB : regBDataWire <= RegWriteData;
        endcase
    end

    
    // Determine all the possible PCMux Values
    
    assign PCPlus4 = PCReg + 32'd4;
    // ALUOut Determined in ALU module
    assign PCPlusImm = PCReg + immediate; 
    assign PCXPlus4 = PCRegDtoX + 32'd4;
    assign JalrWire = ADataWire + immediate;

    // Determining the New PC Value.
    reg [31:0] regNewPC;
    assign newPC = regNewPC;
    always @(*) begin
        if (~stall) begin
        case (PCSel)
            `PCSel_PCPLUS4 : regNewPC <= PCPlus4; 
            `PCSel_ALU : regNewPC <= ALUOutput;
            `PCSel_PCPLUSIMM : regNewPC <= PCPlusImm;
            `PCSel_PCXPLUS4 : regNewPC <= PCXPlus4;
            `PCSel_JALR : regNewPC <= JalrWire;
            `PCSel_SAME : regNewPC <= PCReg;
        endcase 
        end
    
    end
    
    
    // Place the newPC value into the input for IMEM Address.
    reg [32:0] icacheReg;
    always @(posedge clk) begin
        if (~stall & ~reset) begin
        end
    end
    assign icache_addr = newPC;
    
    /**************************************************************************************
    Execute Stage:
    This stage deals with the branch comparison, ASelMux, BSelMux, ALU.
    
    Modules in the X Stage:
    - BranchComp:
    - ASelMux
    - BSelMux
    - ALU

    Control Signals in the X Stage:
    - BrUn
    - ASel
    - BSel
    - ALUdec

    TODO: 
    - Make sure the datapath works correctly.
    **************************************************************************************/


    wire [31:0] BranchInA;
    wire [31:0] BranchInB;
    
    // Determine all the control signals.
    StageX controlX (
        .inst_X(inst_X),
        .inst_M(inst_M),
        .ALUOutXTwoBit(ALUOutput[1:0]),
        .ASel(ASel),
        .BSel(BSel),
        .BrUn(BrUn),
        .ALUop(ALUop),
        .AddrFwd(AddrFwd),
        .DataFwd(DataFwd),
        .MemRW(MemRW),
        .BranchAFwd(BranchAFwd),
        .BranchBFwd(BranchBFwd)
    );
    

    assign BranchInA = BranchAFwd ? LdOut : ADataRegDtoX;
    assign BranchInB = BranchBFwd ? LdOut : BDataRegDtoX;
    // Do Branch Comparison if necessary.
    BranchComp branchcomp (
        .dataA(BranchInA),
        .dataB(BranchInB),
        .BrUn(BrUn),
        .BrEq(BrEq),
        .BrLT(BrLT)
    );



    // Determine ASel and BSel MUX Results.
    reg [31:0] regALUInA;
    assign ALUInA = regALUInA;
    always @(*) begin
        case (ASel) 
            `ASel_REG : regALUInA <= ADataRegDtoX;
            `ASel_PC : regALUInA <= PCRegDtoX;
            `ASel_MEM : regALUInA <= LdOut;
            default : regALUInA <= ADataRegDtoX;
        endcase
    end

    reg [31:0] regALUInB;
    assign ALUInB = regALUInB;
    always @(*) begin
        case (BSel) 
            `BSel_REG : regALUInB <= BDataRegDtoX;
            `BSel_IMM : regALUInB <= immediateRegDtoX;
            `BSel_MEM : regALUInB <= LdOut;
            default : regALUInB <= BDataRegDtoX;
        endcase
    end
    
    // Do arithmetic to the result of the ASel and BSel choice.
    ALU alu (
        .A(ALUInA),
        .B(ALUInB),
        .ALUop(ALUop),

        .Out(ALUOutput)
    );
    
    // Determine if fowarding is needed for address and data in DMEM.
    reg [31:0] regAddrIn;
    assign newMemAddr = immediateRegDtoX + LdOut;
    assign dcache_addr = regAddrIn;
    always @(*) begin
        case (AddrFwd) 
            `AddrFwd_REG : regAddrIn <= ALUOutput;
            `AddrFwd_MEM : regAddrIn <= newMemAddr;
        endcase
    end

    reg [31:0] regDataIn;
    assign DataIn = regDataIn;
    always @(*) begin
        case (DataFwd)
            `DataFwd_REG : regDataIn <= BDataRegDtoX;
            `DataFwd_MEM : regDataIn <= LdOut;
        endcase
    end

    // Now Format the forwarded data.
    
    
    StoreFormatter storeformatter (
        .DataIn(DataIn),
        .inst_X(inst_X),
        .ALUOutXTwoBit(ALUOutput[1:0]),

        .StoreFormatterOut(StoreFormatterOut)
    );
    
    
    // Set the inputs to DMEM
    assign dcache_re = (inst_X[6:0] == `OPC_LOAD & ~flush & ~stall);
    assign dcache_din = StoreFormatterOut;
    assign dcache_we = MemRW;
    /**************************************************************************************
    Branch Prediction:
    Here we input the logic for branch prediction, which involves the combination of
    PCSel, BranchPredictor, and BranchChecker.

    How the Three Will Interact:
    - BranchChecker: In the Execute stage, the BranchComp will output BrLt and BrEq to the
    module. In addition, the inst_X will also be passed in, as well as a predict signal
    from the BranchPredictor. With all these inputs, the Prediction Checker will output
    a 3-bit signal, which is sent to the BranchPrediction
    - BranchPrediction: Based on the result sent by the PredictionChecker, it will 
    accordingly change the state of a special branching register.
    - PCSel: Will take the result from the BranchChecker as well as the inst_FD, and then 
    output an appropriate PCSel output. 

    There is also the propagation from the PCSel if it finds a branch instruction.

    TODO:
    - Make sure it works correctly.
    **************************************************************************************/
    // Wires that communicate between the three.
    

    // PCSel
    PCSel pcsel (
        .inst(icache_dout), // Instruction Pipeline
        .result(result), // From BranchChecker
        .jump(jump), // From BranchPrediction
        .stall(stall),
        .PCSel(PCSel), // Output to PCSelMux
        .predict(prediction) // Output to prediction -> predictionRegDtoX pipeline
    );

    // BranchPrediction
    BranchPredictor #(.N(2)) branchpredictor (
        .clk(clk),
        .result(result), // From BranchChecker
        .rst(reset), // Core access
        .forcer(1'b11), // Always jump
        .jump(jump) // Output to PCSel
    );

    // BranchChecker
    BranchChecker branchchecker (
        .inst(inst_X), // Instruction Pipeline
        .predict(predictionRegDtoX), // From predictionRegDtoX pipeline (from PCSel)
        .BrLT(BrLT), // From BranchComp
        .BrEq(BrEq), // From BranchComp

        .result(result) // Sent to BranchPrediction (to change state) and PCSel (to choose PCSel)
    );


    /**************************************************************************************
    Memory Stage:
    Here, the memory stage includes the DMEM and LoadExtender. This will take in data
    from the ALU and possibly rs2 when loading and storing. 
    
    Modules:
    - Cache: Good luck with this
    - LoadExtender: This will take the output from DMEM and extend it correctly into
    32-bits. This requires the LdSel to help decide how to create this 32-bit value
    
    Control Signals:
    - MemRW: 
    - LdSel: 

    TODO: 
    - DMEM Cache 
    - LoadExtend
    - Make sure data forwarding from Mem-Decode works. 
    **************************************************************************************/

    // Determine the control signal for the memory stage.
    StageM stagem (
        .inst_M(inst_M),
        .LdSel(LdSel)
    );

    assign DMEMOut = dcache_dout;

    // Load Extender
    LoadExtender loadextender(
        .LdIn(DMEMOut),
        .ALUOutMTwoBit(AddrRegXtoM[1:0]),
        .LdSel(LdSel),
        .LdOut(LdOut)
    );


    /**************************************************************************************
    Writeback Stage:
    This module decides how the data fed in will be written to in the RegFile or CSR
    
    Modules in the W Stage:
    - WBSelMux
    - RegFile (Write)
    - CSRSelMux

    Control Signals:
    - WBSel
    - RegWEn
    - CSRSel
    **************************************************************************************/

    // Determine the control signals in the Writeback stage.
    StageW stagew (
        .inst_W(inst_W),
        .WBSel(WBSel),
        .RegWEn(RegWEn),
        .CSRSel(CSRSel)
    );
    
    // Allow the value that is written to the register to pass.
    reg [31:0] regRegWriteData;
    assign RegWriteData = regRegWriteData;
    always @(*) begin
        case(WBSel)
            2'b00: regRegWriteData <= MemResultRegMtoW;
            2'b01: regRegWriteData <= ALUOutRegMtoW;
            2'b10: regRegWriteData <= PCRegMtoW;
        endcase
    end

    // Determine if a write to CSR is necessary.
    reg [31:0] regCSR;
    assign csr = regCSR;
    always @(*) begin
        case (CSRSel)
            `CSR_REG : regCSR <= RegWriteData;
            `CSR_IMM : regCSR <= {{27{1'b0}}, inst_W[19:15]};
            `CSR_ZERO : regCSR <= {32{1'b0}};
            default : regCSR <= {32{1'b0}};
        endcase
    end

    /**************************************************************************************
    Miscellaneous: Reset
    **************************************************************************************/
    // Reset if resent changes on
    always @(posedge clk) begin
        if (reset) begin
            inst_X <= 32'd0;
            inst_M <= 32'd0;
            inst_W <= 32'd0;
            PCReg <= `PC_RESET - 4;
            inst_X <= 32'd0;
            immediateRegDtoX <= 32'd0;
            ADataRegDtoX <= 32'd0;
            BDataRegDtoX <= 32'd0;
            PCRegDtoX <= 32'd0;
            predictionRegDtoX <= 1'd0;
            inst_M <= 32'd0;
            ALUOutRegXtoM <= 32'd0;
            PCRegXtoM <= 32'd0;
            BDataRegXtoM <= 32'd0;
            inst_W <= 32'd0;
            MemResultRegMtoW <= 32'd0;
            ALUOutRegMtoW <= 32'd0;
            PCRegMtoW <= 32'd0;
        end
    end
endmodule
