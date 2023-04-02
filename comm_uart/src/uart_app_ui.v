// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module uart_app_ui (

    input wire clk,  //
    input wire rstn, //

    input  wire        app_axi_rreq,
    output reg         app_axi_rack,
    input  wire [11:0] app_axi_raddr,
    output reg  [31:0] app_axi_rdata,
    input  wire        app_axi_wreq,
    output reg         app_axi_wack,
    input  wire [11:0] app_axi_waddr,
    input  wire [31:0] app_axi_wdata,

    output reg            loopback_en,
    output reg            wtd_en,
    output reg [ (5-1):0] tdest,
    output reg [(12-1):0] baud_freq,
    output reg [(16-1):0] baud_limit,
    output reg [ (4-1):0] recv_parity,
    output reg [(32-1):0] wtd_preset,

    input wire            tx_busy,
    input wire            rx_busy,
    input wire [(32-1):0] tx_cnt,
    input wire [(32-1):0] rx_cnt,

    output reg         upload_req,
    input  wire        upload_busy,  //
    input  wire        upload_done,
    input  wire [31:0] pkt_length,
    input  wire [31:0] pkt_cnt
);

    reg       pkt_rd_req;
    reg [1:0] upload_dd;

    always @(posedge clk) begin
        if (!rstn) begin
            app_axi_rack <= 1'b0;
            app_axi_wack <= 1'b0;
        end else begin
            app_axi_rack <= app_axi_rreq;
            app_axi_wack <= app_axi_wreq;
        end
    end

    // ***********************************************************************************
    // read
    // ***********************************************************************************
    always @(posedge clk) begin
        if (!rstn) begin
            app_axi_rdata <= 0;
        end else begin
            app_axi_rdata <= 0;
            if (app_axi_rreq) begin
                case (app_axi_raddr)
                    // config 0 - 32
                    12'h000: app_axi_rdata <= wtd_en;
                    12'h004: app_axi_rdata <= wtd_preset;
                    12'h008: app_axi_rdata <= tdest;
                    12'h00c: app_axi_rdata <= baud_limit;
                    12'h010: app_axi_rdata <= baud_freq;
                    12'h014: app_axi_rdata <= recv_parity;
                    12'h018: app_axi_rdata <= tx_cnt;
                    12'h01c: app_axi_rdata <= rx_cnt;
                    12'h020: app_axi_rdata <= tx_busy;
                    12'h024: app_axi_rdata <= rx_busy;
                    12'h028: app_axi_rdata <= pkt_cnt;
                    12'h02c: app_axi_rdata <= pkt_rd_req | (|upload_dd) | upload_req;
                    12'h030: app_axi_rdata <= upload_busy;
                    12'h034: app_axi_rdata <= pkt_length;
                    12'h038: app_axi_rdata <= loopback_en;
                    default: app_axi_rdata <= 32'hdeadbeef;
                endcase
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            wtd_en      <= 1'b1;
            wtd_preset  <= 16 * 10 * 2;
            tdest       <= 0;
            baud_limit  <= 15337;
            baud_freq   <= 288;
            recv_parity <= 0;
            loopback_en <= 1'b0;
        end else begin
            wtd_en      <= wtd_en;
            wtd_preset  <= wtd_preset;
            tdest       <= tdest;
            baud_limit  <= baud_limit;
            baud_freq   <= baud_freq;
            recv_parity <= recv_parity;
            loopback_en <= loopback_en;
            if (app_axi_wreq) begin
                case (app_axi_waddr)
                    12'h000: wtd_en <= app_axi_wdata;
                    12'h004: wtd_preset <= app_axi_wdata;
                    12'h008: tdest <= app_axi_wdata;
                    12'h00c: baud_limit <= app_axi_wdata;
                    12'h010: baud_freq <= app_axi_wdata;
                    12'h014: recv_parity <= app_axi_wdata;
                    12'h038: loopback_en <= app_axi_wdata;
                    default: ;
                endcase
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            pkt_rd_req <= 1'b0;
        end else begin
            if (app_axi_wreq) begin
                case (app_axi_waddr)
                    12'h02c: pkt_rd_req <= |app_axi_wdata;
                    default: pkt_rd_req <= 1'b0;
                endcase
            end else begin
                pkt_rd_req <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            upload_dd  <= 0;
            upload_req <= 1'b0;
        end else begin
            upload_dd  <= {upload_dd[0], pkt_rd_req};
            upload_req <= upload_dd[0] & ~upload_dd[1];
        end
    end
endmodule

// verilog_format: off
`resetall
// verilog_format: on
