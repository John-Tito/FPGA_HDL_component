// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module HDLC_RX_FLAG_CHECKER (
    input  wire Clk,    // clock
    input  wire Rstn,   // low active reset
    input  wire En,     // high active enable
    input  wire SRX,    // serial rx data
    output wire SRXD,   // delay verision of SRX
    output reg  FFlag,  // frame start and end flag
    output reg  EFlag   // frame error flag
);

    localparam HEAD_FLAG = 8'h7E;  // the F flag
    wire [7:0] next_value;  // shift register value ahead of time
    reg  [7:0] data_shift_reg;  // shift register value latched

    always @(posedge Clk) begin
        if (!Rstn) begin
            FFlag <= 1'b0;
        end else if (En) begin
            //asserted when F flag was found
            FFlag <= (HEAD_FLAG == next_value) ? 1'b1 : 1'b0;
        end else begin
            FFlag <= 1'b0;
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            EFlag <= 1'b0;
        end else if (En) begin
            //asserted when 8'hFE or 8'hFF or 8'h7F was found
            EFlag <= ((6'h3f == next_value[6:1]) && (next_value[0] || next_value[7])) ? 1'b1 : 1'b0;
        end else begin
            EFlag <= 1'b0;
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            data_shift_reg <= 8'h00;
        end else if (En) begin
            data_shift_reg <= next_value;
        end
    end

    assign next_value = {SRX, data_shift_reg[7:1]};
    assign SRXD       = data_shift_reg[0];

endmodule

// verilog_format: off
`resetall
// verilog_format: on
