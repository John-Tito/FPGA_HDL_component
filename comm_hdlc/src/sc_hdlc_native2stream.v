// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module sc_hdlc_native2stream (
    input wire clk,

    input wire [4:0] tdest,  //

    input  wire [7:0] s_axis_tdata,
    input  wire       s_axis_tvalid,
    output wire       s_axis_tready,
    input  wire       s_axis_tlast,
    input  wire       s_axis_tkeep,
    input  wire [4:0] s_axis_tid,
    input  wire [4:0] s_axis_tdest,
    input  wire [0:0] s_axis_tuser,

    output reg  [7:0] m_axis_tdata,     //
    output reg        m_axis_tvalid,    //
    input  wire       m_axis_tready,    //
    output reg        m_axis_tlast,     //
    output reg        m_axis_tkeep,
    output reg  [4:0] m_axis_tid,
    output reg  [4:0] m_axis_tdest,
    output wire [0:0] m_axis_tuser,
    //
    input  wire       tx_rstn,
    input  wire       tx_input_req,
    input  wire       tx_busy,
    input  wire       tx_flag,
    output reg        tx_start = 1'b0,
    output reg        tx_empty = 1'b1,
    output reg  [7:0] tx_data = 0,

    input  wire        rx_rstn,
    input  wire        rx_start,        //
    input  wire        rx_end,
    input  wire        rx_abort,
    input  wire        rx_error,
    input  wire [ 7:0] rx_data,
    input  wire        rx_dvalid,
    //
    output wire [31:0] pkt_length,
    output wire        pkt_length_push,

    input wire data_afull,  //
    input wire pkt_afull    //
);

    localparam [2:0] FSM_IDLE = 3'b000;
    localparam [2:0] FSM_ACTIVE = 3'b001;
    localparam [2:0] FSM_INACTIVE = 3'b010;

    reg  [ 2:0] c_state;
    reg  [ 2:0] n_state;
    reg  [31:0] rx_length;
    reg  [39:0] pkt_info;
    reg  [ 4:0] pkt_end_dd;

    wire        tx_active;
    wire        rx_active;

    reg  [31:0] data_lost_cnt;

    always @(posedge clk) begin
        if (!rx_rstn) begin
            c_state <= FSM_IDLE;
        end else begin
            c_state <= n_state;
        end
    end

    always @(*) begin
        case (c_state)
            FSM_IDLE: begin
                if (rx_start & ~data_afull & ~pkt_afull) begin
                    n_state = FSM_ACTIVE;
                end else begin
                    n_state = FSM_IDLE;
                end
            end
            FSM_ACTIVE: begin
                if (pkt_length_push) begin
                    n_state = FSM_IDLE;
                end else begin
                    n_state = FSM_ACTIVE;
                end
            end
            default: n_state = FSM_IDLE;
        endcase
    end


    assign tx_active       = s_axis_tvalid & s_axis_tready;
    assign rx_active       = m_axis_tvalid & m_axis_tready;
    assign m_axis_tuser    = 0;
    assign s_axis_tready   = tx_input_req;

    assign pkt_length_push = rx_active & m_axis_tlast;
    assign pkt_length      = pkt_info[31:0];

    always @(posedge clk) begin
        if (!rx_rstn) begin
            pkt_end_dd <= 0;
            pkt_info   <= 0;
        end else begin
            pkt_end_dd <= {pkt_end_dd[3:0], rx_abort | rx_end};
            if (rx_abort | rx_end) begin
                pkt_info <= {5'b0, rx_abort, rx_end, rx_error | (|(data_lost_cnt)), rx_length[30:0] + 31'd5};
            end
        end
    end

    // ***************************************************************************************
    // rx stream
    // ***************************************************************************************
    always @(posedge clk) begin
        if (!rx_rstn) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 8'h00;
            m_axis_tlast  <= 1'b0;
            m_axis_tkeep  <= 1'b0;
            m_axis_tdest  <= tdest;
            m_axis_tid    <= 5'h00;
        end else begin
            m_axis_tdest <= tdest;
            case (n_state)
                FSM_ACTIVE: begin
                    if (pkt_end_dd) begin
                        case (pkt_end_dd)
                            5'b00001: m_axis_tdata <= pkt_info[4*8+:8];
                            5'b00010: m_axis_tdata <= pkt_info[3*8+:8];
                            5'b00100: m_axis_tdata <= pkt_info[2*8+:8];
                            5'b01000: m_axis_tdata <= pkt_info[1*8+:8];
                            5'b10000: m_axis_tdata <= pkt_info[0*8+:8];
                            default:  m_axis_tdata <= 0;
                        endcase
                        m_axis_tvalid <= 1'b1;
                        m_axis_tlast  <= (pkt_end_dd == 5'b10000) ? 1'b1 : 1'b0;
                        m_axis_tkeep  <= 1'b1;
                        m_axis_tid    <= m_axis_tid;
                    end else if (rx_dvalid) begin
                        m_axis_tvalid <= ~(data_afull);
                        m_axis_tdata  <= rx_data;
                        m_axis_tlast  <= 1'b0;
                        m_axis_tkeep  <= 1'b1;
                        m_axis_tid    <= m_axis_tid;
                    end else if (rx_active) begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tdata  <= 8'h00;
                        m_axis_tlast  <= 1'b0;
                        m_axis_tkeep  <= 1'b0;
                        m_axis_tid    <= (m_axis_tlast) ? (m_axis_tid + 1) : m_axis_tid;
                    end else begin
                        m_axis_tvalid <= m_axis_tvalid;
                        m_axis_tdata  <= m_axis_tdata;
                        m_axis_tlast  <= m_axis_tlast;
                        m_axis_tkeep  <= m_axis_tkeep;
                        m_axis_tid    <= m_axis_tid;
                    end
                end
                default: begin
                    m_axis_tvalid <= 1'b0;
                    m_axis_tdata  <= 8'h00;
                    m_axis_tlast  <= 1'b0;
                    m_axis_tkeep  <= 1'b0;
                    m_axis_tid    <= 5'h00;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rx_rstn) begin
            rx_length <= 0;
        end else begin
            if (rx_active & m_axis_tlast) begin
                rx_length <= 0;
            end else if (rx_active) begin
                if (rx_length < 32'hFFFFFFFF) begin
                    rx_length <= rx_length + 1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (!rx_rstn) begin
            data_lost_cnt <= 0;
        end else begin
            if (rx_active & m_axis_tlast) begin
                data_lost_cnt <= 0;
            end else if (rx_dvalid & data_afull) begin
                if (data_lost_cnt < 32'hFFFFFFFF) begin
                    data_lost_cnt <= data_lost_cnt + 1;
                end
            end
        end
    end

    // ***************************************************************************************
    // tx stream
    // ***************************************************************************************
    always @(posedge clk) begin
        if (!tx_rstn) begin
            tx_empty <= 1'b1;
        end else begin
            if (s_axis_tlast & tx_active) begin
                tx_empty <= 1'b1;
            end else if (tx_flag || tx_start) begin
                tx_empty <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (!tx_rstn) begin
            tx_data <= 0;
        end else begin
            if (tx_active) begin
                tx_data <= s_axis_tdata;
            end
        end
    end

    always @(posedge clk) begin
        if (!tx_rstn) begin
            tx_start <= 1'b0;
        end else begin
            tx_start <= ~tx_empty & tx_flag & s_axis_tvalid & ~tx_busy;
        end
    end


endmodule

// verilog_format: off
`resetall
// verilog_format: on
