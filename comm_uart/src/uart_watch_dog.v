
// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module uart_watch_dog (
    input  wire        clk,         // clock input
    input  wire        rstn,        // low active sync reset input
    input  wire        en,          // high active enable control input
    input  wire [31:0] preset,      // 31 bit preset value input for internal downward counter
    input  wire        monitor_in,  // monitor input, this signal will resets internal downward counter to input preset value
    input  wire        cnt_pulse,   // count pulse input for internal downward counter
    output reg         state,       // state signal that shows if monitor input is active
    output reg         active,      // pulse that shows monitor input changed from inactive to active
    output reg         inactive     // pulse that shows monitor input changed from active to inactive
);
    reg [31:0] cnt = 32'd320;
    always @(posedge clk) begin
        if (~rstn | monitor_in | ~state | ~en) begin
            cnt <= preset;
        end else begin
            if (cnt_pulse) begin
                if (cnt > 0) begin
                    cnt <= cnt - 1;
                end else begin
                    cnt <= cnt;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (~rstn | ~en) begin
            state <= monitor_in;
        end else begin
            if (monitor_in == 1'b1) begin
                state <= 1'b1;
            end else begin
                if (state) begin
                    if (cnt > 0) begin
                        state <= 1'b1;
                    end else begin
                        state <= 1'b0;
                    end
                end else begin
                    state <= 1'b0;
                end
            end
        end
    end

    reg [1:0] state_dd;
    always @(posedge clk) begin
        if (~rstn | ~en) begin
            state_dd <= 2'b0;
        end else begin
            state_dd <= {state_dd[0], state};
        end
    end

    always @(posedge clk) begin
        if (~rstn | ~en) begin
            active   <= 1'b0;
            inactive <= 1'b0;
        end else begin
            active   <= state_dd[0] & ~state_dd[1];
            inactive <= state_dd[1] & ~state_dd[0];
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
