// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on
module adc_backend_tb;

    // Parameters
    localparam real TIMEPERIOD = 5;
    localparam integer MM_ADDR_WIDTH = 32;
    localparam integer BIT_WIDTH = 64;
    localparam integer BLOCK_SIZE = 512;

    // Ports
    reg                         clk = 0;
    reg                         rstn = 0;

    reg  [ (MM_ADDR_WIDTH-1):0] config_start_addr = 0;
    reg  [ (MM_ADDR_WIDTH-1):0] config_end_addr = 0;
    reg  [ (MM_ADDR_WIDTH-1):0] config_sample_num = 0;
    reg  [ (MM_ADDR_WIDTH-1):0] config_pre_sample_num = 0;
    reg                         update_config = 0;

    reg                         sample_start = 0;
    wire                        sample_trig;
    wire                        sample_busy;
    wire                        sample_done;
    wire                        sample_err;
    reg                         adc_data_val = 0;
    reg  [     (BIT_WIDTH-1):0] adc_data_out = 0;

    wire [     (BIT_WIDTH-1):0] axis_s2mm_tdata0;
    wire [   (BIT_WIDTH/8-1):0] axis_s2mm_tkeep0;
    wire                        axis_s2mm_tlast0;
    wire                        axis_s2mm_tvalid0;
    wire                        axis_s2mm_tready0;

    wire [               511:0] axis_s2mm_tdata1;
    wire [                63:0] axis_s2mm_tkeep1;
    wire                        axis_s2mm_tlast1;
    wire                        axis_s2mm_tvalid1;
    wire                        axis_s2mm_tready1;

    wire [(MM_ADDR_WIDTH+39):0] axis_s2mm_cmd_tdata;
    wire                        axis_s2mm_cmd_tvalid;
    wire                        axis_s2mm_cmd_tready;
    wire                        axis_s2mm_error;
    wire [                 7:0] axis_s2mm_sts_tdata;
    wire                        axis_s2mm_sts_tkeep;
    wire                        axis_s2mm_sts_tlast;
    wire                        axis_s2mm_sts_tvalid;
    wire                        axis_s2mm_sts_tready;

    wire [     (BIT_WIDTH-1):0] odata;
    wire                        odata_valid;
    wire [     (BIT_WIDTH-1):0] idata;
    wire                        idata_valid;

    adc_data_generator #(
        .DIV(1),
        .CHANNEL_NUM   (4),
        .ADC_BIT_NUM   (10),
        .OUTPUT_BIT_NUM(16)
    ) adc_data_generator_dut (
        .clk       (clk),
        .rstn      (rstn),
        .data      (idata),
        .data_valid(idata_valid)
    );

    trigger_generator trigger_generator_dut (
        .clk        (clk),
        .rstn       (rstn),
        .trig_mux   (4'd1),
        .trig_level (16'd218),
        .idata      (idata),
        .idata_valid(idata_valid),
        .odata      (odata),
        .odata_valid(odata_valid),
        .trig       (sample_trig)
    );

    adc_backend #(
        .MM_ADDR_WIDTH(MM_ADDR_WIDTH),
        .BIT_WIDTH    (BIT_WIDTH),
        .BLOCK_SIZE   (BLOCK_SIZE)
    ) adc_backend_dut (
        .clk                  (clk),
        .rstn                 (rstn),
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
        .adc_data_val         (odata_valid),
        .adc_data_out         (odata),

        .m_axis_tdata (axis_s2mm_tdata0),
        .m_axis_tkeep (axis_s2mm_tkeep0),
        .m_axis_tlast (axis_s2mm_tlast0),
        .m_axis_tvalid(axis_s2mm_tvalid0),
        .m_axis_tready(axis_s2mm_tready0),

        .m_axis_s2mm_cmd_tdata (axis_s2mm_cmd_tdata),
        .m_axis_s2mm_cmd_tvalid(axis_s2mm_cmd_tvalid),
        .m_axis_s2mm_cmd_tready(axis_s2mm_cmd_tready),

        .s_axis_s2mm_err       (axis_s2mm_error),
        .s_axis_s2mm_sts_tdata (axis_s2mm_sts_tdata),
        .s_axis_s2mm_sts_tkeep (axis_s2mm_sts_tkeep),
        .s_axis_s2mm_sts_tlast (axis_s2mm_sts_tlast),
        .s_axis_s2mm_sts_tvalid(axis_s2mm_sts_tvalid),
        .s_axis_s2mm_sts_tready(axis_s2mm_sts_tready)
    );

    axis_dwidth_converter_0 axis_dwidth_converter_inst (
        .aclk         (clk),                // input wire aclk
        .aresetn      (rstn),               // input wire aresetn
        .s_axis_tvalid(axis_s2mm_tvalid0),  // input wire s_axis_tvalid
        .s_axis_tready(axis_s2mm_tready0),  // output wire s_axis_tready
        .s_axis_tdata (axis_s2mm_tdata0),   // input wire [63 : 0] s_axis_tdata
        .s_axis_tkeep (axis_s2mm_tkeep0),   // input wire [7 : 0] s_axis_tkeep
        .s_axis_tlast (axis_s2mm_tlast0),   // input wire s_axis_tlast
        .m_axis_tvalid(axis_s2mm_tvalid1),  // output wire m_axis_tvalid
        .m_axis_tready(axis_s2mm_tready1),  // input wire m_axis_tready
        .m_axis_tdata (axis_s2mm_tdata1),   // output wire [511 : 0] m_axis_tdata
        .m_axis_tkeep (axis_s2mm_tkeep1),   // output wire [63 : 0] m_axis_tkeep
        .m_axis_tlast (axis_s2mm_tlast1)    // output wire m_axis_tlast
    );

    sim_datamover_warper sim_datamover_warper_dut (
        .clk (clk),
        .rstn(rstn),

        .axis_s2mm_cmd_tvalid(axis_s2mm_cmd_tvalid),
        .axis_s2mm_cmd_tready(axis_s2mm_cmd_tready),
        .axis_s2mm_cmd_tdata (axis_s2mm_cmd_tdata),

        .axis_s2mm_sts_tvalid(axis_s2mm_sts_tvalid),
        .axis_s2mm_sts_tready(axis_s2mm_sts_tready),
        .axis_s2mm_sts_tdata (axis_s2mm_sts_tdata),
        .axis_s2mm_sts_tkeep (axis_s2mm_sts_tkeep),
        .axis_s2mm_sts_tlast (axis_s2mm_sts_tlast),
        .axis_s2mm_error     (axis_s2mm_error),

        .axis_s2mm_tdata (axis_s2mm_tdata1),
        .axis_s2mm_tkeep (axis_s2mm_tkeep1),
        .axis_s2mm_tvalid(axis_s2mm_tvalid1),
        .axis_s2mm_tready(axis_s2mm_tready1),
        .axis_s2mm_tlast (axis_s2mm_tlast1)
    );

    initial begin
        begin
            config_start_addr     = 32'h00000000;
            config_end_addr       = 32'h00010000;
            config_sample_num     = 1024;
            config_pre_sample_num = 1024;
            wait (rstn);
            @(posedge clk);
            @(posedge clk);

            update_config = 1'b1;
            @(posedge clk);
            update_config = 1'b0;
            @(posedge clk);

        end
    end

    initial begin
        begin
            sample_start = 1'b0;
            wait (rstn);
            #1000;
            @(posedge clk);
            @(posedge clk);

            sample_start = 1'b1;
            @(posedge clk);
            sample_start = 1'b0;
            @(posedge clk);
        end
    end

    initial begin
        begin
            #2000000;
            $finish;
        end
    end

    // ***********************************************************************************
    // clock block
    always #(TIMEPERIOD / 2) clk = !clk;

    // reset block
    initial begin
        begin
            rstn = 1'b0;
            #(TIMEPERIOD * 2);
            rstn = 1'b1;
        end
    end

    // record block
    initial begin
        begin
            $dumpfile("sim/test_tb.lxt");
            $dumpvars(0, adc_backend_tb);
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
