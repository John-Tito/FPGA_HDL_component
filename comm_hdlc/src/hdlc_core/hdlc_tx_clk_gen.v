// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module hdlc_tx_clk_gen #(
    parameter CPOL = 1'b1,
    parameter CPHA = 1'b1
) (
    input  wire        clk,         // clock
    input  wire        rstn,        // active low reset
    input  wire        en,          //
    input  wire        load,        //
    input  wire [11:0] baud_freq,   //
    input  wire [15:0] baud_limit,  //
    output reg         shift_en,    //
    output wire        sync_clk     //
);
    reg        en_reg;
    reg [11:0] baud_freq_reg;
    reg [15:0] baud_limit_reg;

    // ***********************************************************************************
    // config register
    // ***********************************************************************************
    always @(posedge clk) begin
        if (!rstn) begin
            baud_freq_reg  <= 4;
            baud_limit_reg <= 1;
        end else if (load) begin
            if (baud_freq > 0 && baud_limit > 0) begin
                baud_freq_reg  <= baud_freq;
                baud_limit_reg <= baud_limit;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            en_reg <= 1'b0;
        end else begin
            if (en) begin
                en_reg <= 1'b1;
            end else if (CPOL == sync_clk) begin
                en_reg <= 1'b0;
            end
        end
    end

    // ***********************************************************************************
    // internal clock for transmit
    // ***********************************************************************************
    reg [15:0] counter;
    reg [ 3:0] count16;
    reg        ce_16;
    reg        int_sync_clk = 1'b0;
    // baud divider counter
    always @(posedge clk) begin
        if (!rstn) begin
            counter <= 16'b0;
        end else if (counter >= baud_limit_reg) begin
            counter <= counter - baud_limit_reg;
        end else begin
            counter <= counter + {4'h0, baud_freq_reg};
        end
    end

    // clk divider output
    always @(posedge clk) begin
        if (!rstn) begin
            ce_16 <= 1'b0;
        end else if (counter >= baud_limit_reg) begin
            ce_16 <= 1'b1;
        end else begin
            ce_16 <= 1'b0;
        end
    end

    // ce_16 divider output
    always @(posedge clk) begin
        if (!rstn) count16 <= 4'b0;
        else if (en_reg == 1'b1) begin
            if (ce_16) begin
                count16 <= count16 + 4'h1;
            end
        end else begin
            count16 <= 4'b0;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            int_sync_clk <= 1'b0;
        end else begin
            if (ce_16) begin
                if (count16 < 8) begin
                    int_sync_clk <= 1'b0;
                end else begin
                    int_sync_clk <= 1'b1;
                end
            end
        end
    end

    // ***********************************************************************************
    // tx enable strobe
    // ***********************************************************************************
    reg [1:0] sync_clk_dd;
    always @(posedge clk) begin
        if (!rstn || !en_reg) begin
            sync_clk_dd <= 2'b00;
        end else begin
            sync_clk_dd <= {sync_clk_dd[0], int_sync_clk};
        end
    end

    always @(posedge clk) begin
        if (!rstn || !en_reg) begin
            shift_en <= 1'b0;
        end else begin
            if ((sync_clk_dd[0] & (~sync_clk_dd[1]))) begin
                shift_en <= 1'b1;
            end else begin
                shift_en <= 1'b0;
            end
        end
    end

    // ***********************************************************************************
    // sync clk for output
    // ***********************************************************************************
    reg [1:0] sync_clk_d = {2{CPOL}};
    generate
        always @(posedge clk) begin
            if (!rstn || !en_reg) begin
                sync_clk_d <= {2{CPOL}};
            end else if (^sync_clk_dd) begin
                sync_clk_d <= {sync_clk_d[0], int_sync_clk ^ CPOL};
            end
        end
        if (CPHA == 1'b0) begin : g_cpha0
            assign sync_clk = sync_clk_d[1];
        end else begin : g_cpha1
            assign sync_clk = sync_clk_d[0];
        end
    endgenerate

endmodule

// verilog_format: off
`resetall
// verilog_format: on
