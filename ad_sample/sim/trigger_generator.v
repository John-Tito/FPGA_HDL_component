// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module trigger_generator #(
    parameter integer CHANNEL_NUM = 4,
    parameter integer BIT_NUM = 16
) (
    input  wire                             clk,          //
    input  wire                             rstn,         //
    input  wire [        (CHANNEL_NUM-1):0] trig_mask,    //
    input  wire [           (BIT_NUM -1):0] trig_level,   //
    input  wire [(BIT_NUM*CHANNEL_NUM-1):0] idata,        //
    input  wire                             idata_valid,  //
    output reg  [(BIT_NUM*CHANNEL_NUM-1):0] odata,        //
    output reg                              odata_valid,  //
    output reg                              trig          //
);

    reg [(CHANNEL_NUM-1):0] trig_channle;

    always @(posedge clk) begin
        if (!rstn) begin
            odata       <= 0;
            odata_valid <= 1'b0;
        end else begin
            odata       <= idata;
            odata_valid <= idata_valid;
        end
    end

    genvar ii;
    generate
        for (ii = 0; ii < CHANNEL_NUM; ii = ii + 1) begin
            always @(posedge clk) begin
                if (!rstn) begin
                    trig_channle[ii] <= 1'b0;
                end else if ((idata[(ii*BIT_NUM)+:BIT_NUM] == trig_level)) begin
                    trig_channle[ii] <= 1'b1;
                end else begin
                    trig_channle[ii] <= 1'b0;
                end
            end
        end
    endgenerate

    assign trig = |(trig_channle & trig_mask);

endmodule

// verilog_format: off
`resetall
// verilog_format: on
