// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on
module uart_wrapper_tb;

    // Parameters

    // Ports
    wire         clk;
    wire         rstn;
    reg          uart_rxd = 0;
    wire         uart_txd;
    reg  [  4:0] tdest;
    reg          app_axi_rreq = 0;
    wire         app_axi_rack;
    reg  [ 11:0] app_axi_raddr = 0;
    wire [ 31:0] app_axi_rdata;
    reg          app_axi_wreq = 0;
    wire         app_axi_wack;
    reg  [ 11:0] app_axi_waddr = 0;
    reg  [ 31:0] app_axi_wdata = 0;
    
    wire [  7:0] tx_axis_tdata;
    wire         tx_axis_tvalid;
    wire         tx_axis_tready;
    wire         tx_axis_tlast;
    wire         tx_axis_tkeep;
    wire [  4:0] tx_axis_tid;
    wire [  4:0] tx_axis_tdest;
    wire [0 : 0] tx_axis_tuser;

    wire [  7:0] rx_axis_tdata;
    wire         rx_axis_tvalid;
    wire         rx_axis_tready;
    wire         rx_axis_tlast;
    wire         rx_axis_tkeep;
    wire [  4:0] rx_axis_tid;
    wire [  4:0] rx_axis_tdest;
    wire [  0:0] rx_axis_tuser;

    wire         skip_arb;
    wire         pkt_valid;

    uart_wrapper dut (
        .clk          (clk),
        .rstn         (rstn),
        .uart_rxd     (uart_rxd),
        .uart_txd     (uart_txd),
        .tdest        (tdest),
        .app_axi_rreq (app_axi_rreq),
        .app_axi_rack (app_axi_rack),
        .app_axi_raddr(app_axi_raddr),
        .app_axi_rdata(app_axi_rdata),
        .app_axi_wreq (app_axi_wreq),
        .app_axi_wack (app_axi_wack),
        .app_axi_waddr(app_axi_waddr),
        .app_axi_wdata(app_axi_wdata),
        .s_axis_tdata (tx_axis_tdata),
        .s_axis_tvalid(tx_axis_tvalid),
        .s_axis_tready(tx_axis_tready),
        .s_axis_tlast (tx_axis_tlast),
        .s_axis_tkeep (tx_axis_tkeep),
        .s_axis_tid   (tx_axis_tid),
        .s_axis_tdest (tx_axis_tdest),
        .s_axis_tuser (tx_axis_tuser),
        .m_axis_tdata (rx_axis_tdata),
        .m_axis_tvalid(rx_axis_tvalid),
        .m_axis_tready(rx_axis_tready),
        .m_axis_tlast (rx_axis_tlast),
        .m_axis_tkeep (rx_axis_tkeep),
        .m_axis_tid   (rx_axis_tid),
        .m_axis_tdest (rx_axis_tdest),
        .m_axis_tuser (rx_axis_tuser),
        .skip_arb     (skip_arb),
        .pkt_valid    (pkt_valid)
    );

    localparam TBYTE_NUM = 1;
    reg  [              4 : 0] pkt_dest;
    reg  [               31:0] pkt_gap;
    reg  [               31:0] pkt_len;
    reg  [               31:0] trans_len;
    reg  [(TBYTE_NUM*8-1) : 0] start_from;
    reg  [(TBYTE_NUM*8-1) : 0] inc;
    reg                        fix;
    reg                        stream_start;
    wire                       stream_busy;

    stream_master #(
        .TBYTE_NUM(TBYTE_NUM)
    ) stream_master_dut (
        .clk          (clk),
        .rstn         (rstn),
        .pkt_dest     (pkt_dest),
        .pkt_gap      (pkt_gap),
        .pkt_len      (pkt_len),
        .trans_len    (trans_len),
        .start_from   (start_from),
        .inc          (inc),
        .fix          (fix),
        .stream_start (stream_start),
        .stream_busy  (stream_busy),
        .m_axis_tvalid(tx_axis_tvalid),
        .m_axis_tready(tx_axis_tready),
        .m_axis_tdata (tx_axis_tdata),
        .m_axis_tkeep (tx_axis_tkeep),
        .m_axis_tlast (tx_axis_tlast),
        .m_axis_tid   (tx_axis_tid),
        .m_axis_tdest (tx_axis_tdest)
    );

    assign rx_axis_tready = 1'b1;
    initial begin
        begin
            pkt_dest     = 0;
            pkt_gap      = 0;
            pkt_len      = 0;
            trans_len    = 0;
            start_from   = 0;
            inc          = 0;
            fix          = 1'b0;
            stream_start = 1'b0;
            wait (rstn);
            wait (~stream_busy);

            pkt_dest   = 0;
            pkt_gap    = 50000;
            pkt_len    = 10;
            trans_len  = 10;
            start_from = 8'h01;
            inc        = 8'h01;
            fix        = 1'b0;
            #10;
            stream_start = 1'b1;
            #10;
            stream_start = 1'b0;
            #10;
            wait (~stream_busy);

            #30000;
            $finish;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            uart_rxd <= 1'b1;
        end else begin
            uart_rxd <= uart_txd;
        end
    end

    // record block
    initial begin
        begin
            $dumpfile("sim/test_tb.lxt");
            $dumpvars(0, dut);
        end
    end

    clock_rst #(
        .TIMEPERIOD(10)
    ) clock_rst_dut (
        .clk (clk),
        .rstn(rstn),
        .rst ()
    );

endmodule

// verilog_format: off
`resetall
// verilog_format: on
