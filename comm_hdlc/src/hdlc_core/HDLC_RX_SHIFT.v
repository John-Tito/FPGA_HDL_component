// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module HDLC_RX_SHIFT #(
    parameter integer WIDTH = 8
) (
    input  wire               Clk,        // clock
    input  wire               Rstn,       // low active reset
    input  wire               Clr,        // high active
    input  wire               En,         // enable shift
    input  wire               SData,      // serial data input
    output wire [(WIDTH-1):0] PData,      // parallel data output
    output wire               PDataValid  // parallel data valid
);

    reg               done;
    reg [(WIDTH-1):0] shift_reg;
    reg [(WIDTH-1):0] cnt;

    always @(posedge Clk) begin
        if ((!Rstn) || Clr) begin
            shift_reg <= 8'h00;
        end else if (En) begin
            shift_reg <= {SData, shift_reg[(WIDTH-1):1]};
        end
    end

    always @(posedge Clk) begin
        if ((!Rstn) || Clr) begin
            cnt <= 0;
        end else if (En) begin
            if (cnt >= WIDTH) begin
                cnt <= 1;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

    always @(posedge Clk) begin
        if ((!Rstn) || Clr) begin
            done <= 1'b0;
        end else if (En && ((WIDTH - 1) == cnt)) begin
            done <= 1'b1;
        end else done <= 1'b0;
    end

    assign PDataValid = done;
    assign PData      = shift_reg;
endmodule

// verilog_format: off
`resetall
// verilog_format: on
