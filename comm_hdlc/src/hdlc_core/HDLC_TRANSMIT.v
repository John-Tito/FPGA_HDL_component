// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module HDLC_TRANSMIT (
    // global
    input wire Rstn,  // Master reset
    input wire Clk,   // Clock

    // HDLC
    output reg STX,  // serial data

    // master
    input  wire [7:0] TxInputData,  // data to be transferd
    output reg        TxInputReq,   // request to get new data
    input  wire       TxEmpty,      // No more Data to transfer
    input  wire       TxStart,      // Start the transfer
    input  wire       TxAbort,      // Abort the transfer
    input  wire       TxEnable,     // Tx strobe
    output reg        TxBusy,       // Transfer is in progress
    output reg        TxFlag
);

    // fsm for flag insert
    localparam FL0 = 8'b00000000;
    localparam FL1 = 8'b00000001;
    localparam FL2 = 8'b00000010;
    localparam FL3 = 8'b00000100;
    localparam FL4 = 8'b00001000;
    localparam FL5 = 8'b00010000;
    localparam FL6 = 8'b00100000;
    localparam FL7 = 8'b01000000;
    localparam NF = 8'b10000000;

    reg  [ 8:0] FlagState;
    reg         FlagFields;  // flag

    reg         AbortLatch;
    reg         Abort;
    reg         Aborting;  // indicator to send Abort flag

    reg         StartLatch;
    reg         Start;
    reg         StartAck;  // indicator to send start flag

    wire        ZeroStuffIn;  // serial data after zero stuff process
    reg         ZeroStuffOut;  // serial data after zero stuff process
    wire        ZeroStuffHold;
    reg  [ 4:0] ZeroStuffShift;  // shift register

    wire        TxLoad;  // load data into shift register
    reg  [ 7:0] TxBuffer;  // shift register
    reg  [ 7:0] TxShift;  // shift register

    wire        FCSen;  // enable crc calculate
    wire        FCSIn;  // data input to crc module
    reg         FCSClear;  // clear crc
    wire [15:0] FCSShift;  // Parallel CRC values
    wire        FCSValid;  // CRC value is valid
    reg         FCSFields;  // crc send phase
    reg  [ 1:0] FCSCnt;  //

    reg  [ 2:0] TS_CNT;  // counter

    reg         latch;
    reg         latchD;
    reg         NotLastByte;  // last byte have been read out
    reg         NotLastByteD;

    always @(posedge Clk) begin
        if (!Rstn) begin
            FlagState <= FL0;
        end else if (TxEnable) begin
            case (FlagState)
                FL0: FlagState <= FL1;
                FL1: FlagState <= FL2;
                FL2: FlagState <= FL3;
                FL3: FlagState <= FL4;
                FL4: FlagState <= FL5;
                FL5: FlagState <= FL6;
                FL6: FlagState <= FL7;
                FL7, NF: begin
                    if (!FlagFields) FlagState <= NF;
                    else FlagState <= FL0;
                end
                default: FlagState <= FL0;
            endcase
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            STX <= 1'b1;
        end else if (TxEnable) begin
            case (FlagState)
                FL0, FL7: STX <= 1'b0;
                NF: STX <= ZeroStuffOut | Aborting;
                default: STX <= 1'b1;
            endcase
        end
    end

    assign ZeroStuffIn   = FCSFields ? (~FCSShift[15]) : TxShift[0];
    assign ZeroStuffHold = (5'b11111 == ZeroStuffShift) ? 1'b1 : 1'b0;
    always @(posedge Clk) begin
        if (!Rstn || FCSClear) begin
            ZeroStuffShift <= 5'b00000;
        end else if (TxEnable) begin
            if (ZeroStuffHold) ZeroStuffShift <= {ZeroStuffShift[3:0], 1'b0};
            else ZeroStuffShift <= {ZeroStuffShift[3:0], ZeroStuffIn};
        end
    end

    always @(posedge Clk) begin
        if (!Rstn || FCSClear) begin
            ZeroStuffOut <= 1'b0;
        end else if (TxEnable) begin
            ZeroStuffOut <= ZeroStuffHold ? 1'b0 : ZeroStuffIn;
        end
    end
    // assign ZeroStuffOut = ZeroStuffHold ? 1'b0 : ZeroStuffIn;

    // ***********************************************************************************
    // tx data
    always @(posedge Clk) begin
        if (!Rstn) begin
            TxBuffer <= 8'h00;
        end else if (TxEnable && (latchD)) begin
            TxBuffer <= TxInputData;
            $display("latch: %2x to tx", TxInputData);
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            TxShift <= 8'h00;
        end else if (TxEnable && (!ZeroStuffHold)) begin
            if (TxLoad) begin
                TxShift <= TxBuffer;
            end else begin
                TxShift <= {1'b0, TxShift[7:1]};
            end
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            TS_CNT <= 3'h0;
        end else if (TxEnable) begin
            if (FlagFields || Abort) begin
                TS_CNT <= 3'h0;
            end else if (Aborting || !ZeroStuffHold) begin
                TS_CNT <= TS_CNT + 3'h1;
            end
        end
    end

    // ***********************************************************************************
    // fcs
    assign FCSen = TxEnable & (~ZeroStuffHold);
    assign FCSIn = (FCSFields) ? FCSShift[15] : TxShift[0];
    HDLC_SERIAL_CRC #(
        .INIT(16'hFFFF)
    ) HDLC_SERIAL_CRC_dut (
        .Clk      (Clk),
        .Rstn     (Rstn),
        .En       (FCSen),
        .Clr      (FCSClear),
        .SData    (FCSIn),
        .PCRC     (FCSShift),
        .SCRC     (),
        .SCRCValid(FCSValid)
    );

    always @(posedge Clk) begin
        if (!Rstn || FCSClear) begin
            FCSCnt <= 2'b00;
        end else if (TxEnable && (!ZeroStuffHold)) begin
            if (!FCSFields) begin
                FCSCnt <= 2'b00;
            end else if (3'b111 == TS_CNT) begin
                FCSCnt <= FCSCnt + 1;
            end
        end
    end

    // request for new data
    always @(posedge Clk) begin
        if (!Rstn) begin
            TxInputReq <= 1'b0;
        end else if (TxEnable) begin
            if (StartAck && (FL3 == FlagState)) begin
                TxInputReq <= 1'b1;
                $display("request new data from fifo");
            end else if (!ZeroStuffHold && (3'b101 == TS_CNT) && (NotLastByte || NotLastByteD)) begin
                TxInputReq <= 1'b1;
                $display("request new data from fifo");
            end else begin
                TxInputReq <= 1'b0;
            end
        end else begin
            TxInputReq <= 1'b0;
        end
    end

    // latch data
    always @(posedge Clk) begin
        if (!Rstn) begin
            latch <= 1'b0;
        end else if (TxEnable) begin
            if (StartAck && (FL3 == FlagState)) begin
                latch <= 1'b1;
            end else if (!ZeroStuffHold && (3'b101 == TS_CNT) && (NotLastByte || NotLastByteD)) begin
                latch <= 1'b1;
            end else begin
                latch <= 1'b0;
            end
        end
    end

    // latch data delay
    always @(posedge Clk) begin
        if (!Rstn) begin
            latchD <= 1'b0;
        end else if (TxEnable) begin
            latchD <= latch;
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            NotLastByte <= 1'b0;
        end else if (FL0 == FlagState) begin
            NotLastByte <= 1'b1;
        end else if (TxEnable && latchD) begin
            NotLastByte <= ~TxEmpty;
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            NotLastByteD <= 1'b0;
        end else if (TxEnable && TxLoad && (!ZeroStuffHold)) begin
            NotLastByteD <= NotLastByte;
        end
    end
    assign TxLoad = (((NotLastByte) || (NotLastByteD)) && (3'h0 == TS_CNT)) ? 1'b1 : 1'b0;

    // start
    always @(posedge Clk) begin
        if (!Rstn) begin
            StartLatch <= 1'b0;
        end else if (Abort || Start) begin
            StartLatch <= 1'b0;
        end else if (TxStart) begin
            StartLatch <= 1'b1;
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            Start <= 1'b0;
        end else if (TxEnable) begin
            Start <= StartLatch;
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            StartAck <= 1'b0;
        end else if (TxEnable) begin
            if (!FlagFields) begin
                StartAck <= 1'b0;
            end else if (Start && !TxEmpty) begin
                StartAck <= 1'b1;
            end
        end
    end

    // abort
    always @(posedge Clk) begin
        if (!Rstn) begin
            AbortLatch <= 1'b0;
        end else if (Abort) begin
            AbortLatch <= 1'b0;
        end else if (TxAbort) begin
            AbortLatch <= 1'b1;
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            Abort <= 1'b0;
        end else if (TxEnable) begin
            Abort <= AbortLatch;
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            Aborting <= 1'b0;
        end else if (TxEnable) begin
            if (FlagFields) begin
                Aborting <= 1'b0;
            end else if (Abort) begin
                Aborting <= 1'b1;
            end
        end
    end

    //
    always @(posedge Clk) begin
        if (!Rstn) begin
            FlagFields <= 1'b1;
        end else if (TxEnable && (!ZeroStuffHold)) begin
            if (Aborting && (3'b111 == TS_CNT)) begin
                FlagFields <= 1'b1;
            end else if (2'b10 == FCSCnt) begin
                FlagFields <= 1'b1;
            end else if (latchD) begin
                FlagFields <= 1'b0;
            end
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            FCSClear <= 1'b1;
        end else if (TxEnable) begin
            FCSClear <= FlagFields;
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            FCSFields <= 1'b0;
        end else if (TxEnable && (!ZeroStuffHold)) begin
            if (FL7 == FlagState || Aborting || FlagFields) begin
                FCSFields <= 1'b0;
            end else if (!FlagFields && !NotLastByte && !NotLastByteD && (0 == TS_CNT)) begin
                FCSFields <= 1'b1;
            end
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            TxBusy <= 1'b0;
        end else begin
            TxBusy <= ~FlagFields | (Aborting) | (StartAck) | (TS_CNT != 3'b000);
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            TxFlag <= 1'b0;
        end else begin
            TxFlag <= (FL7 == FlagState) & TxEnable;
        end
    end
endmodule

// verilog_format: off
`resetall
// verilog_format: on
