// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module ad574_top #(
    parameter integer IN_CLK_FREQ = 100_000_000
) (
    input  wire        clk,         //
    input  wire        rstn,        //
    //
    output wire [11:0] data,
    output wire        data_valid,
    // to ad574
    output wire        AO,          //
    output wire        S12_8n,      //
    output wire        CE,          //
    output wire        RCn,         //
    input  wire        STS,         //
    input  wire [11:0] DB           //
);

    wire       busy;
    wire       op_req;
    wire       op;
    wire [1:0] addr;

    ad574_ila ad574_ila_inst (
        .clk   (clk),           // input wire clk
        .probe0({S12_8n, AO}),  // input wire [1:0]  probe0
        .probe1(CE),            // input wire [0:0]  probe1
        .probe2(RCn),           // input wire [0:0]  probe2
        .probe3(STS),           // input wire [0:0]  probe3
        .probe4(DB)             // input wire [11:0]  probe4
    );

    ad574_sample ad574_sample_dut (
        .clk   (clk),
        .rstn  (rstn),
        .busy  (busy),
        .op_req(op_req),
        .op    (op),
        .addr  (addr)
    );

    ad574_timing #(
        .IN_CLK_FREQ(IN_CLK_FREQ)
    ) ad574_timing_dut (
        .clk       (clk),
        .rstn      (rstn),
        .op_req    (op_req),
        .op        (op),
        .addr      (addr),
        .busy      (busy),
        .data      (data),
        .data_valid(data_valid),
        .AO        (AO),
        .S12_8n    (S12_8n),
        .CE        (CE),
        .RCn       (RCn),
        .STS       (STS),
        .DB        (DB)
    );

endmodule

// verilog_format: off
`resetall
// verilog_format: on
