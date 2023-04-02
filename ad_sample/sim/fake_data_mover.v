// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module fake_data_mover #(
    parameter integer MM_ADDR_WIDTH = 32,
    parameter integer BIT_WIDTH = 128
) (
    input  wire                          clk,
    input  wire                          rstn,
    output reg                           cmd_tready,
    input  wire                          cmd_tvalid,
    input  wire [(MM_ADDR_WIDTH+39) : 0] cmd_tdata,
    //
    output reg                           sts_err,
    output reg                           sts_tvalid,
    output reg  [                 7 : 0] sts_tdata,
    output reg  [                 0 : 0] sts_tkeep,
    output reg                           sts_tlast,
    input  wire                          sts_tready,

    input  wire [  (BIT_WIDTH-1):0] s_axis_tdata,
    input  wire [(BIT_WIDTH/8-1):0] s_axis_tkeep,
    input  wire                     s_axis_tlast,
    input  wire                     s_axis_tvalid,
    output reg                      s_axis_tready
);
    wire cmd_active = cmd_tvalid & cmd_tready;
    wire data_active = s_axis_tvalid & s_axis_tready;
    wire sts_active = sts_tvalid & sts_tready;

    reg [MM_ADDR_WIDTH:0] wait_cnt;
    reg wait_respond;
    wire respond;

    reg [22:0] cmd_latch;
    always @(posedge clk) begin
        if (!rstn) begin
            cmd_latch <= 0;
        end else begin
            if (cmd_active) begin
                cmd_latch <= cmd_tdata[22:0];
            end else if (sts_active) begin
                cmd_latch <= 0;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn || cmd_active || sts_active) begin
            wait_cnt <= 0;
        end else begin
            if (wait_respond && data_active) begin
                wait_cnt <= wait_cnt + 1;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            s_axis_tready <= 1'b0;
        end else begin
            if (wait_respond) begin
                s_axis_tready <= respond;
            end
        end
    end

    assign respond = wait_cnt < cmd_latch - 1;

    always @(posedge clk) begin
        if (!rstn) begin
            wait_respond <= 1'b0;
        end else begin
            if (cmd_active && cmd_tdata[22:0] > 0) begin
                wait_respond <= 1'b1;
            end else if (sts_active) begin
                wait_respond <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            cmd_tready <= 1'b0;
        end else begin
            if (wait_respond) begin
                cmd_tready <= 1'b0;
            end else begin
                cmd_tready <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            sts_err    <= 1'b0;
            sts_tvalid <= 1'b0;
            sts_tdata  <= 0;
            sts_tkeep  <= 1'b0;
            sts_tlast  <= 1'b0;
        end else begin
            if (!respond) begin
                sts_err    <= 1'b0;
                sts_tvalid <= 1'b1;
                sts_tdata  <= 8'h80;
                sts_tkeep  <= 1'b1;
                sts_tlast  <= 1'b1;
            end else begin
                sts_err    <= 1'b0;
                sts_tvalid <= 1'b0;
                sts_tdata  <= 0;
                sts_tkeep  <= 1'b0;
                sts_tlast  <= 1'b0;
            end
        end
    end


endmodule

// verilog_format: off
`resetall
// verilog_format: on
