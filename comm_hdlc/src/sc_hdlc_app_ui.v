// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module sc_hdlc_app_ui (
    input wire clk,
    input wire rstn,

    input  wire        app_axi_rreq,
    output reg         app_axi_rack,
    input  wire [11:0] app_axi_raddr,
    output reg  [31:0] app_axi_rdata,

    input  wire        app_axi_wreq,
    output reg         app_axi_wack,
    input  wire [11:0] app_axi_waddr,
    input  wire [31:0] app_axi_wdata,

    output reg tx_en,
    output reg tx_rstn,
    output reg rx_en,
    output reg rx_rstn,

    output reg        baud_update,
    output reg [11:0] baud_freq,
    output reg [15:0] baud_limit,
    output reg        loopback_en,
    output reg        ovs_en,
    output reg        keep_flag,

    input wire        tx_busy,
    input wire        rx_busy,
    input wire [31:0] tx_cnt,
    input wire [31:0] rx_cnt,

    output reg         upload_req,
    input  wire        upload_busy,
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
                    12'h000: app_axi_rdata <= tx_en;
                    12'h004: app_axi_rdata <= tx_rstn;
                    12'h008: app_axi_rdata <= rx_en;
                    12'h00c: app_axi_rdata <= rx_rstn;
                    12'h010: app_axi_rdata <= loopback_en;
                    12'h014: app_axi_rdata <= {keep_flag, ovs_en};
                    12'h018: app_axi_rdata <= baud_limit;
                    12'h01c: app_axi_rdata <= baud_freq;
                    12'h020: app_axi_rdata <= tx_cnt;
                    12'h024: app_axi_rdata <= rx_cnt;
                    12'h028: app_axi_rdata <= tx_busy;
                    12'h02c: app_axi_rdata <= rx_busy;
                    12'h030: app_axi_rdata <= pkt_cnt;
                    12'h034: app_axi_rdata <= pkt_rd_req | (|upload_dd) | upload_req;
                    12'h038: app_axi_rdata <= upload_busy;
                    12'h03c: app_axi_rdata <= pkt_length;
                    12'h040: app_axi_rdata <= baud_update;
                    default: app_axi_rdata <= 32'hdeadbeef;
                endcase
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            tx_en       <= 1'b0;
            rx_en       <= 1'b0;
            loopback_en <= 1'b0;
            ovs_en      <= 1'b1;
            keep_flag   <= 1'b0;
            baud_limit  <= 1;
            baud_freq   <= 4;
        end else begin
            tx_en       <= tx_en;
            rx_en       <= rx_en;
            loopback_en <= loopback_en;
            ovs_en      <= ovs_en;
            keep_flag   <= keep_flag;
            baud_limit  <= baud_limit;
            baud_freq   <= baud_freq;
            if (app_axi_wreq) begin
                case (app_axi_waddr)
                    12'h000: tx_en <= app_axi_wdata;
                    12'h008: rx_en <= app_axi_wdata;
                    12'h010: loopback_en <= app_axi_wdata;
                    12'h014: {keep_flag, ovs_en} <= ~app_axi_wdata[0];
                    12'h018: baud_limit <= app_axi_wdata;
                    12'h01c: baud_freq <= app_axi_wdata;
                    default: ;
                endcase
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            tx_rstn <= 1'b0;
        end else begin
            if (app_axi_wreq) begin
                case (app_axi_waddr)
                    12'h004: tx_rstn <= ~(|app_axi_wdata);
                    default: tx_rstn <= 1'b1;
                endcase
            end else begin
                tx_rstn <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            rx_rstn <= 1'b0;
        end else begin
            if (app_axi_wreq) begin
                case (app_axi_waddr)
                    12'h00c: rx_rstn <= ~(|app_axi_wdata);
                    default: rx_rstn <= 1'b1;
                endcase
            end else begin
                rx_rstn <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            pkt_rd_req <= 1'b0;
        end else begin
            if (app_axi_wreq) begin
                case (app_axi_waddr)
                    12'h034: begin
                        if (pkt_cnt > 0) begin
                            pkt_rd_req <= |app_axi_wdata;
                        end else begin
                            pkt_rd_req <= 1'b0;
                        end
                    end
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

    always @(posedge clk) begin
        if (!rstn) begin
            baud_update <= 1'b0;
        end else begin
            if (app_axi_wreq) begin
                case (app_axi_waddr)
                    12'h040: begin
                        baud_update <= |app_axi_wdata;
                    end
                    default: baud_update <= 1'b0;
                endcase
            end else begin
                baud_update <= 1'b0;
            end
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
