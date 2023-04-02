// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module HDLC_RX_ZREO_DELETE (
    input  wire Clk,   // clock
    input  wire Rstn,  // low active reset
    input  wire En,    // high active enable
    input  wire SRX,   // serial rx data
    output reg  Valid  // SRXD is valid
);

    reg [5:0] data_shift_reg;  // shift register value latched
    wire [5:0] next_value;

    always @(posedge Clk) begin
        if (!Rstn) begin
            data_shift_reg <= 6'h00;
        end else if (En) begin
            data_shift_reg <= next_value;
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            Valid <= 1'b0;
        end else if (En) begin
            Valid <= (6'b011111 != next_value) ? 1'b1 : 1'b0;
        end else begin
            Valid <= 1'b1;
        end
    end

    assign next_value = {SRX, data_shift_reg[5:1]};
endmodule

// verilog_format: off
`resetall
// verilog_format: on
