// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module ad574_sample (
    input  wire       clk,     //
    input  wire       rstn,    //
    //
    input  wire       busy,
    output reg        op_req,  // op request
    output reg        op,      // operate , 0:read, 1:write
    output reg  [1:0] addr     //
);

    always @(posedge clk) begin
        if (!rstn) begin
            op_req <= 1'b0;
            op     <= 1'b0;
            addr   <= 2'b11;
        end else begin
            if (!busy && !op_req) begin
                op_req <= 1'b1;
                if (op) begin
                    op   <= 1'b0;
                    addr <= 2'b10;
                end else begin
                    op   <= 1'b1;
                    addr <= 2'b10;
                end
            end else begin
                op_req <= 1'b0;
                op     <= op;
                addr   <= addr;
            end
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
