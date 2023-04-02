// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module uart_top_tb;

    // Ports
    wire        clock;
    wire        reset;
    reg         ser_in = 0;
    wire        ser_out;
    reg  [ 7:0] tx_data = 0;
    reg         tx_new_data = 0;
    wire        tx_busy;
    wire [ 7:0] rx_data;
    wire        rx_new_data;
    wire        rx_busy;
    reg         loopback = 1'b1;
    reg  [11:0] baud_freq = 12'd4;
    reg  [15:0] baud_limit = 12'd1;
    wire        baud_clk;
    reg  [ 3:0] recv_parity = 4'b1111;
    wire        parity_error;

    uart_top dut (
        .clock          (clock),
        .reset          (reset),
        .loopback       (loopback),
        .baud_freq      (baud_freq),
        .baud_limit     (baud_limit),
        .baud_clk       (baud_clk),
        .recv_parity    (recv_parity),
        .tx_data        (tx_data),
        .tx_new_data    (tx_new_data),
        .tx_busy        (tx_busy),
        .rx_data        (rx_data),
        .rx_new_data    (rx_new_data),
        .rx_parity_error(),
        .rx_begin_error (),
        .rx_end_error   (),
        .rx_busy        (rx_busy),
        .ser_in         (ser_in),
        .ser_out        (ser_out)
    );


    reg [7:0] ii;
    initial begin
        begin
            wait (!reset);
            for (ii = 0; ii < 16; ii = ii + 1) begin
                @(posedge clock);
                tx_new_data <= 1'b1;
                tx_data     <= ii;
                @(posedge clock);
                tx_new_data <= 1'b0;
                tx_data     <= ii;
                @(posedge clock);
                wait (!tx_busy);
            end
            #40000;
            $finish;
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
        .clk (clock),
        .rstn(),
        .rst (reset)
    );

endmodule
