// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module ad574_timing_tb;

    // Parameters
    localparam real TIMEPERIOD = 10;
    localparam integer IN_CLK_FREQ = 100_000_000;

    // Ports
    reg         clk = 0;
    reg         rstn = 0;
    wire        AO;
    wire        S12_8n;
    wire        CE;
    wire        RCn;
    reg         STS = 0;
    reg  [11:0] DB = 0;

    ad574_top #(
        .IN_CLK_FREQ(IN_CLK_FREQ)
    ) ad574_top_dut (
        .clk       (clk),
        .rstn      (rstn),
        .data      (),
        .data_valid(),
        .AO        (AO),
        .S12_8n    (S12_8n),
        .CE        (CE),
        .RCn       (RCn),
        .STS       (STS),
        .DB        (DB)
    );

    initial begin
        begin
            wait (rstn);
            #10000;
            $finish;
        end
    end

    // always @(posedge clk) begin
    //     if (!rstn) begin
    //         DB <= 0;
    //     end else begin
    //         if (CE & ~RCn) begin
    //             DB <= DB + 1;
    //         end
    //     end
    // end

    always begin
        DB <= 0;
        wait (rstn);
        while (1) begin
            wait (CE & ~RCn);
            DB <= DB + 1;
            wait (!CE);
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
            $dumpvars(0, ad574_timing_tb);
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
