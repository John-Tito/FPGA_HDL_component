//---------------------------------------------------------------------------------------
// uart receive module
//
//---------------------------------------------------------------------------------------
// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on
module uart_rx (
    input  wire       clock,         // global clock input
    input  wire       reset,         // global reset input
    input  wire       sample_en,
    input  wire       ser_in,        // serial data input
    input  wire       rece_parity,
    input  wire       odd_even,
    output reg  [7:0] rx_data,       // data byte received
    output reg        rx_new_data,   // signs that a new byte was received
    output reg        parity_error,  //
    output reg        begin_error,
    output reg        end_error,     //
    output reg        rx_busy
);
    //---------------------------------------------------------------------------------------
    // modules inputs and outputs

    wire [3:0] data_length;
    // internal registers
    reg  [7:0] in_sync;
    reg        rx_start;
    reg  [3:0] bit_count;
    reg  [7:0] data_buf;
    reg        parity_bit_cal;
    reg        parity_bit_sav;

    assign data_length = (rece_parity) ? 4'd10 : 4'd9;

    // input async
    always @(posedge clock) begin
        if (reset) begin
            in_sync <= 8'hFF;
        end else begin
            in_sync <= {in_sync[6:0], ser_in};  // timing compensate, 7 clock delay for ser_in
        end
    end

    always @(posedge clock) begin
        if (reset) begin
            rx_start <= 1'b0;
        end else begin
            rx_start <= ~rx_busy & ~in_sync[0] & in_sync[1];
        end
    end

    // receiving busy flag
    always @(posedge clock) begin
        if (reset) begin
            rx_busy <= 1'b0;
        end else if (rx_start) begin
            rx_busy <= 1'b1;
        end else if (rx_busy & (bit_count == data_length) & sample_en) begin
            rx_busy <= 1'b0;  // rx finish
        end else if (rx_busy & (bit_count == 0) & sample_en & (in_sync[7] == 1'b1)) begin
            rx_busy <= 1'b0;  // first bit is not 0
        end
    end

    // bit counter
    always @(posedge clock) begin
        if (reset | rx_start | ~rx_busy) begin
            bit_count <= 4'h0;
        end else if (rx_busy & sample_en) begin
            if (bit_count == data_length) begin
                bit_count <= 4'h0;
            end else begin
                bit_count <= bit_count + 4'h1;
            end
        end
    end

    // data buffer shift register
    always @(posedge clock) begin
        if (reset | ~rx_busy) begin
            data_buf <= 8'h0;
        end else if (rx_busy & sample_en) begin
            if (bit_count <= 4'h8) begin
                data_buf <= {in_sync[7], data_buf[7:1]};
            end
        end
    end

    // data output and flag
    always @(posedge clock) begin
        if (reset) begin
            rx_data     <= 8'h0;
            rx_new_data <= 1'b0;
        end else if (rx_busy & (bit_count == data_length) & sample_en) begin
            rx_data     <= data_buf;
            rx_new_data <= 1'b1;
        end else begin
            rx_data     <= rx_data;
            rx_new_data <= 1'b0;
        end
    end

    // parity cal
    always @(posedge clock) begin
        if (reset) begin
            parity_bit_sav <= 8'h0;
            parity_bit_cal <= 8'h0;
        end else if (rx_busy & rece_parity) begin
            if (sample_en) begin
                if (bit_count <= 4'h8) begin
                    parity_bit_cal <= parity_bit_cal + in_sync[7];
                end else if (bit_count == 4'h9) begin
                    parity_bit_sav <= in_sync[7];
                end
            end
        end else begin
            parity_bit_sav <= 8'h0;
            parity_bit_cal <= 8'h0;
        end
    end

    // parity error check
    always @(posedge clock) begin
        if (reset) begin
            parity_error <= 1'b0;
        end else if (rx_busy & rece_parity) begin
            if (sample_en) begin
                if (bit_count >= data_length) begin
                    parity_error <= (odd_even ^ (parity_bit_sav ^ parity_bit_cal));
                end
            end
        end else begin
            parity_error <= 0;
        end
    end

    // begin_error check
    always @(posedge clock) begin
        if (reset) begin
            begin_error <= 1'b0;
        end else if (rx_busy & (bit_count == 0) & sample_en & in_sync[7]) begin
            begin_error <= 1'b1;
        end else begin_error <= 1'b0;
    end

    // end_error check
    always @(posedge clock) begin
        if (reset) begin
            end_error <= 1'b0;
        end else if (rx_busy & (bit_count == data_length) & sample_en & ~in_sync[7]) begin
            end_error <= 1'b1;
        end else end_error <= 1'b0;
    end

endmodule
//---------------------------------------------------------------------------------------
//                        Th.. Th.. Th.. Thats all folks !!!
//---------------------------------------------------------------------------------------
