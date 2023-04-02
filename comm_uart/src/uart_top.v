//---------------------------------------------------------------------------------------
// uart top level module
//****Downloaded from opencores.org, edited by zou
//---------------------------------------------------------------------------------------
// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on
module uart_top (
    input wire clock,
    input wire reset,

    input  wire        loopback,
    input  wire [11:0] baud_freq,
    input  wire [15:0] baud_limit,
    output wire        baud_clk,
    input  wire [ 3:0] recv_parity,

    input  wire [7:0] tx_data,
    input  wire       tx_new_data,
    output wire       tx_busy,

    output wire [7:0] rx_data,
    output wire       rx_new_data,
    output wire       rx_parity_error,  //
    output wire       rx_begin_error,
    output wire       rx_end_error,     //
    output wire       rx_busy,

    input  wire ser_in,
    output wire ser_out
);
    //---------------------------------------------------------------------------------------
    // modules inputs and outputs

    // internal wires
    wire ce_16;  // clock enable at bit rate
    wire send_parity;
    wire rece_parity;
    wire t_odd_even;
    wire r_odd_even;
    reg  rxd_mux_out;

    assign baud_clk    = ce_16;
    assign send_parity = recv_parity[3];
    assign rece_parity = recv_parity[2];
    assign t_odd_even  = recv_parity[1];
    assign r_odd_even  = recv_parity[0];


    //---------------------------------------------------------------------------------------
    // module implementation
    // baud rate generator module
    //****baud_freq  = 16*BaudRate / GCD(GlobalClkFreq,16*BaudRate)
    //****baud_limit = (GlobalClkFreq / GCD(GlobalClkFreq,16*BaudRate)) - baud_freq
    //  ( 115200 baud on 40MHz clock )
    //        `define baud_freq            12'h90
    //        `define baud_limit        16'h0ba5
    //  ( 19200 baud on 40MHz clock )
    //        `define baud_freq            12'h18
    //        `define baud_limit        16'h0C1D
    //

    //// baud rate generator parameters for 115200 baud on 40MHz clock
    ////`define D_BAUD_FREQ            12'h90
    ////`define D_BAUD_LIMIT        16'h0ba5
    //// baud rate generator parameters for 115200 baud on 44MHz clock
    ////`define D_BAUD_FREQ            12'd23
    ////`define D_BAUD_LIMIT        16'd527
    //// baud rate generator parameters for 9600 baud on 66MHz clock
    ////`define D_BAUD_FREQ            12'h10
    ////`define D_BAUD_LIMIT        16'h1ACB

    // uart transmitter
    uart_tx inst_uart_tx (
        .clock      (clock),
        .reset      (reset),
        .ce_16      (ce_16),
        .tx_data    (tx_data),
        .tx_new_data(tx_new_data),
        .send_parity(send_parity),
        .odd_even   (t_odd_even),
        .ser_out    (ser_out),
        .tx_busy    (tx_busy)
    );

    wire sample_en;
    wire sample_clr;
    // uart receiver
    uart_rx inst_uart_rx (
        .clock       (clock),
        .reset       (reset),
        .sample_en   (sample_en),
        .ser_in      (rxd_mux_out),
        .rece_parity (rece_parity),
        .odd_even    (r_odd_even),
        .rx_data     (rx_data),
        .rx_new_data (rx_new_data),
        .rx_busy     (rx_busy),
        .parity_error(rx_parity_error),
        .begin_error (rx_begin_error),
        .end_error   (rx_end_error)
    );

    uart_rx_clk_gen #(
        .CPOL(1'b0),
        .CPHA(1'b1)
    ) uart_rx_clk_gen_inst (
        .clk         (clock),
        .rst         (reset),
        .en          (rx_busy),
        .baud_freq   (baud_freq),
        .baud_limit  (baud_limit),
        .sync_mode   (1'b0),
        .sample_en   (sample_en),
        .sample_clr  (),
        .ext_sync_clk(1'b0)
    );

    baud_gen inst_baud_gen (
        .clock     (clock),
        .reset     (reset),
        .baud_freq (baud_freq),
        .baud_limit(baud_limit),
        .ce_16     (ce_16)
    );

    always @(posedge clock) begin
        if (reset) begin
            rxd_mux_out <= 1'b1;
        end else begin
            rxd_mux_out <= (loopback == 1'b1) ? ser_out : ser_in;
        end
    end

endmodule
//---------------------------------------------------------------------------------------
//                        Th.. Th.. Th.. Thats all folks !!!
//---------------------------------------------------------------------------------------
