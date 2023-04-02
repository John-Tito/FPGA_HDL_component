// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module stream2native #(
    parameter integer WIDTH = 16
) (
    input  wire                 clk,            //
    input  wire                 rstn,           //
    //
    input  wire                 fifo_full,      //
    output wire [      WIDTH:0] fifo_data,      //
    output wire                 fifo_wr,        //
    //
    output wire                 s_axis_tready,  //
    input  wire                 s_axis_tvalid,  //
    input  wire [  (WIDTH-1):0] s_axis_tdata,   //
    input  wire [(WIDTH/8-1):0] s_axis_tkeep,   //
    input  wire                 s_axis_tlast    //
);
    wire active;

    assign s_axis_tready = ~fifo_full;
    assign active        = s_axis_tvalid & s_axis_tready & (|s_axis_tkeep);
    assign fifo_wr       = active;
    assign fifo_data     = {s_axis_tlast, s_axis_tdata};

endmodule

// verilog_format: off
`resetall
// verilog_format: on
