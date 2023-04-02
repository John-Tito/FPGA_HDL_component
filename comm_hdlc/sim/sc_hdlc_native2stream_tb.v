// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module sc_hdlc_native2stream_tb;

    // Parameters
    localparam real TIMEPERIOD = 5;

    // Ports
    reg         clk = 0;
    reg         rstn = 0;
    reg  [ 4:0] tdest = 0;
    reg  [ 7:0] s_axis_tdata = 0;
    reg         s_axis_tvalid = 0;
    wire        s_axis_tready;
    reg         s_axis_tlast = 0;
    reg         s_axis_tkeep = 0;
    reg  [ 4:0] s_axis_tid = 0;
    reg  [ 4:0] s_axis_tdest = 0;
    reg  [ 0:0] s_axis_tuser = 0;
    wire [ 7:0] m_axis_tdata;
    wire        m_axis_tvalid;
    reg         m_axis_tready = 0;
    wire        m_axis_tlast;
    wire        m_axis_tkeep;
    wire [ 4:0] m_axis_tid;
    wire [ 4:0] m_axis_tdest;
    wire [ 0:0] m_axis_tuser;
    wire        tx_rstn;
    reg         tx_input_req = 0;
    reg         tx_busy = 0;
    reg         tx_flag = 0;
    wire        tx_start;
    wire        tx_empty;
    wire [ 7:0] tx_data;
    wire        rx_rstn;
    reg         rx_end = 0;
    reg         rx_abort = 0;
    reg         rx_error = 0;
    reg  [ 7:0] rx_data = 0;
    reg         rx_dvalid = 0;
    wire [31:0] pkt_length;
    wire        pkt_length_push;

    sc_hdlc_native2stream sc_hdlc_native2stream_dut (
        .clk            (clk),
        .tdest          (tdest),
        .s_axis_tdata   (s_axis_tdata),
        .s_axis_tvalid  (s_axis_tvalid),
        .s_axis_tready  (s_axis_tready),
        .s_axis_tlast   (s_axis_tlast),
        .s_axis_tkeep   (s_axis_tkeep),
        .s_axis_tid     (s_axis_tid),
        .s_axis_tdest   (s_axis_tdest),
        .s_axis_tuser   (s_axis_tuser),
        .m_axis_tdata   (m_axis_tdata),
        .m_axis_tvalid  (m_axis_tvalid),
        .m_axis_tready  (m_axis_tready),
        .m_axis_tlast   (m_axis_tlast),
        .m_axis_tkeep   (m_axis_tkeep),
        .m_axis_tid     (m_axis_tid),
        .m_axis_tdest   (m_axis_tdest),
        .m_axis_tuser   (m_axis_tuser),
        .tx_rstn        (tx_rstn),
        .tx_input_req   (tx_input_req),
        .tx_busy        (tx_busy),
        .tx_flag        (tx_flag),
        .tx_start       (tx_start),
        .tx_empty       (tx_empty),
        .tx_data        (tx_data),
        .rx_rstn        (rx_rstn),
        .rx_end         (rx_end),
        .rx_abort       (rx_abort),
        .rx_error       (rx_error),
        .rx_data        (rx_data),
        .rx_dvalid      (rx_dvalid),
        .pkt_length     (pkt_length),
        .pkt_length_push(pkt_length_push)
    );

    initial begin
        begin
            #2000;
            $finish;
        end
    end

    assign tx_rstn = rstn;
    assign rx_rstn = rstn;

    // ***********************************************************************************
    // clock block
    always #(TIMEPERIOD / 2) clk = !clk;

    // reset block
    initial begin
        begin
            rstn = 1'b0;
            #(TIMEPERIOD * 2);
            rstn = 1'b1;
        end
    end

    // record block
    initial begin
        begin
            $dumpfile("sim/test_tb.lxt");
            $dumpvars(0, sc_hdlc_native2stream_tb);
        end
    end
endmodule
