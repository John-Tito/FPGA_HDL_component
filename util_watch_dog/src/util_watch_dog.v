
// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module util_watch_dog (
    input  wire        clk,
    input  wire        rstn,
    input  wire        en,          //
    input  wire [31:0] preset,      //
    input  wire        monitor_in,  //
    input  wire        cnt_pulse,   //
    output reg         state,       //
    output reg         active,      //
    output reg         inactive     //
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
