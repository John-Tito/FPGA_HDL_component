// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module hdlc_rx_ovs #(
    parameter CNT_WIDTH = 32  // ovs counter width
) (
    input  wire clk,         // clock
    input  wire rstn,        // active low reset
    input  wire en,          //
    input  wire ovs_en,      //
    input  wire rxd,         //
    input  wire sample_clr,  //
    input  wire sample_en,   //
    output reg  vote_res,    //
    output reg  vote_valid   //
);

    reg [(CNT_WIDTH-1):0] vote_cnt;
    reg [(CNT_WIDTH-1):0] clk_cnt;
    reg [(CNT_WIDTH-1):0] clk_cnt_latch;

    // 时钟周期计数
    always @(posedge clk) begin
        if (!rstn || !en) begin
            clk_cnt <= 0;
        end else begin
            if (sample_en) begin
                clk_cnt <= 0;
            end else begin
                clk_cnt = clk_cnt + 1;
            end
        end
    end

    // 时钟周期锁存
    always @(posedge clk) begin
        if (!rstn || !en) begin
            clk_cnt_latch <= 0;
        end else begin
            if (sample_en) begin
                clk_cnt_latch <= clk_cnt;
            end
        end
    end

    // 数据状态计数
    always @(posedge clk) begin
        if (!rstn || !en) begin
            vote_cnt <= 0;
        end else begin
            if (sample_clr) begin
                vote_cnt <= 0;
            end else begin
                if (rxd) begin
                    if (vote_cnt < 32'hffffffff) vote_cnt = vote_cnt + 1;
                end else begin
                    if (vote_cnt > 32'h0) vote_cnt = vote_cnt - 1;
                end
            end
        end
    end

    // 数据状态表决判定
    always @(posedge clk) begin
        if (!rstn || !en) begin
            vote_res <= 1'b1;
        end else begin
            if (sample_en) begin
                if (ovs_en) begin
                    if (vote_cnt > clk_cnt_latch[(CNT_WIDTH-1):2]) vote_res <= 1'b1;
                    else vote_res <= 1'b0;
                end else begin
                    vote_res <= rxd;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn || !en) begin
            vote_valid <= 1'b0;
        end else begin
            vote_valid <= sample_en;
        end
    end
endmodule

// verilog_format: off
`resetall
// verilog_format: on
