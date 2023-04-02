// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module clock_rst #(
    parameter real TIMEPERIOD = 10
) (
    output reg clk = 1'b0,   //
    output reg rstn = 1'b0,  //
    output reg rst = 1'b1    //
);

    // ***********************************************************************************
    // clock block
    always #(TIMEPERIOD / 2) clk = !clk;

    reg [7:0] ii;
    // reset block
    initial begin
        begin
            rstn = 1'b0;
            rst  = 1'b1;
            for (ii = 0; ii < 32; ii = ii + 1) begin
                @(posedge clk);
                @(posedge clk);
            end
            rstn = 1'b1;
            rst  = 1'b0;
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
