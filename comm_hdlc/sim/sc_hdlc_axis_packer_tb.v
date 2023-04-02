
// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on
module sc_hdlc_axis_packer_tb;

    // Parameters
    localparam real TIMEPERIOD = 10;

    // Ports
    reg         clk = 0;
    reg         rstn = 0;
    reg         upload_req = 0;
    reg  [31:0] upload_length = 0;
    wire        upload_busy;
    wire        upload_done;
    wire        skip_arb;
    wire        m_axis_tvalid;
    wire        m_axis_tready;
    wire        m_axis_tready1;
    wire        m_axis_tlast;

    sc_hdlc_axis_packer sc_hdlc_axis_packer_dut (
        .clk           (clk),
        .rstn          (rstn),
        .upload_req    (upload_req),
        // .upload_length (upload_length),
        .upload_busy   (upload_busy),
        .upload_done   (upload_done),
        .skip_arb      (skip_arb),
        .m_axis_tvalid (m_axis_tvalid),
        .m_axis_tready (m_axis_tready),
        .m_axis_tready1(m_axis_tready1),
        .m_axis_tlast  (m_axis_tlast)
    );

    localparam TBYTE_NUM = 16;
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
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready1),
        .m_axis_tdata (),
        .m_axis_tkeep (),
        .m_axis_tlast (m_axis_tlast),
        .m_axis_tid   (),
        .m_axis_tdest ()
    );

    assign m_axis_tready = 1'b1;
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
            pkt_gap    = 8;
            pkt_len    = 1;
            trans_len  = 4;
            start_from = 128'h100F0E0D0C0B0A090807060504030201;
            inc        = 128'h10101010101010101010101010101010;
            fix        = 1'b0;
            #10;
            stream_start = 1'b1;
            #10;
            stream_start = 1'b0;
            #10;
            wait (~stream_busy);

            #3000;
            $finish;
        end
    end

    initial begin
        begin
            upload_length = 0;
            upload_req    = 1'b0;
            wait (rstn);
            #100;
            upload_length = 16;
            upload_req    = 1'b1;
            #10;
            upload_req = 1'b0;
            #3000;
        end
    end

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
            $dumpvars(0, sc_hdlc_axis_packer_tb);
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
