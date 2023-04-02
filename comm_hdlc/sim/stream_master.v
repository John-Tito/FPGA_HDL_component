// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module stream_master #(
    parameter TBYTE_NUM = 16
) (
    input wire clk,  //
    input wire rstn, //

    input wire [              4 : 0] pkt_dest,    //
    input wire [               31:0] pkt_gap,     //
    input wire [               31:0] pkt_len,     //
    input wire [               31:0] trans_len,   //
    input wire [(TBYTE_NUM*8-1) : 0] start_from,  //
    input wire [(TBYTE_NUM*8-1) : 0] inc,         //
    input wire                       fix,         //

    input  wire stream_start,  //
    output reg  stream_busy,   //

    output reg                        m_axis_tvalid,
    input  wire                       m_axis_tready,
    output reg  [(TBYTE_NUM*8-1) : 0] m_axis_tdata,
    output reg  [  (TBYTE_NUM-1) : 0] m_axis_tkeep,
    output wire                       m_axis_tlast,
    output reg  [              4 : 0] m_axis_tid,
    output reg  [              4 : 0] m_axis_tdest
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

    assign active    = m_axis_tready & m_axis_tvalid;
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

    always @(posedge clk) begin
        if (!rstn) begin
            m_axis_tvalid <= 1'b0;
        end else begin
            case (n_state)
                FSM_PKT: begin
                    m_axis_tvalid <= 1'b1;
                end
                default: begin
                    m_axis_tvalid <= 1'b0;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            m_axis_tdata <= start_from;
        end else begin
            case (n_state)
                FSM_PKT: begin
                    if (fix) begin
                        m_axis_tdata <= start_from;
                    end else begin
                        if (active) begin
                            m_axis_tdata <= m_axis_tdata + inc;
                        end else begin
                            m_axis_tdata <= m_axis_tdata;
                        end
                    end
                end
                default: begin
                    m_axis_tdata <= start_from;
                end
            endcase
        end
    end

    assign m_axis_tlast = trans_end;
    // always @(posedge clk) begin
    //     if (!rstn) begin
    //         m_axis_tlast <= 1'b0;
    //     end else begin
    //         case (n_state)
    //             FSM_PREPARE: begin
    //                 m_axis_tlast <= 1'b0;
    //             end
    //             default: begin

    //             end
    //         endcase
    //     end
    // end

    always @(posedge clk) begin
        if (!rstn) begin
            m_axis_tid <= 0;
        end else begin
            case (n_state)
                FSM_PREPARE: begin
                    m_axis_tid <= 0;
                end
                FSM_PKT: begin
                    if (trans_end & active) begin
                        m_axis_tid <= m_axis_tid + 1;
                    end
                end
                default: begin
                    m_axis_tid <= m_axis_tid;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            m_axis_tdest <= 0;
        end else begin
            case (n_state)
                FSM_PREPARE: begin
                    m_axis_tdest <= pkt_dest;
                end
                default: begin
                    m_axis_tdest <= m_axis_tdest;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            m_axis_tkeep <= 0;
        end else begin
            m_axis_tkeep <= 16'hffff;
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
