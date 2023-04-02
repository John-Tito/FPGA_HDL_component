// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module adc_backend #(
    parameter integer MM_ADDR_WIDTH = 32,
    parameter integer S_AXI_DATA_WIDTH = 32,
    parameter integer S_AXI_ADDR_WIDTH = 16,
    parameter integer INPUT_BIT_WIDTH = 128,
    parameter integer OUTPUT_BIT_WIDTH = 512,
    parameter integer BLOCK_SIZE = 512,
    parameter IN_SIM = "false",
    parameter ENABLE_DEBUG = "false"
) (
    input wire clk,
    input wire rstn,

    input  wire                        app_axi_rreq,
    output wire                        app_axi_rack,
    input  wire [S_AXI_ADDR_WIDTH-1:0] app_axi_raddr,
    output wire [S_AXI_DATA_WIDTH-1:0] app_axi_rdata,

    input  wire                        app_axi_wreq,
    output wire                        app_axi_wack,
    input  wire [S_AXI_ADDR_WIDTH-1:0] app_axi_waddr,
    input  wire [S_AXI_DATA_WIDTH-1:0] app_axi_wdata,

    input wire                         adc_data_val,
    input wire [(INPUT_BIT_WIDTH-1):0] adc_data_out,

    output wire [  (OUTPUT_BIT_WIDTH-1):0] m_axis_tdata,
    output wire [(OUTPUT_BIT_WIDTH/8-1):0] m_axis_tkeep,
    output wire                            m_axis_tlast,
    output wire                            m_axis_tvalid,
    input  wire                            m_axis_tready,

    output wire [(MM_ADDR_WIDTH+39):0] m_axis_s2mm_cmd_tdata,
    output wire                        m_axis_s2mm_cmd_tvalid,
    input  wire                        m_axis_s2mm_cmd_tready,

    input  wire       s_axis_s2mm_err,
    input  wire [7:0] s_axis_s2mm_sts_tdata,
    input  wire       s_axis_s2mm_sts_tkeep,
    input  wire       s_axis_s2mm_sts_tlast,
    input  wire       s_axis_s2mm_sts_tvalid,
    output wire       s_axis_s2mm_sts_tready
);

    // config
    wire [                   63:0] config_start_addr;
    wire [                   63:0] config_end_addr;
    wire [                   31:0] config_sample_num;
    wire [                   31:0] config_pre_sample_num;

    wire                           update_config;
    wire                           sample_start;
    wire                           sample_trig;
    wire                           sample_busy;
    wire                           sample_done;
    wire                           sample_err;

    wire [                   63:0] rec_trig_addr;
    wire [                   63:0] rec_start_addr;
    wire [                   63:0] rec_end_addr;
    wire [                   63:0] move_addr;
    wire                           move_en;
    wire                           move_busy;
    wire                           move_err;
    wire                           move_done;

    //
    wire                           trig_out;

    // data write to fifo
    wire                           axis_tvalid;
    wire                           axis_tready;
    wire                           axis_tlast;
    wire [  (INPUT_BIT_WIDTH-1):0] axis_tdata;
    wire [(INPUT_BIT_WIDTH/8-1):0] axis_tkeep;

    // data rrad from fifo
    wire                           axis_s2mm_tvalid_0;
    wire                           axis_s2mm_tready_0;
    wire                           axis_s2mm_tlast_0;
    wire [  (INPUT_BIT_WIDTH-1):0] axis_s2mm_tdata_0;
    wire [(INPUT_BIT_WIDTH/8-1):0] axis_s2mm_tkeep_0;

    wire                           pkt_info_wr;
    wire [                   95:0] pkt_info_wr_data;
    wire                           pkt_info_rd;
    wire [                   95:0] pkt_info_rd_data;
    wire                           pkt_info_empty;
    wire                           pkt_info_full;

    wire                           data_buffer_reset_n;
    wire                           sample_reset_n;
    wire                           move_reset_n;
    wire                           pkt_info_clr;

    data_mover_ui #(
        .MM_ADDR_WIDTH(MM_ADDR_WIDTH),
        .BLOCK_SIZE   (BLOCK_SIZE)
    ) data_mover_ui_inst (
        .clk           (clk),
        .rstn          (move_reset_n),
        .pkt_info_empty(pkt_info_empty),
        .pkt_info_data (pkt_info_rd_data),
        .pkt_info_rd   (pkt_info_rd),
        .fifo_afull    (1'b0),
        .cmd_tready    (m_axis_s2mm_cmd_tready),
        .cmd_tvalid    (m_axis_s2mm_cmd_tvalid),
        .cmd_tdata     (m_axis_s2mm_cmd_tdata),
        .sts_err       (s_axis_s2mm_err),
        .sts_tvalid    (s_axis_s2mm_sts_tvalid),
        .sts_tdata     (s_axis_s2mm_sts_tdata),
        .sts_tkeep     (s_axis_s2mm_sts_tkeep),
        .sts_tlast     (s_axis_s2mm_sts_tlast),
        .sts_tready    (s_axis_s2mm_sts_tready),
        .move_en       (move_en),
        .move_addr     (move_addr),
        .move_busy     (move_busy),
        .move_err      (move_err),
        .move_done     (move_done)
    );

    adc_sample_app_ui #(
        .S_AXI_DATA_WIDTH(S_AXI_DATA_WIDTH),
        .S_AXI_ADDR_WIDTH(S_AXI_ADDR_WIDTH)
    ) adc_sample_app_ui_inst (
        .clk                  (clk),
        .rstn                 (rstn),
        .app_axi_rreq         (app_axi_rreq),
        .app_axi_rack         (app_axi_rack),
        .app_axi_raddr        (app_axi_raddr),
        .app_axi_rdata        (app_axi_rdata),
        .app_axi_wreq         (app_axi_wreq),
        .app_axi_wack         (app_axi_wack),
        .app_axi_waddr        (app_axi_waddr),
        .app_axi_wdata        (app_axi_wdata),
        .config_start_addr    (config_start_addr),
        .config_end_addr      (config_end_addr),
        .config_sample_num    (config_sample_num),
        .config_pre_sample_num(config_pre_sample_num),
        .sample_start         (sample_start),
        .sample_trig          (sample_trig),
        .update_config        (update_config),
        .sample_busy          (sample_busy),
        .sample_done          (sample_done),
        .sample_err           (sample_err),
        .move_en              (move_en),
        .move_busy            (move_busy),
        .move_err             (move_err),
        .move_done            (move_done),
        .move_addr            (move_addr),
        .rec_trig_addr        (rec_trig_addr),
        .rec_start_addr       (rec_start_addr),
        .rec_end_addr         (rec_end_addr),

        .data_buffer_reset_n(data_buffer_reset_n),
        .sample_reset_n     (sample_reset_n),
        .move_reset_n       (move_reset_n),
        .pkt_info_clr       (pkt_info_clr)
    );

    sample_core #(
        .BIT_WIDTH    (INPUT_BIT_WIDTH),
        .BLOCK_SIZE   (BLOCK_SIZE),
        .IN_SIM       (IN_SIM),
        .ENABLE_DEBUG (ENABLE_DEBUG)
    ) sample_core_inst (
        .clk                  (clk),
        .rstn                 (sample_reset_n),
        .config_start_addr    (config_start_addr),
        .config_end_addr      (config_end_addr),
        .config_sample_num    (config_sample_num),
        .config_pre_sample_num(config_pre_sample_num),
        .update_config        (update_config),
        .sample_start         (sample_start),
        .sample_trig          (sample_trig),
        .sample_busy          (sample_busy),
        .sample_done          (sample_done),
        .sample_err           (sample_err),
        .trig_out             (trig_out),
        .data                 (adc_data_out),
        .data_valid           (adc_data_val),
        .m_axis_tvalid        (axis_tvalid),
        .m_axis_tdata         (axis_tdata),
        .m_axis_tkeep         (axis_tkeep),
        .m_axis_tlast         (axis_tlast),
        .m_axis_tready        (axis_tready),
        .pkt_info_wr          (pkt_info_wr),
        .pkt_info_data        (pkt_info_wr_data),
        .rec_trig_addr        (rec_trig_addr),
        .rec_start_addr       (rec_start_addr),
        .rec_end_addr         (rec_end_addr)
    );

    wire almost_empty;
    wire almost_full;
    sample_data_fifo data_buffer (
        .s_axis_aresetn(data_buffer_reset_n),  // input wire s_axis_aresetn
        .s_axis_aclk   (clk),                  // input wire s_axis_aclk
        .s_axis_tvalid (axis_tvalid),          // input wire s_axis_tvalid
        .s_axis_tready (axis_tready),          // output wire s_axis_tready
        .s_axis_tdata  (axis_tdata),           // input wire [127 : 0] s_axis_tdata
        .s_axis_tkeep  (axis_tkeep),           // input wire [15 : 0] s_axis_tkeep
        .s_axis_tlast  (axis_tlast),           // input wire s_axis_tlast
        .m_axis_tvalid (axis_s2mm_tvalid_0),   // output wire m_axis_tvalid
        .m_axis_tready (axis_s2mm_tready_0),   // input wire m_axis_tready
        .m_axis_tdata  (axis_s2mm_tdata_0),    // output wire [127 : 0] m_axis_tdata
        .m_axis_tkeep  (axis_s2mm_tkeep_0),    // output wire [15 : 0] m_axis_tkeep
        .m_axis_tlast  (axis_s2mm_tlast_0),    // output wire m_axis_tlast
        .almost_empty  (almost_empty),         // output wire almost_empty
        .almost_full   (almost_full)           // output wire almost_full
    );

    sample_pkt_info_fifo pkt_info_buffer (
        .clk         (clk),               // input wire clk
        .srst        (pkt_info_clr),      // input wire srst
        .din         (pkt_info_wr_data),  // input wire [63 : 0] din
        .wr_en       (pkt_info_wr),       // input wire wr_en
        .rd_en       (pkt_info_rd),       // input wire rd_en
        .dout        (pkt_info_rd_data),  // output wire [63 : 0] dout
        .full        (),                  // output wire full
        .almost_full (),                  // output wire almost_full
        .empty       (pkt_info_empty),    // output wire empty
        .almost_empty()                   // output wire almost_empty
    );

    generate
        if (INPUT_BIT_WIDTH != OUTPUT_BIT_WIDTH) begin : g_dwc
            sample_dw_conv sample_dw_conv_inst (
                .aclk         (clk),
                .aresetn      (data_buffer_reset_n),
                .s_axis_tvalid(axis_s2mm_tvalid_0),
                .s_axis_tready(axis_s2mm_tready_0),
                .s_axis_tdata (axis_s2mm_tdata_0),
                .s_axis_tkeep (axis_s2mm_tkeep_0),
                .s_axis_tlast (axis_s2mm_tlast_0),
                .m_axis_tvalid(m_axis_tvalid),
                .m_axis_tready(m_axis_tready),
                .m_axis_tdata (m_axis_tdata),
                .m_axis_tkeep (m_axis_tkeep),
                .m_axis_tlast (m_axis_tlast)
            );
        end else begin : g_bypass
            assign m_axis_tvalid      = axis_s2mm_tvalid_0;
            assign axis_s2mm_tready_0 = m_axis_tready;
            assign m_axis_tdata       = axis_s2mm_tdata_0;
            assign m_axis_tkeep       = axis_s2mm_tkeep_0;
            assign m_axis_tlast       = axis_s2mm_tlast_0;
        end
    endgenerate
endmodule

// verilog_format: off
`resetall
// verilog_format: on
