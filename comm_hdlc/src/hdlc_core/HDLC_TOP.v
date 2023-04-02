// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module HDLC_TOP #(
    parameter integer CNT_WIDTH = 32,    // ovs counter width
    parameter         CPOL      = 1'b1,
    parameter         CPHA      = 1'b1
) (
    input  wire        Clk,            // clock
    //
    output wire        TxClk,          //
    output wire        STx,            // serial data output
    input  wire        RxClk,          //
    input  wire        SRx,            // serial data input
    //
    input  wire        TxEn,           // enable Tx path
    input  wire        TxRstn,         // reset Tx path,low active
    input  wire [ 7:0] TxInputData,    // data to be transferd
    output wire        TxInputReq,     // request to get new data
    input  wire        TxEmpty,        // No more Data to transfer
    input  wire        TxStart,        // Start the transfer
    input  wire        TxAbort,        // Abort the transfer
    output wire        TxBusy,         // Transfer is in progress
    output wire        TxFlag,         //
    //
    input  wire        RxEn,           // enable Rx path
    input  wire        RxRstn,         // reset Rx path,low active
    output wire [ 8:0] RxOutputData,   //
    output wire        RxOutputValid,  //
    output wire        RxBusy,         //
    output wire        RxStart,        //
    output wire        RxAbort,        //
    output wire        RxEnd,          //
    output wire        RxError,        //
    output wire [31:0] RxByteLen,      //
    output wire [31:0] RxBitLen,       //
    //
    input  wire        RxKeepFlag,     //
    input  wire        BaudUpdate,     //
    input  wire [11:0] BaudFreq,       //
    input  wire [15:0] BaudLimit,      //
    input  wire        OVSEn,
    input  wire        Loopback        //
);
    wire SampleEn;
    wire SampleClr;
    reg  SRxMux = 1'b0;
    reg  RxClkMux = 1'b0;
    wire TxEnable;
    wire RxEnable;
    wire VoteRes;

    // ila_hdlc ila_hdlc_inst (
    //     .clk    (Clk),            // input wire clk
    //     .probe0 (TxStart),        // input wire [0:0]  probe0
    //     .probe1 (TxEmpty),        // input wire [0:0]  probe1
    //     .probe2 (TxInputReq),     // input wire [0:0]  probe2
    //     .probe3 (TxInputData),    // input wire [7:0]  probe3
    //     .probe4 (TxBusy),         // input wire [0:0]  probe4
    //     .probe5 (TxFlag),         // input wire [0:0]  probe5
    //     .probe6 (RxOutputData),   // input wire [8:0]  probe6
    //     .probe7 (RxOutputValid),  // input wire [0:0]  probe7
    //     .probe8 (RxBusy),         // input wire [0:0]  probe8
    //     .probe9 (RxStart),        // input wire [0:0]  probe9
    //     .probe10(RxAbort),        // input wire [0:0]  probe10
    //     .probe11(RxEnd),          // input wire [0:0]  probe11
    //     .probe12(RxError),        // input wire [0:0]  probe12
    //     .probe13(RxByteLen),      // input wire [31:0]  probe13
    //     .probe14(RxBitLen),       // input wire [31:0]  probe14
    //     .probe15(SampleEn),       // input wire [0:0]  probe15
    //     .probe16(SampleClr),      // input wire [0:0]  probe16
    //     .probe17(SRxMux),         // input wire [0:0]  probe17
    //     .probe18(RxClkMux),       // input wire [0:0]  probe18
    //     .probe19(TxEnable),       // input wire [0:0]  probe19
    //     .probe20(RxEnable),       // input wire [0:0]  probe20
    //     .probe21(VoteRes)         // input wire [0:0]  probe21
    // );

    hdlc_tx_clk_gen #(
        .CPOL(CPOL),
        .CPHA(CPHA)
    ) hdlc_tx_clk_gen_inst (
        .clk       (Clk),
        .rstn      (TxRstn),
        .en        (TxEn),
        .load      (BaudUpdate),
        .baud_freq (BaudFreq),
        .baud_limit(BaudLimit),
        .shift_en  (TxEnable),
        .sync_clk  (TxClk)
    );

    HDLC_TRANSMIT HDLC_TRANSMIT_inst (
        .Rstn       (TxRstn),
        .Clk        (Clk),
        .STX        (STx),
        .TxInputData(TxInputData),
        .TxInputReq (TxInputReq),
        .TxEmpty    (TxEmpty),
        .TxStart    (TxStart),
        .TxAbort    (TxAbort),
        .TxEnable   (TxEnable),
        .TxBusy     (TxBusy),
        .TxFlag     (TxFlag)
    );

    hdlc_rx_clk_gen #(
        .CPOL(CPOL),
        .CPHA(CPHA)
    ) hdlc_rx_clk_gen_inst (
        .clk         (Clk),
        .rstn        (RxRstn),
        .en          (RxEn),
        .load        (BaudUpdate),
        .baud_freq   (BaudFreq),
        .baud_limit  (BaudLimit),
        .sync_mode   (1'b1),
        .sample_en   (SampleEn),
        .sample_clr  (SampleClr),
        .ext_sync_clk(RxClkMux)
    );

    hdlc_rx_ovs #(
        .CNT_WIDTH(CNT_WIDTH)
    ) hdlc_rx_ovs_inst (
        .clk       (Clk),
        .rstn      (RxRstn),
        .en        (RxEn),
        .ovs_en    (OVSEn),
        .rxd       (SRxMux),
        .sample_clr(SampleClr),
        .sample_en (SampleEn),
        .vote_res  (VoteRes),
        .vote_valid(RxEnable)
    );

    HDLC_RECEIVE HDLC_RECEIVE_inst (
        .Clk           (Clk),
        .Rstn          (RxRstn),
        .RxEnable      (RxEnable),
        .KeepFlag      (RxKeepFlag),
        .SRX           (VoteRes),
        .PData         (RxOutputData),
        .PDataValid    (RxOutputValid),
        .FrameReceiving(RxBusy),
        .FrameStart    (RxStart),
        .FrameAbort    (RxAbort),
        .FrameEnd      (RxEnd),
        .FrameError    (RxError),
        .FrameByteLen  (RxByteLen),
        .FrameBitLen   (RxBitLen)
    );

    always @(posedge Clk) begin
        if (!RxRstn) begin
            SRxMux   <= 1'b1;
            RxClkMux <= CPOL;
        end else begin
            SRxMux   <= Loopback ? STx : SRx;
            RxClkMux <= Loopback ? TxClk : RxClk;
        end
    end
endmodule

// verilog_format: off
`resetall
// verilog_format: on
