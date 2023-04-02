// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module adc_sample_app_ui #(
    parameter integer S_AXI_DATA_WIDTH = 32,
    parameter integer S_AXI_ADDR_WIDTH = 16
) (
    input wire clk,
    input wire rstn,

    input  wire                        app_axi_rreq,
    output reg                         app_axi_rack,
    input  wire [S_AXI_ADDR_WIDTH-1:0] app_axi_raddr,
    output reg  [S_AXI_DATA_WIDTH-1:0] app_axi_rdata,

    input  wire                        app_axi_wreq,
    output reg                         app_axi_wack,
    input  wire [S_AXI_ADDR_WIDTH-1:0] app_axi_waddr,
    input  wire [S_AXI_DATA_WIDTH-1:0] app_axi_wdata,

    output wire [63:0] config_start_addr,
    output wire [63:0] config_end_addr,
    output wire [31:0] config_sample_num,
    output wire [31:0] config_pre_sample_num,

    output reg  sample_start,
    output wire sample_trig,
    output reg  update_config,

    input  wire        sample_busy,
    input  wire        sample_done,
    input  wire        sample_err,
    output reg         move_en,
    input  wire        move_busy,
    input  wire        move_err,
    input  wire        move_done,
    input  wire [63:0] move_addr,

    input wire [63:0] rec_trig_addr,
    input wire [63:0] rec_start_addr,
    input wire [63:0] rec_end_addr,
    //
    output reg data_buffer_reset_n,
    output reg sample_reset_n,
    output reg move_reset_n,
    output reg pkt_info_clr
);

    reg  [63:0] config_start_addr_reg;
    reg  [63:0] config_end_addr_reg;
    reg  [31:0] config_sample_num_reg;
    reg  [31:0] config_pre_sample_num_reg;

    reg         update_config_reg;
    reg         sample_reset_reg;
    reg         sample_start_reg;
    reg         sample_trig_reg;

    reg  [31:0] sample_status_reg;
    wire [31:0] sample_status_reg_s;
    wire        sample_done_reg;
    wire        sample_err_reg;
    wire        move_err_reg;
    wire        move_done_reg;

    assign sample_trig = sample_trig_reg;

    assign config_start_addr = config_start_addr_reg;
    assign config_end_addr = config_end_addr_reg;
    assign config_sample_num = config_sample_num_reg;
    assign config_pre_sample_num = config_pre_sample_num_reg;

    assign sample_done_reg = sample_status_reg[17];
    assign sample_err_reg = sample_status_reg[16];
    assign move_err_reg = sample_status_reg[1];
    assign move_done_reg = sample_status_reg[0];

    assign sample_status_reg_s = {
        13'b0,
        sample_busy,
        sample_err_reg ? 1'b1 : sample_err,
        sample_done_reg ? 1'b1 : sample_done,
        13'b0,
        move_busy,
        move_err_reg ? 1'b1 : move_err,
        move_done_reg ? 1'b1 : move_done
    };

    always @(posedge clk) begin
        if (!rstn) begin
            app_axi_rack <= 1'b0;
            app_axi_wack <= 1'b0;
        end else begin
            app_axi_rack <= app_axi_rreq;
            app_axi_wack <= app_axi_wreq;
        end
    end

    always @(posedge clk) begin
        if (!rstn || !sample_reset_n) begin
            sample_status_reg <= 0;
        end else begin
            if (app_axi_wreq) begin
                case (app_axi_waddr)
                    16'h0200: sample_status_reg <= ((~app_axi_wdata) & sample_status_reg_s);
                    default:  ;
                endcase
            end else begin
                sample_status_reg <= sample_status_reg_s;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn || !sample_reset_n) begin
            config_start_addr_reg     <= 0;
            config_end_addr_reg       <= 0;
            config_sample_num_reg     <= 0;
            config_pre_sample_num_reg <= 0;
        end else begin
            config_start_addr_reg     <= config_start_addr_reg;
            config_end_addr_reg       <= config_end_addr_reg;
            config_sample_num_reg     <= config_sample_num_reg;
            config_pre_sample_num_reg <= config_pre_sample_num_reg;

            if (app_axi_wreq) begin
                case (app_axi_waddr)
                    16'h0004: config_start_addr_reg[31:0] <= app_axi_wdata;
                    16'h0008: config_start_addr_reg[63:32] <= app_axi_wdata;
                    16'h000c: config_end_addr_reg[31:0] <= app_axi_wdata;
                    16'h0010: config_end_addr_reg[63:32] <= app_axi_wdata;
                    16'h0014: config_sample_num_reg <= app_axi_wdata;
                    16'h0018: config_pre_sample_num_reg <= app_axi_wdata;
                    default:  ;
                endcase
            end
        end
    end

    // ***********************************************************************************
    // update_config
    // ***********************************************************************************
    always @(posedge clk) begin
        if (!rstn || !sample_reset_n) begin
            update_config_reg <= 1'b0;
        end else begin
            if (app_axi_wreq) begin
                case (app_axi_waddr)
                    16'h0100: update_config_reg <= app_axi_wdata[0];
                    default:  update_config_reg <= 1'b0;
                endcase
            end else begin
                update_config_reg <= 1'b0;
            end
        end
    end

    reg [1:0] update_config_s;
    always @(posedge clk) begin
        if (!rstn) begin
            update_config_s <= 1'b0;
            update_config   <= 1'b0;
        end else begin
            update_config_s <= {update_config_s[0], update_config_reg};
            update_config   <= (update_config_s[0] & (~update_config_s[1]));
        end
    end

    // ***********************************************************************************
    // reset
    // ***********************************************************************************
    always @(posedge clk) begin
        if (!rstn) begin
            sample_reset_reg <= 1'b0;
        end else begin
            if (app_axi_wreq) begin
                case (app_axi_waddr)
                    16'h0104: sample_reset_reg <= app_axi_wdata[0];
                    default:  sample_reset_reg <= 1'b0;
                endcase
            end else begin
                sample_reset_reg <= 1'b0;
            end
        end
    end

    reg [1:0] sample_reset_s;
    always @(posedge clk) begin
        if (!rstn) begin
            sample_reset_s <= 1'b0;
        end else begin
            sample_reset_s <= {sample_reset_s[0], sample_reset_reg};
        end
    end

    reg [3:0] reset_fsm;
    always @(posedge clk) begin
        if (!rstn) begin
            reset_fsm <= 4'h0;
        end else begin
            case (reset_fsm)
                4'h0: begin
                    if ((sample_reset_s[0] & (~sample_reset_s[1]))) begin
                        reset_fsm <= 4'h1;
                    end else begin
                        reset_fsm <= 4'h0;
                    end
                end
                4'h1: reset_fsm <= 4'h2;
                4'h2: begin
                    if (!move_busy) begin
                        reset_fsm <= 4'h3;
                    end else begin
                        reset_fsm <= 4'h2;
                    end
                end
                default: begin
                    reset_fsm <= 4'h0;
                end
            endcase
        end
    end

    // 0: idle
    // 1: clear pkt_info and deassert move_en and reset sample
    // 2: wait move done
    // 3: clear data buffer and reset move
    always @(posedge clk) begin
        if (!rstn) begin
            move_en        <= 1'h0;
            sample_reset_n <= 1'h0;
            pkt_info_clr   <= 1'h1;
        end else begin
            case (reset_fsm)
                4'h0: begin
                    move_en        <= 1'b1;
                    sample_reset_n <= 1'b1;
                    pkt_info_clr   <= 1'h0;
                end
                default: begin
                    move_en        <= 1'h0;
                    sample_reset_n <= 1'h0;
                    pkt_info_clr   <= 1'h1;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            move_reset_n        <= 1'b0;
            data_buffer_reset_n <= 1'b0;
        end else begin
            case (reset_fsm)
                4'h3: begin
                    move_reset_n        <= 1'b0;
                    data_buffer_reset_n <= 1'b0;
                end
                default: begin
                    move_reset_n        <= 1'b1;
                    data_buffer_reset_n <= 1'b1;
                end
            endcase
        end
    end

    // ***********************************************************************************
    // sample_start
    // ***********************************************************************************
    always @(posedge clk) begin
        if (!rstn || !sample_reset_n) begin
            sample_start_reg <= 1'b0;
        end else begin
            if (app_axi_wreq) begin
                case (app_axi_waddr)
                    16'h0108: sample_start_reg <= app_axi_wdata[0];
                    default:  sample_start_reg <= 1'b0;
                endcase
            end else begin
                sample_start_reg <= 1'b0;
            end
        end
    end

    reg [1:0] sample_start_s;
    always @(posedge clk) begin
        if (!rstn || !sample_reset_n) begin
            sample_start_s <= 0;
        end else begin
            sample_start_s <= {sample_start_s[0], sample_start_reg};
        end
    end

    always @(posedge clk) begin
        if (!rstn || !sample_reset_n) begin
            sample_start <= 1'b0;
        end else begin
            if (sample_busy) begin
                sample_start <= 1'b0;
            end else begin
                if (sample_start_s[0] & (~sample_start_s[1])) begin
                    sample_start <= 1'b1;
                end else begin
                    sample_start <= sample_start;
                end
            end
        end
    end

    // ***********************************************************************************
    // trig
    // ***********************************************************************************
    always @(posedge clk) begin
        if (!rstn || !sample_reset_n) begin
            sample_trig_reg <= 1'b0;
        end else begin
            if (app_axi_wreq) begin
                case (app_axi_waddr)
                    16'h010c: sample_trig_reg <= app_axi_wdata[0];
                    default:  sample_trig_reg <= sample_trig_reg;
                endcase
            end else begin
                sample_trig_reg <= sample_trig_reg;
            end
        end
    end

    // ***********************************************************************************
    // read
    // ***********************************************************************************
    always @(posedge clk) begin
        if (!rstn) begin
            app_axi_rdata <= 0;
        end else begin
            if (app_axi_rreq) begin
                case (app_axi_raddr)
                    // config 0x00--
                    16'h0000: app_axi_rdata <= 32'hF7DEC7A5;
                    16'h0004: app_axi_rdata <= config_start_addr_reg[31:0];
                    16'h0008: app_axi_rdata <= config_start_addr_reg[63:32];
                    16'h000c: app_axi_rdata <= config_end_addr_reg[31:0];
                    16'h0010: app_axi_rdata <= config_end_addr_reg[63:32];
                    16'h0014: app_axi_rdata <= config_sample_num_reg;
                    16'h0018: app_axi_rdata <= config_pre_sample_num_reg;

                    // control 0x01--
                    16'h0100:
                    app_axi_rdata <= {
                        31'b0, update_config_reg | (|update_config_s) | update_config
                    };
                    16'h0104:
                    app_axi_rdata <= {
                        31'b0,
                        sample_reset_reg | (|sample_reset_s) | (|reset_fsm) | (~sample_reset_n)
                    };
                    16'h0108:
                    app_axi_rdata <= {31'b0, sample_start_reg | (|sample_start_s) | sample_start};
                    16'h010c: app_axi_rdata <= {31'b0, sample_trig_reg};

                    // status 0x02--
                    16'h0200: app_axi_rdata <= sample_status_reg;
                    16'h0204: app_axi_rdata <= rec_start_addr[31:0];
                    16'h0208: app_axi_rdata <= rec_start_addr[63:32];
                    16'h020c: app_axi_rdata <= rec_end_addr[31:0];
                    16'h0210: app_axi_rdata <= rec_end_addr[63:32];
                    16'h0214: app_axi_rdata <= rec_trig_addr[31:0];
                    16'h0218: app_axi_rdata <= rec_trig_addr[63:32];
                    16'h021c: app_axi_rdata <= move_addr[31:0];
                    16'h0220: app_axi_rdata <= move_addr[63:32];
                    default:  app_axi_rdata <= 0;
                endcase
            end
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
