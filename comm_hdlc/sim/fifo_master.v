// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module fifo_master #(
    parameter TBYTE_NUM = 16
) (
    input wire clk,  //
    input wire rstn, //

    input wire [               31:0] pkt_gap,     //
    input wire [               31:0] pkt_len,     //
    input wire [               31:0] trans_len,   //
    input wire [(TBYTE_NUM*8-1) : 0] start_from,  //
    input wire [(TBYTE_NUM*8-1) : 0] inc,         //
    input wire                       fix,         //

    input  wire stream_start,  //
    output reg  stream_busy,   //

    input  wire                       fifo_rd,     //
    output reg                        fifo_empty,  //
    output reg  [(TBYTE_NUM*8-1) : 0] fifo_dout    //
);

    localparam FSM_IDLE = 8'h0;
    localparam FSM_PREPARE = 8'h1;
    localparam FSM_PKT = 8'h2;
    localparam FSM_GAP = 8'h4;
    localparam FSM_END = 8'h8;

    reg  [31:0] pkt_cnt;
    wire        pkt_end;

    reg  [31:0] trans_cnt;
    wire        trans_end;

    reg  [31:0] gap_cnt;
    wire        gap_end;

    reg  [ 7:0] c_state;
    reg  [ 7:0] n_state;

    wire        active;

    assign active    = ~fifo_empty & fifo_rd;
    assign trans_end = (trans_cnt == (trans_len - 1)) ? 1'b1 : 1'b0;
    assign pkt_end   = (pkt_cnt == (pkt_len - 1)) ? 1'b1 : 1'b0;
    assign gap_end   = (gap_cnt == (pkt_gap - 1)) ? 1'b1 : 1'b0;

    always @(posedge clk) begin
        if (!rstn) begin
            c_state <= FSM_IDLE;
        end else begin
            c_state <= n_state;
        end
    end

    always @(*) begin
        if (!rstn) begin
            n_state = FSM_IDLE;
        end else begin
            case (c_state)
                FSM_IDLE: begin
                    if (stream_start) begin
                        n_state = FSM_PREPARE;
                    end else begin
                        n_state = FSM_IDLE;
                    end
                end
                FSM_PREPARE: begin
                    n_state = FSM_PKT;
                end
                FSM_PKT: begin
                    if (trans_end & active) begin
                        n_state = FSM_GAP;
                    end else begin
                        n_state = FSM_PKT;
                    end
                end
                FSM_GAP: begin
                    if (gap_end) begin
                        if (pkt_end) begin
                            n_state = FSM_END;
                        end else begin
                            n_state = FSM_PKT;
                        end
                    end else begin
                        n_state = FSM_GAP;
                    end
                end
                default: n_state = FSM_IDLE;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            trans_cnt <= 0;
        end else begin
            case (n_state)
                FSM_PKT: begin
                    if (active) begin
                        trans_cnt <= trans_cnt + 1;
                    end
                end
                default: begin
                    trans_cnt <= 0;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            pkt_cnt <= 0;
        end else begin
            case (n_state)
                FSM_PREPARE: begin
                    pkt_cnt <= 0;
                end
                default: begin
                    if (gap_end) begin
                        pkt_cnt <= pkt_cnt + 1;
                    end else begin
                        pkt_cnt <= pkt_cnt;
                    end
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            gap_cnt <= 0;
        end else begin
            case (n_state)
                FSM_GAP: begin
                    gap_cnt <= gap_cnt + 1;
                end
                default: begin
                    gap_cnt <= 0;
                end
            endcase
        end
    end

    reg [(TBYTE_NUM*8-1) : 0] dout;
    always @(posedge clk) begin
        if (!rstn) begin
            dout <= start_from;
        end else begin
            case (n_state)
                FSM_PKT: begin
                    if (fix) begin
                        dout <= start_from;
                    end else begin
                        if (active) begin
                            dout <= dout + inc;
                        end else begin
                            dout <= dout;
                        end
                    end
                end
                default: begin
                    dout <= start_from;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            fifo_dout <= start_from;
        end else begin
            if (active) begin
                fifo_dout <= dout;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            fifo_empty <= 1'b1;
        end else begin
            case (n_state)
                FSM_PKT: begin
                    fifo_empty <= 1'b0;
                end
                default: begin
                    fifo_empty <= 1'b1;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            stream_busy <= 1'b1;
        end else begin
            case (n_state)
                FSM_IDLE: begin
                    stream_busy <= 1'b0;
                end
                default: begin
                    stream_busy <= 1'b1;
                end
            endcase
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
