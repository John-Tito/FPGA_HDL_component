// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module uart_rx_clk_gen #(
    parameter CPOL = 1'b0,
    parameter CPHA = 1'b0
) (
    input  wire        clk,          //
    input  wire        rst,          //
    input  wire        en,           //
    input  wire [11:0] baud_freq,    //
    input  wire [15:0] baud_limit,   //
    input  wire        sync_mode,    //
    output reg         sample_en,
    output reg         sample_clr,
    input  wire        ext_sync_clk  //
);
    // ***********************************************************************************
    // internal clock for receive
    // ***********************************************************************************
    reg [15:0] counter;
    reg [ 3:0] count16;
    reg        ce_16;
    reg        int_sync_clk = 1'b0;
    // baud divider counter
    always @(posedge clk) begin
        if (rst | sync_mode | !en) begin
            counter <= 16'b0;
        end else if (counter >= baud_limit) begin
            counter <= counter - baud_limit;
        end else begin
            counter <= counter + {4'h0, baud_freq};
        end
    end

    // clock divider output
    always @(posedge clk) begin
        if (rst | sync_mode | !en) begin
            ce_16 <= 1'b0;
        end else if (counter >= baud_limit) begin
            ce_16 <= 1'b1;
        end else begin
            ce_16 <= 1'b0;
        end
    end

    // ce_16 divider output
    always @(posedge clk) begin
        if (rst | sync_mode | !en) begin
            count16 <= 4'b0;
        end else if (ce_16) begin
            count16 <= count16 + 4'h1;
        end
    end


    // CPOL = 0
    // ____/ ̅ ̅ ̅ ̅ ̅ ̅  \_______
    // CPHA = 0
    //     |sample  |clr
    // CPHA = 1
    //     |clr     |sample

    // CPOL = 1
    //  ̅ ̅ ̅ ̅ ̅  \_____/ ̅ ̅ ̅ ̅ ̅ ̅
    // CPHA = 0
    //     |sample  |clr
    // CPHA = 1
    //     |clr     |sample

    always @(posedge clk) begin
        if (rst | sync_mode | !en) begin
            int_sync_clk <= CPOL;
        end else begin
            if (ce_16) begin
                if (count16 < 8) begin
                    int_sync_clk <= ~CPOL;
                end else begin
                    int_sync_clk <= CPOL;
                end
            end
        end
    end

    // ***********************************************************************************
    // rx enable strobe
    // ***********************************************************************************
    reg  [2:0] sync_clk_dd = {3{CPOL}};
    wire       pedge;
    wire       nedge;
    wire       rx_clk;
    wire       SampleStart;

    // latch rx clock to shift register
    always @(posedge clk) begin
        if (rst || !en) begin
            sync_clk_dd <= {3{CPOL}};
        end else begin
            sync_clk_dd <= {sync_clk_dd[1:0], ((sync_mode) ? ext_sync_clk : int_sync_clk)};
        end
    end

    // edge detect
    assign pedge = (sync_clk_dd[0]) & ~sync_clk_dd[1];
    assign nedge = (sync_clk_dd[1]) & ~sync_clk_dd[0];

    always @(posedge clk) begin
        if (rst || !en) begin
            sample_en  <= 1'b0;
            sample_clr <= 1'b0;
        end else begin
            sample_en  <= ((CPOL ^ CPHA) ? nedge : pedge);
            sample_clr <= ((CPOL ^ CPHA) ? pedge : nedge);
        end
    end
endmodule

// verilog_format: off
`resetall
// verilog_format: on
