// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on
module sample_core_tb;

    // Parameters
    localparam real TIMEPERIOD = 5;
    localparam integer MM_ADDR_WIDTH = 32;
    localparam integer BIT_WIDTH = 512;
    localparam integer BLOCK_SIZE = 512;

    // Ports
    reg                          clk = 0;
    reg                          rstn = 0;

    // Ports
    reg  [  (MM_ADDR_WIDTH-1):0] config_start_addr = 0;
    reg  [  (MM_ADDR_WIDTH-1):0] config_end_addr = 0;
    reg  [                 31:0] config_sample_num = 0;
    reg  [                 31:0] config_pre_sample_num = 0;
    reg                          update_config = 0;
    reg                          sample_start = 0;
    wire                         sample_trig;
    wire                         sample_busy;
    wire                         sample_done;
    wire                         sample_err;
    wire                         trig_out;

    wire [      (BIT_WIDTH-1):0] odata;
    wire                         odata_valid;
    wire [      (BIT_WIDTH-1):0] idata;
    wire                         idata_valid;

    wire                         m_axis_tvalid;
    wire [    (BIT_WIDTH-1) : 0] m_axis_tdata;
    wire [  (BIT_WIDTH/8-1) : 0] m_axis_tstrb;
    wire                         m_axis_tlast;
    wire                         m_axis_tready;

    reg                          pkt_info_wr;
    reg  [(MM_ADDR_WIDTH*2-1):0] pkt_info_data;
    reg  [  (MM_ADDR_WIDTH-1):0] rec_trig_addr;
    reg  [  (MM_ADDR_WIDTH-1):0] rec_start_addr;
    reg  [  (MM_ADDR_WIDTH-1):0] rec_end_addr;

    sample_core #(
        .MM_ADDR_WIDTH(MM_ADDR_WIDTH),
        .BIT_WIDTH    (BIT_WIDTH),
        .BLOCK_SIZE   (BLOCK_SIZE)
    ) sample_core_dut (
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
        .trig_out             (trig_out),
        .data                 (odata),
        .data_valid           (odata_valid),
        .m_axis_tvalid        (m_axis_tvalid),
        .m_axis_tdata         (m_axis_tdata),
        .m_axis_tlast         (m_axis_tlast),
        .m_axis_tready        (m_axis_tready),
        .pkt_info_wr          (pkt_info_wr),
        .pkt_info_data        (pkt_info_data),
        .rec_trig_addr        (rec_trig_addr),
        .rec_start_addr       (rec_start_addr),
        .rec_end_addr         (rec_end_addr)
    );

    initial begin
        begin
            config_start_addr     = 32'hC0000000;
            config_end_addr       = 32'hC0007fFF;
            config_sample_num     = 32'h00000040;
            config_pre_sample_num = 32'h00000000;
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
            wait (sample_done | sample_err);
            #1000;
            $finish;
        end
    end

    adc_data_generator #(
        .DIV           (1),
        .CHANNEL_NUM   (4),
        .ADC_BIT_NUM   (8),
        .OUTPUT_BIT_NUM(128)
    ) adc_data_generator_dut (
        .clk       (clk),
        .rstn      (rstn),
        .data      (idata),
        .data_valid(idata_valid)
    );

    trigger_generator #(
        .CHANNEL_NUM(4),
        .BIT_NUM(128)
    ) trigger_generator_dut (
        .clk        (clk),
        .rstn       (rstn),
        .trig_mask  (4'd1),
        .trig_level (128'd0),
        .idata      (idata),
        .idata_valid(idata_valid),
        .odata      (odata),
        .odata_valid(odata_valid),
        .trig       (sample_trig)
    );

    axis_checker #(
        .DATA_WIDTH(BIT_WIDTH)
    ) axis_checker_dut (
        .s_axis_aclk   (clk),
        .s_axis_aresetn(rstn),
        .s_axis_tvalid (m_axis_tvalid),
        .s_axis_tdata  (m_axis_tdata),
        .s_axis_tstrb  (m_axis_tstrb),
        .s_axis_tlast  (m_axis_tlast),
        .s_axis_tready (m_axis_tready)
    );

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
            $dumpvars(0, sample_core_tb);
        end
    end

endmodule


// verilog_format: off
`resetall
// verilog_format: on
