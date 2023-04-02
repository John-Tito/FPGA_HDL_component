// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module adc_data_generator #(
    parameter integer DIV = 4,
    parameter integer CHANNEL_NUM = 4,
    parameter integer ADC_BIT_NUM = 10,
    parameter integer OUTPUT_BIT_NUM = 16
) (
    input  wire                                    clk,        //
    input  wire                                    rstn,       //
    output wire [(OUTPUT_BIT_NUM*CHANNEL_NUM-1):0] data,       //
    output reg                                     data_valid  //
);

    reg [(ADC_BIT_NUM-1):0] adc_raw_data[0:(CHANNEL_NUM-1)];
    reg [7:0] cnt;
    wire update;

    genvar ii;
    generate
        for (ii = 0; ii < CHANNEL_NUM; ii = ii + 1) begin : g_mux
            assign data[(ii*OUTPUT_BIT_NUM)+:OUTPUT_BIT_NUM] = adc_raw_data[ii];

            always @(posedge clk) begin
                if (!rstn) begin
                    data_valid       <= 1'b0;
                    adc_raw_data[ii] <= 0;
                end else begin
                    if (update) begin
                        adc_raw_data[ii] <= adc_raw_data[ii] + 1;
                    end
                    data_valid <= update;
                end
            end
        end
    endgenerate

    always @(posedge clk) begin
        if (!rstn) begin
            cnt <= 0;
        end else begin
            if (update) begin
                cnt <= 0;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

    assign update = (cnt >= DIV - 1) ? 1'b1 : 1'b0;

endmodule

// verilog_format: off
`resetall
// verilog_format: on
