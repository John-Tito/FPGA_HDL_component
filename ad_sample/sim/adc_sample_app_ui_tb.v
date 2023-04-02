// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on
module adc_sample_app_ui_tb;

    // Parameters
    localparam real TIMEPERIOD = 5;
    localparam integer MM_ADDR_WIDTH = 32;
    localparam integer S_AXI_DATA_WIDTH = 32;
    localparam integer S_AXI_ADDR_WIDTH = 16;

    // Ports
    reg                         clk = 0;
    reg                         rstn = 0;
    reg                         app_axi_rreq = 0;
    wire                        app_axi_rack;
    reg  [S_AXI_ADDR_WIDTH-1:0] app_axi_raddr = 0;
    wire [S_AXI_DATA_WIDTH-1:0] app_axi_rdata;
    reg                         app_axi_wreq = 0;
    wire                        app_axi_wack;
    reg  [S_AXI_ADDR_WIDTH-1:0] app_axi_waddr = 0;
    reg  [S_AXI_DATA_WIDTH-1:0] app_axi_wdata = 0;
    wire                        sample_start;
    wire                        sample_trig;
    wire                        update_config;
    reg                         sample_busy = 0;
    reg                         sample_done = 0;
    reg                         sample_err = 0;
    wire                        move_en;
    reg                         move_busy = 0;
    reg                         move_err = 0;
    reg                         move_done = 0;
    reg  [   MM_ADDR_WIDTH-1:0] move_addr = 0;
    reg  [ (MM_ADDR_WIDTH-1):0] rec_trig_addr = 0;
    reg  [ (MM_ADDR_WIDTH-1):0] rec_start_addr = 0;
    reg  [ (MM_ADDR_WIDTH-1):0] rec_end_addr = 0;

    task app_rd;
        input [S_AXI_ADDR_WIDTH-1:0] raddr;

        app_axi_raddr <= 0;
        app_axi_rreq  <= 1'b0;
        @(posedge clk);
        app_axi_raddr <= raddr;
        app_axi_rreq  <= 1'b1;
        @(posedge clk);
        app_axi_raddr <= raddr;
        app_axi_rreq  <= 1'b0;
        wait (app_axi_rack);
        app_axi_raddr <= 0;
        app_axi_rreq  <= 1'b0;
        @(posedge clk);
    endtask

    task app_wr;
        // input clk;
        input [S_AXI_ADDR_WIDTH-1:0] waddr;
        input [S_AXI_DATA_WIDTH-1:0] wdata;

        app_axi_waddr <= 0;
        app_axi_wdata <= 0;
        app_axi_wreq  <= 1'b0;
        @(posedge clk);
        app_axi_waddr <= waddr;
        app_axi_wdata <= wdata;
        app_axi_wreq  <= 1'b1;
        @(posedge clk);
        app_axi_wreq  <= 1'b0;
        app_axi_waddr <= waddr;
        app_axi_wdata <= wdata;
        wait (app_axi_wack);
        app_axi_wreq  <= 1'b0;
        app_axi_waddr <= 0;
        app_axi_wdata <= 0;
        @(posedge clk);
    endtask

    adc_sample_app_ui #(
        .MM_ADDR_WIDTH   (MM_ADDR_WIDTH),
        .S_AXI_DATA_WIDTH(S_AXI_DATA_WIDTH),
        .S_AXI_ADDR_WIDTH(S_AXI_ADDR_WIDTH)
    ) adc_sample_app_ui_dut (
        .clk           (clk),
        .rstn          (rstn),
        .app_axi_rreq  (app_axi_rreq),
        .app_axi_rack  (app_axi_rack),
        .app_axi_raddr (app_axi_raddr),
        .app_axi_rdata (app_axi_rdata),
        .app_axi_wreq  (app_axi_wreq),
        .app_axi_wack  (app_axi_wack),
        .app_axi_waddr (app_axi_waddr),
        .app_axi_wdata (app_axi_wdata),
        .sample_start  (sample_start),
        .sample_trig   (sample_trig),
        .update_config (update_config),
        .sample_busy   (sample_busy),
        .sample_done   (sample_done),
        .sample_err    (sample_err),
        .move_en       (move_en),
        .move_busy     (move_busy),
        .move_err      (move_err),
        .move_done     (move_done),
        .move_addr     (move_addr),
        .rec_trig_addr (rec_trig_addr),
        .rec_start_addr(rec_start_addr),
        .rec_end_addr  (rec_end_addr)
    );

    initial begin
        begin
            wait (rstn);
            app_wr(16'd0, 32'h00000000);
            app_rd(16'd0);

            app_wr(16'd4, 32'hC0000000);
            app_rd(16'd4);

            app_wr(16'd8, 32'hC0007FFF);
            app_rd(16'd8);

            app_wr(16'd12, 32'h00000080);
            app_rd(16'd12);

            app_wr(16'd16, 32'h00000040);
            app_rd(16'd16);


            app_wr(16'd32, 32'h00000001);
            app_rd(16'd32);

            app_wr(16'd40, 32'h00000001);
            app_rd(16'd40);

            app_wr(16'd44, 32'h00000001);
            app_rd(16'd44);

            app_wr(16'd36, 32'h00000001);
            app_rd(16'd36);

            #100;
            app_rd(16'd64);
            #100;
            app_wr(16'd64, app_axi_rdata);
        end
    end

    initial begin
        begin
            wait (rstn);
            #50;
            sample_err <= 1'b1;
            // #20;
            // sample_err <= 1'b0;
        end
    end

    initial begin
        begin
            wait (rstn);
            #50;
            sample_done <= 1'b1;
            // #40;
            // sample_done <= 1'b0;
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
            $dumpvars(0, adc_sample_app_ui_tb);
        end
    end


endmodule

// verilog_format: off
`resetall
// verilog_format: on
