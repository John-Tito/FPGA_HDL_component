// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on
module watch_dog_tb;

    // Parameters
    localparam real TIMEPERIOD = 5;

    // Ports
    reg         clk = 0;
    reg         rstn = 0;
    reg         en = 0;
    reg         load = 0;
    reg  [31:0] preset = 0;
    reg         monitor_in = 0;
    wire        state;
    wire        active;
    wire        inactive;

    uart_watch_dog watch_dog_dut (
        .clk       (clk),
        .rstn      (rstn),
        .en        (en),
        .load      (load),
        .preset    (preset),
        .monitor_in(monitor_in),
        .state     (state),
        .active    (active),
        .inactive  (inactive)
    );

    initial begin
        begin

            monitor_in = 1'b0;
            wait (rstn);

            preset = 32'h000000ff;
            load   = 1'b1;
            #300;
            load = 1'b0;
            #300;
            monitor_in = 1'b1;
            #30;
            load = 1'b1;
            #300;
            load       = 1'b0;

            monitor_in = 1'b0;
            #40000;
            $finish;
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
            $dumpvars(0, watch_dog_tb);
        end
    end

endmodule
