// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module uart_wrapper (
    input wire clk,
    input wire rstn,

    input  wire uart_rxd,
    output wire uart_txd,

    input wire [4:0] tdest,

    input  wire        app_axi_rreq,
    output wire        app_axi_rack,
    input  wire [11:0] app_axi_raddr,
    output wire [31:0] app_axi_rdata,

    input  wire        app_axi_wreq,
    output wire        app_axi_wack,
    input  wire [11:0] app_axi_waddr,
    input  wire [31:0] app_axi_wdata,

    input  wire [  7:0] s_axis_tdata,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire         s_axis_tlast,
    input  wire         s_axis_tkeep,
    input  wire [  4:0] s_axis_tid,
    input  wire [  4:0] s_axis_tdest,
    input  wire [0 : 0] s_axis_tuser,

    output wire [7:0] m_axis_tdata,   //
    output wire       m_axis_tvalid,  //
    input  wire       m_axis_tready,  //
    output wire       m_axis_tlast,   //
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

    wire [ 11:0] baud_freq;
    wire [ 15:0] baud_limit;
    wire [ 03:0] recv_parity;
    wire         loopback_en;
    wire         wtd_en;
    wire [ 31:0] wtd_preset;

    wire [ 07:0] rx_data;
    wire         rx_dvalid;
    wire [ 07:0] tx_data;
    wire         tx_dvalid;

    wire         baud_clk;
    wire         parity_error;

    wire         rx_state;
    wire         rx_start;
    wire         rx_end;

    wire         tx_busy;  //
    wire         rx_busy;  //
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

    uart_top inst_uart_top (
        .clock(clk),
        .reset(~rstn),

        .loopback   (loopback_en),
        .baud_freq  (baud_freq),
        .baud_limit (baud_limit),
        .baud_clk   (baud_clk),
        .recv_parity(recv_parity),

        .tx_data    (tx_data),
        .tx_new_data(tx_dvalid),
        .tx_busy    (tx_busy),

        .rx_data        (rx_data),
        .rx_new_data    (rx_dvalid),
        .rx_parity_error(),
        .rx_begin_error (),
        .rx_end_error   (),
        .rx_busy        (rx_busy),

        .ser_in (uart_rxd),
        .ser_out(uart_txd)
    );

    uart_axis_fifo tx_fifo (
        .s_axis_aresetn    (rstn),            // input wire s_axis_aresetn
        .s_axis_aclk       (clk),             // input wire s_axis_aclk
        .s_axis_tvalid     (s_axis_tvalid),   // input wire s_axis_tvalid
        .s_axis_tready     (s_axis_tready),   // output wire s_axis_tready
        .s_axis_tdata      (s_axis_tdata),    // input wire [7 : 0] s_axis_tdata
        .s_axis_tkeep      (s_axis_tkeep),    // input wire [0 : 0] s_axis_tkeep
        .s_axis_tlast      (s_axis_tlast),    // input wire s_axis_tlast
        .s_axis_tid        (s_axis_tid),      // input wire [4 : 0] s_axis_tid
        .s_axis_tdest      (s_axis_tdest),    // input wire [4 : 0] s_axis_tdest
        .s_axis_tuser      (s_axis_tuser),    // input wire [0: 0] s_axis_tuser
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

    uart_native2stream uart_native2stream_inst (
        .clk            (clk),
        .rstn           (rstn),
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
        .tx_busy        (tx_busy),
        .tx_dvalid      (tx_dvalid),
        .tx_data        (tx_data),
        .rx_dvalid      (rx_dvalid),
        .rx_data        (rx_data),
        .rx_state       (rx_state),
        .rx_start       (rx_start),
        .rx_end         (rx_end),
        .pkt_length     (pkt_length),
        .pkt_length_push(pkt_length_push),
        .data_afull     (data_afull),
        .pkt_afull      (pkt_afull)
    );

    uart_axis_fifo rx_fifo (
        .s_axis_aresetn    (rstn),            // input wire s_axis_aresetn
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

    util_watch_dog util_watch_dog_inst (
        .clk       (clk),
        .rstn      (rstn),
        .en        (wtd_en),
        .preset    (wtd_preset),
        .monitor_in(rx_dvalid),
        .cnt_pulse (baud_clk),
        .state     (rx_state),
        .active    (rx_start),
        .inactive  (rx_end)
    );

    uart_app_ui uart_ui_inst (
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
        .loopback_en  (loopback_en),
        .wtd_en       (wtd_en),
        .baud_freq    (baud_freq),
        .baud_limit   (baud_limit),
        .recv_parity  (recv_parity),
        .wtd_preset   (wtd_preset),
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

    uart_axis_packer uart_axis_packer_inst (
        .clk           (clk),
        .rstn          (rstn),
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

    uart_pkt_info_fifo pkt_info_fifo_inst (
        .s_axis_aresetn    (rstn),             // input wire s_axis_aresetn
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

endmodule

`resetall
