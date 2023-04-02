// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on
module HDLC_TOP_tb;

    // Parameters
    localparam real TIMEPERIOD = 5;

    // Ports
    reg        Clk = 0;
    reg        Rstn = 0;
    wire       TxClk;
    wire       STx;
    reg        RxClk = 0;
    reg        SRx = 0;


    wire [7:0] TxInputData;
    wire       TxInputReq;
    wire       TxEmpty;

    reg        TxEn = 0;
    reg        TxRstn = 0;
    reg        TxAbort = 0;
    wire       TxStart;
    wire       TxBusy;

    wire [7:0] RxOutputData;
    wire       RxOutputValid;
    reg        RxEn = 0;
    reg        RxRstn = 0;
    wire       RxBusy;
    wire       RxStart;
    wire       RxAbort;
    wire       RxEnd;
    wire       RxError;

    HDLC_TOP #(
        .CNT_WIDTH(32),
        .CPOL     (1'b0),
        .CPHA     (1'b1)
    ) HDLC_TOP_dut (
        .Clk          (Clk),
        .TxClk        (TxClk),
        .STx          (STx),
        .RxClk        (RxClk),
        .SRx          (SRx),
        .TxEn         (TxEn),
        .TxRstn       (TxRstn),
        .TxInputData  (TxInputData),
        .TxInputReq   (TxInputReq),
        .TxEmpty      (TxEmpty),
        .TxStart      (TxStart),
        .TxAbort      (TxAbort),
        .TxBusy       (TxBusy),
        .TxFlag       (),
        .RxEn         (RxEn),
        .RxRstn       (RxRstn),
        .RxOutputData (RxOutputData),
        .RxOutputValid(RxOutputValid),
        .RxBusy       (RxBusy),
        .RxStart      (RxStart),
        .RxAbort      (RxAbort),
        .RxEnd        (RxEnd),
        .RxError      (RxError),
        .RxByteLen    (),
        .RxBitLen     (),
        .RxKeepFlag   (1'b1),
        .BaudFreq     (12'd1),
        .BaudLimit    (16'd4),
        .OVSEn        (1'b1),
        .Loopback     (1'b1)
    );

    always @(posedge Clk) begin
        if (!Rstn) begin
            SRx   <= 1'b0;
            RxClk <= 1'b0;
        end else begin
            SRx   <= STx;
            RxClk <= TxClk;
        end
    end

    initial begin
        begin
            RxRstn = 1'b0;
            TxRstn = 1'b0;
            RxEn   = 1'b0;
            TxEn   = 1'b0;
            wait (Rstn);
            @(posedge Clk);
            @(posedge Clk);
            RxRstn = 1'b1;
            TxRstn = 1'b1;
            RxEn   = 1'b1;
            TxEn   = 1'b1;
        end
    end

    localparam integer TBYTE_NUM = 1;
    reg  [               31:0] pkt_gap;
    reg  [               31:0] pkt_len;
    reg  [               31:0] trans_len;
    reg  [(TBYTE_NUM*8-1) : 0] start_from;
    reg  [(TBYTE_NUM*8-1) : 0] inc;
    reg                        fix;
    reg                        stream_start;
    wire                       stream_busy;
    wire                       fifo_rd;
    wire                       fifo_empty;
    wire [(TBYTE_NUM*8-1) : 0] fifo_dout;

    fifo_master #(
        .TBYTE_NUM(TBYTE_NUM)
    ) fifo_master_dut (
        .clk         (Clk),
        .rstn        (Rstn),
        .pkt_gap     (pkt_gap),
        .pkt_len     (pkt_len),
        .trans_len   (trans_len),
        .start_from  (start_from),
        .inc         (inc),
        .fix         (fix),
        .stream_start(stream_start),
        .stream_busy (stream_busy),
        .fifo_rd     (fifo_rd),
        .fifo_empty  (fifo_empty),
        .fifo_dout   (fifo_dout)
    );

    assign fifo_rd     = TxInputReq;
    assign TxInputData = fifo_dout;
    assign TxEmpty     = fifo_empty;
    assign TxStart     = stream_start;


    initial begin
        begin
            pkt_gap      = 0;
            pkt_len      = 0;
            trans_len    = 0;
            start_from   = 0;
            inc          = 0;
            fix          = 1'b0;
            stream_start = 1'b0;
            wait (Rstn);
            wait (~stream_busy);

            pkt_gap    = 8;
            pkt_len    = 1;
            trans_len  = 128;
            start_from = 8'he0;
            inc        = 8'h01;
            fix        = 1'b0;
            #10;
            stream_start = 1'b1;
            #10;
            stream_start = 1'b0;
            #10;
            wait (~stream_busy);
            #40000;
            $finish;
        end
    end

    // ***********************************************************************************
    // clock block
    always #(TIMEPERIOD / 2) Clk = !Clk;

    // reset block
    initial begin
        begin
            Rstn = 1'b0;
            #(TIMEPERIOD * 2);
            Rstn = 1'b1;
        end
    end

    // record block
    initial begin
        begin
            $dumpfile("sim/test_tb.lxt");
            $dumpvars(0, HDLC_TOP_tb);
        end
    end
endmodule

// verilog_format: off
`resetall
// verilog_format: on
