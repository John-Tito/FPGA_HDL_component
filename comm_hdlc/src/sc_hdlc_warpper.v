
// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module sc_hdlc_warpper #(
    parameter integer CNT_WIDTH = 32,    // ovs counter width
    parameter         CPOL      = 1'b0,
    parameter         CPHA      = 1'b1
) (
    input wire clk,
    input wire rstn,

    output wire TxClk,
    output wire STx,
    input  wire RxClk,
    input  wire SRx,

    input wire [4:0] tdest,

    input  wire        app_axi_rreq,
    output wire        app_axi_rack,
    input  wire [11:0] app_axi_raddr,
    output wire [31:0] app_axi_rdata,

    input  wire        app_axi_wreq,
    output wire        app_axi_wack,
    input  wire [11:0] app_axi_waddr,
    input  wire [31:0] app_axi_wdata,

    input  wire [7:0] s_axis_tdata,
    input  wire       s_axis_tvalid,
    output wire       s_axis_tready,
    input  wire       s_axis_tlast,
    input  wire       s_axis_tkeep,
    input  wire [4:0] s_axis_tid,
    input  wire [4:0] s_axis_tdest,
    input  wire [0:0] s_axis_tuser,

    output wire [7:0] m_axis_tdata,
    output wire       m_axis_tvalid,
    input  wire       m_axis_tready,
    output wire       m_axis_tlast,
    output wire       m_axis_tkeep,
    output wire [4:0] m_axis_tid,
    output wire [4:0] m_axis_tdest,
    output wire [0:0] m_axis_tuser,
    output wire       skip_arb,       //
    output wire       pkt_valid       //
);

    wire         m_axis_tvalid1;
    wire         m_axis_tready1;
    //
    wire [  7:0] rx_axis_tdata;
    wire         rx_axis_tvalid;
    wire         rx_axis_tready;
    wire         rx_axis_tlast;
    wire         rx_axis_tkeep;
    wire [  4:0] rx_axis_tid;
    wire [  4:0] rx_axis_tdest;
    wire [0 : 0] rx_axis_tuser;

    wire [  7:0] tx_axis_tdata;
    wire         tx_axis_tvalid;
    wire         tx_axis_tready;
    wire         tx_axis_tlast;
    wire         tx_axis_tkeep;
    wire [  4:0] tx_axis_tid;
    wire [  4:0] tx_axis_tdest;
    wire [0 : 0] tx_axis_tuser;

    wire         keep_flag;
    wire         ovs_en;
    wire         baud_update;
    wire [ 11:0] baud_freq;
    wire [ 15:0] baud_limit;
    wire         loopback_en;

    wire         tx_start;
    wire         tx_empty;
    wire         tx_flag;
    wire [  7:0] tx_data;
    wire         tx_input_req;
    wire         rx_start;
    wire         rx_end;
    wire         rx_abort;
    wire         rx_error;
    wire [  7:0] rx_data;
    wire         rx_dvalid;

    wire         tx_en;
    wire         tx_rstn;
    wire         rx_en;
    wire         rx_rstn;
    wire         tx_busy;
    wire         rx_busy;
    wire [ 31:0] tx_cnt;
    wire [ 31:0] rx_cnt;

    wire         upload_req;
    wire         upload_busy;
    wire         upload_done;
    wire [ 31:0] upload_length;

    wire         pkt_length_push;
    wire [ 31:0] pkt_length;
    wire [ 31:0] pkt_cnt;

    wire         data_afull;  //
    wire         pkt_afull;  //


    HDLC_TOP #(
        .CNT_WIDTH(CNT_WIDTH),
        .CPOL(CPOL),
        .CPHA(CPHA)
    ) HDLC_TOP_inst (
        .Clk          (clk),
        .TxClk        (TxClk),
        .STx          (STx),
        .RxClk        (RxClk),
        .SRx          (SRx),
        .TxEn         (tx_en),
        .TxRstn       (tx_rstn),
        .TxInputData  (tx_data),
        .TxInputReq   (tx_input_req),
        .TxEmpty      (tx_empty),
        .TxStart      (tx_start),
        .TxAbort      (1'b0),
        .TxBusy       (tx_busy),
        .TxFlag       (tx_flag),
        .RxEn         (rx_en),
        .RxRstn       (rx_rstn),
        .RxOutputData (rx_data),
        .RxOutputValid(rx_dvalid),
        .RxBusy       (rx_busy),
        .RxStart      (rx_start),
        .RxAbort      (rx_abort),
        .RxEnd        (rx_end),
        .RxError      (rx_error),
        .RxByteLen    (),
        .RxBitLen     (),
        .RxKeepFlag   (keep_flag),
        .BaudUpdate   (baud_update),
        .BaudFreq     (baud_freq),
        .BaudLimit    (baud_limit),
        .OVSEn        (ovs_en),
        .Loopback     (loopback_en)
    );

    hdlc_axis_fifo tx_fifo (
        .s_axis_aresetn    (tx_rstn),         // input wire s_axis_aresetn
        .s_axis_aclk       (clk),             // input wire s_axis_aclk
        .s_axis_tvalid     (s_axis_tvalid),   // input wire s_axis_tvalid
        .s_axis_tready     (s_axis_tready),   // output wire s_axis_tready
        .s_axis_tdata      (s_axis_tdata),    // input wire [7 : 0] s_axis_tdata
        .s_axis_tkeep      (s_axis_tkeep),    // input wire [0 : 0] s_axis_tkeep
        .s_axis_tlast      (s_axis_tlast),    // input wire s_axis_tlast
        .s_axis_tid        (s_axis_tid),      // input wire [4 : 0] s_axis_tid
        .s_axis_tdest      (s_axis_tdest),    // input wire [4 : 0] s_axis_tdest
        .s_axis_tuser      (s_axis_tuser),    // input wire [0 : 0] s_axis_tuser
        .m_axis_tvalid     (tx_axis_tvalid),  // output wire m_axis_tvalid
        .m_axis_tready     (tx_axis_tready),  // input wire m_axis_tready
        .m_axis_tdata      (tx_axis_tdata),   // output wire [7 : 0] m_axis_tdata
        .m_axis_tkeep      (tx_axis_tkeep),   // output wire [0 : 0] m_axis_tkeep
        .m_axis_tlast      (tx_axis_tlast),   // output wire m_axis_tlast
        .m_axis_tid        (tx_axis_tid),     // output wire [4 : 0] m_axis_tid
        .m_axis_tdest      (tx_axis_tdest),   // output wire [4 : 0] m_axis_tdest
        .m_axis_tuser      (tx_axis_tuser),   // output wire [0 : 0] m_axis_tuser
        .axis_wr_data_count(tx_cnt),          // output wire [31 : 0] axis_wr_data_count
        .axis_rd_data_count(),                // output wire [31 : 0] axis_rd_data_count
        .prog_full         ()
    );

    sc_hdlc_native2stream sc_hdlc_native2stream_inst (
        .clk            (clk),
        .tdest          (tdest),
        .s_axis_tdata   (tx_axis_tdata),
        .s_axis_tvalid  (tx_axis_tvalid),
        .s_axis_tready  (tx_axis_tready),
        .s_axis_tlast   (tx_axis_tlast),
        .s_axis_tkeep   (tx_axis_tkeep),
        .s_axis_tid     (tx_axis_tid),
        .s_axis_tdest   (tx_axis_tdest),
        .s_axis_tuser   (tx_axis_tuser),
        .m_axis_tdata   (rx_axis_tdata),
        .m_axis_tvalid  (rx_axis_tvalid),
        .m_axis_tready  (rx_axis_tready),
        .m_axis_tlast   (rx_axis_tlast),
        .m_axis_tkeep   (rx_axis_tkeep),
        .m_axis_tid     (rx_axis_tid),
        .m_axis_tdest   (rx_axis_tdest),
        .m_axis_tuser   (rx_axis_tuser),
        .tx_rstn        (tx_rstn),
        .tx_start       (tx_start),
        .tx_empty       (tx_empty),
        .tx_busy        (tx_busy),
        .tx_flag        (tx_flag),
        .tx_input_req   (tx_input_req),
        .tx_data        (tx_data),
        .rx_rstn        (rx_rstn),
        .rx_dvalid      (rx_dvalid),
        .rx_data        (rx_data),
        .rx_start       (rx_start),
        .rx_error       (rx_error),
        .rx_end         (rx_end),
        .rx_abort       (rx_abort),
        .pkt_length     (pkt_length),
        .pkt_length_push(pkt_length_push),
        .data_afull     (data_afull),
        .pkt_afull      (pkt_afull)
    );

    hdlc_axis_fifo rx_fifo (
        .s_axis_aresetn    (rx_rstn),         // input wire s_axis_aresetn
        .s_axis_aclk       (clk),             // input wire s_axis_aclk
        .s_axis_tvalid     (rx_axis_tvalid),  // input wire s_axis_tvalid
        .s_axis_tready     (rx_axis_tready),  // output wire s_axis_tready
        .s_axis_tdata      (rx_axis_tdata),   // input wire [7 : 0] s_axis_tdata
        .s_axis_tkeep      (rx_axis_tkeep),   // input wire [0 : 0] s_axis_tkeep
        .s_axis_tlast      (rx_axis_tlast),   // input wire s_axis_tlast
        .s_axis_tid        (rx_axis_tid),     // input wire [4 : 0] s_axis_tid
        .s_axis_tdest      (rx_axis_tdest),   // input wire [4 : 0] s_axis_tdest
        .s_axis_tuser      (rx_axis_tuser),   // input wire [0 : 0] s_axis_tuser
        .m_axis_tvalid     (m_axis_tvalid1),  // output wire m_axis_tvalid
        .m_axis_tready     (m_axis_tready1),  // input wire m_axis_tready
        .m_axis_tdata      (m_axis_tdata),    // output wire [7 : 0] m_axis_tdata
        .m_axis_tkeep      (m_axis_tkeep),    // output wire [0 : 0] m_axis_tkeep
        .m_axis_tlast      (m_axis_tlast),    // output wire m_axis_tlast
        .m_axis_tid        (m_axis_tid),      // output wire [4 : 0] m_axis_tid
        .m_axis_tdest      (m_axis_tdest),    // output wire [4 : 0] m_axis_tdest
        .m_axis_tuser      (m_axis_tuser),    // output wire [0 : 0] m_axis_tuser
        .axis_wr_data_count(),                // output wire [31 : 0] axis_wr_data_count
        .axis_rd_data_count(rx_cnt),          // output wire [31 : 0] axis_rd_data_count
        .prog_full         (data_afull)
    );

    sc_hdlc_app_ui sc_hdlc_app_ui_inst (
        .clk          (clk),
        .rstn         (rstn),
        .app_axi_rreq (app_axi_rreq),
        .app_axi_rack (app_axi_rack),
        .app_axi_raddr(app_axi_raddr),
        .app_axi_rdata(app_axi_rdata),
        .app_axi_wreq (app_axi_wreq),
        .app_axi_wack (app_axi_wack),
        .app_axi_waddr(app_axi_waddr),
        .app_axi_wdata(app_axi_wdata),
        .tx_en        (tx_en),
        .tx_rstn      (tx_rstn),
        .rx_en        (rx_en),
        .rx_rstn      (rx_rstn),
        .baud_update  (baud_update),
        .baud_freq    (baud_freq),
        .baud_limit   (baud_limit),
        .loopback_en  (loopback_en),
        .keep_flag    (keep_flag),
        .ovs_en       (ovs_en),
        .tx_busy      (tx_busy),
        .rx_busy      (rx_busy),
        .tx_cnt       (tx_cnt),
        .rx_cnt       (rx_cnt),
        .upload_req   (upload_req),
        .pkt_length   (upload_length),
        .upload_busy  (upload_busy),
        .upload_done  (upload_done),
        .pkt_cnt      (pkt_cnt)
    );

    sc_hdlc_axis_packer sc_hdlc_axis_packer_inst (
        .clk           (clk),
        .rstn          (rx_rstn),
        .upload_req    (upload_req),
        .upload_busy   (upload_busy),
        .upload_done   (upload_done),
        .skip_arb      (skip_arb),
        .m_axis_tvalid (m_axis_tvalid1),
        .m_axis_tvalid1(m_axis_tvalid),
        .m_axis_tready (m_axis_tready),
        .m_axis_tready1(m_axis_tready1),
        .m_axis_tlast  (m_axis_tlast)
    );

    hdlc_pkt_info_fifo pkt_info_fifo_inst (
        .s_axis_aresetn    (rx_rstn),          // input wire s_axis_aresetn
        .s_axis_aclk       (clk),              // input wire s_axis_aclk
        .s_axis_tvalid     (pkt_length_push),  // input wire s_axis_tvalid
        .s_axis_tready     (),                 // output wire s_axis_tready
        .s_axis_tdata      (pkt_length),       // input wire [31 : 0] s_axis_tdata
        .m_axis_tvalid     (pkt_valid),        // output wire m_axis_tvalid
        .m_axis_tready     (upload_done),      // input wire m_axis_tready
        .m_axis_tdata      (upload_length),    // output wire [31 : 0] m_axis_tdata
        .axis_rd_data_count(pkt_cnt),
        .prog_full         (pkt_afull)
    );

    // axis_8_ila tx_inst (
    //     .clk   (clk),             // input wire clk
    //     .probe0(tx_axis_tready),  // input wire [0:0] probe0
    //     .probe1(tx_axis_tdata),   // input wire [7:0]  probe1
    //     .probe2(1'b0),            // input wire [0:0]  probe2
    //     .probe3(tx_axis_tvalid),  // input wire [0:0]  probe3
    //     .probe4(tx_axis_tlast),   // input wire [0:0]  probe4
    //     .probe5(tx_axis_tuser),   // input wire [0:0]  probe5
    //     .probe6(tx_axis_tkeep),   // input wire [0:0]  probe6
    //     .probe7(tx_axis_tdest),   // input wire [4:0]  probe7
    //     .probe8(tx_axis_tid)      // input wire [4:0]  probe8
    // );
    // axis_8_ila rx_inst (
    //     .clk   (clk),             // input wire clk
    //     .probe0(rx_axis_tready),  // input wire [0:0] probe0
    //     .probe1(rx_axis_tdata),   // input wire [7:0]  probe1
    //     .probe2(1'b0),            // input wire [0:0]  probe2
    //     .probe3(rx_axis_tvalid),  // input wire [0:0]  probe3
    //     .probe4(rx_axis_tlast),   // input wire [0:0]  probe4
    //     .probe5(rx_axis_tuser),   // input wire [0:0]  probe5
    //     .probe6(rx_axis_tkeep),   // input wire [0:0]  probe6
    //     .probe7(rx_axis_tdest),   // input wire [4:0]  probe7
    //     .probe8(rx_axis_tid)      // input wire [4:0]  probe8
    // );
endmodule

// verilog_format: off
`resetall
// verilog_format: on
