// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module axis_checker #(
    parameter integer DATA_WIDTH = 64
) (
    input  wire                        s_axis_aclk,
    input  wire                        s_axis_aresetn,
    input  wire                        s_axis_tvalid,
    input  wire [  (DATA_WIDTH-1) : 0] s_axis_tdata,
    input  wire [(DATA_WIDTH/8-1) : 0] s_axis_tstrb,
    input  wire                        s_axis_tlast,
    output reg                         s_axis_tready
);

    reg [31:0] cnt = 0;
    wire active = s_axis_tready & s_axis_tvalid;

    always @(posedge s_axis_aclk) begin
        if (!s_axis_aresetn) begin
            s_axis_tready <= 1'b0;
        end else begin
            s_axis_tready <= 1'b1;
        end
    end

    always @(posedge s_axis_aclk) begin
        if (!s_axis_aresetn || (active & s_axis_tlast)) begin
            cnt <= 0;
        end else if (active) begin
            cnt <= cnt + 1;
        end
    end

    always @(posedge s_axis_aclk) begin
        if (active & s_axis_tlast) begin
            $display("frame length,%d", cnt + 1);
        end else begin
            ;
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
