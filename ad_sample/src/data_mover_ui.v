// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module data_mover_ui #(
    parameter MM_ADDR_WIDTH = 32,
    parameter BLOCK_SIZE    = 512
) (
    input  wire                          clk,
    input  wire                          rstn,
    //
    input  wire                          pkt_info_empty,  //
    input  wire [                  95:0] pkt_info_data,   //
    output reg                           pkt_info_rd,     //
    //
    input  wire                          fifo_afull,      // 发送缓冲区剩余空间不足
    //
    input  wire                          cmd_tready,
    output reg                           cmd_tvalid,
    output reg  [(MM_ADDR_WIDTH+39) : 0] cmd_tdata,
    //
    input  wire                          sts_err,
    input  wire                          sts_tvalid,
    input  wire [                 7 : 0] sts_tdata,
    input  wire                          sts_tkeep,
    input  wire                          sts_tlast,
    output reg                           sts_tready,
    //
    input  wire                          move_en,         //
    output reg  [                63 : 0] move_addr,       // 当前读地址
    output reg                           move_busy,       //
    output reg                           move_err,        //
    output wire                          move_done        //
);

    localparam FSM_IDLE = 8'h01;
    localparam FSM_START = 8'h02;
    localparam FSM_PRE_WAIT = 8'h04;
    localparam FSM_MOVE_UPDATE = 8'h08;
    localparam FSM_MOVE_CMD = 8'h10;
    localparam FSM_POST_WAIT = 8'h20;

    reg  [   7:0] c_state;
    reg  [   7:0] n_state;

    //
    wire [31 : 0] move_length;  // 数据包长度
    wire [  63:0] move_staddr;  // 数据包开始地址

    reg  [  31:0] pkt_length;  // 剩余待搬运数据数量
    reg  [  31:0] block_length;  // 本次搬运数量
    reg  [  63:0] block_staddr;  // 本次搬运开始地址
    //
    reg           move_req_d;
    reg           pkt_move_done;
    reg           block_move_done;
    reg           left_space_enough;

    task automatic mover_cmd;
        input [3:0] TAG;  //Command TAG
        input [(MM_ADDR_WIDTH-1):0] SADDR;
        input DRR;  // DRE ReAlignment Request
        input EOF;  // End of Frame
        input [5:0] DSA;  // DRE Stream Alignment
        input Type;  // 1:incr, 0:fixed
        input [22:0] BIT;
        output [(MM_ADDR_WIDTH+39) : 0] cmd;  //
        cmd = {4'b0, TAG, SADDR, DRR, EOF, DSA, Type, BIT};
    endtask

    assign move_staddr = pkt_info_data[32+:64];  // 64 bit
    assign move_length = pkt_info_data[0+:32];  // 32 bit

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
                    if (move_req_d) begin
                        n_state = FSM_START;
                    end else begin
                        n_state = FSM_IDLE;
                    end
                end
                FSM_START: begin
                    n_state = FSM_PRE_WAIT;
                end
                FSM_PRE_WAIT: begin
                    if (cmd_tready) begin
                        if (move_en) begin
                            if (left_space_enough) begin
                                n_state = FSM_MOVE_UPDATE;
                            end else begin
                                n_state = FSM_PRE_WAIT;
                            end
                        end else begin
                            n_state = FSM_IDLE;
                        end
                    end else begin
                        n_state = FSM_PRE_WAIT;
                    end
                end
                FSM_MOVE_UPDATE: begin
                    if (pkt_move_done) begin
                        n_state = FSM_IDLE;
                    end else begin
                        n_state = FSM_MOVE_CMD;
                    end
                end
                FSM_MOVE_CMD: begin
                    n_state = FSM_POST_WAIT;
                end
                FSM_POST_WAIT: begin
                    if (sts_tvalid) begin
                        n_state = FSM_PRE_WAIT;
                    end else begin
                        n_state = FSM_POST_WAIT;
                    end
                end
                default: n_state = FSM_IDLE;
            endcase
        end
    end

    //  读取新数据包信息
    always @(posedge clk) begin
        if (!rstn) begin
            pkt_info_rd <= 1'b0;
        end else begin
            case (n_state)
                FSM_IDLE:
                pkt_info_rd <= move_en & (~pkt_info_empty) & (~pkt_info_rd) & (~move_req_d);
                default: pkt_info_rd <= 1'b0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            move_req_d <= 1'b0;
        end else begin
            move_req_d <= pkt_info_rd;
        end
    end

    // 剩余字节数
    always @(posedge clk) begin
        if (!rstn) begin
            pkt_length <= 0;
        end else begin
            case (n_state)
                FSM_START: pkt_length <= move_length;
                FSM_PRE_WAIT, FSM_POST_WAIT, FSM_MOVE_UPDATE: pkt_length <= pkt_length;
                FSM_MOVE_CMD: pkt_length <= pkt_length - block_length;
                default: pkt_length <= 0;
            endcase
        end
    end

    // 数据块长度
    always @(posedge clk) begin
        if (!rstn) begin
            block_length <= 0;
        end else begin
            case (n_state)
                FSM_MOVE_UPDATE:
                block_length <= (pkt_length > BLOCK_SIZE) ? BLOCK_SIZE : pkt_length;
                FSM_PRE_WAIT, FSM_POST_WAIT, FSM_MOVE_CMD: block_length <= block_length;
                default: block_length <= 0;
            endcase
        end
    end

    // 数据块起始地址
    always @(posedge clk) begin
        if (!rstn) begin
            block_staddr <= 0;
        end else begin
            case (n_state)
                FSM_START: block_staddr <= move_staddr;
                FSM_MOVE_UPDATE: block_staddr <= block_staddr + block_length;
                FSM_PRE_WAIT, FSM_POST_WAIT, FSM_MOVE_CMD: block_staddr <= block_staddr;
                default: block_staddr <= 0;
            endcase
        end
    end

    // 数据搬移命令
    always @(posedge clk) begin
        if (!rstn) begin
            cmd_tvalid <= 1'b0;
            cmd_tdata  <= 0;
        end else begin
            case (n_state)
                FSM_MOVE_CMD: begin
                    cmd_tvalid <= 1'b1;
                    mover_cmd(4'h0, block_staddr[0+:MM_ADDR_WIDTH], 1'b0, 1'b1, 6'b0, 1'b1,
                              block_length[0+:22], cmd_tdata);
                end
                default: begin
                    cmd_tvalid <= 1'b0;
                    cmd_tdata  <= 0;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            pkt_move_done <= 1'b0;
        end else begin
            case (n_state)
                FSM_MOVE_UPDATE: pkt_move_done <= (pkt_length == 0) ? 1'b1 : 1'b0;
                default: pkt_move_done <= 1'b0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            sts_tready <= 1'b0;
        end else begin
            case (n_state)
                FSM_POST_WAIT: sts_tready <= 1'b1;
                default: sts_tready <= 1'b0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            left_space_enough <= 1'b0;
        end else begin
            left_space_enough <= ~fifo_afull;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            block_move_done <= 1'b0;
        end else begin
            block_move_done <= sts_tvalid & sts_tready & sts_tkeep;
        end
    end

    // state feedback
    always @(posedge clk) begin
        if (!rstn) begin
            move_busy <= 1'b1;
        end else begin
            case (n_state)
                FSM_IDLE: move_busy <= 1'b0;
                default:  move_busy <= 1'b1;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            move_addr <= 0;
        end else begin
            if (block_move_done) begin
                move_addr <= block_staddr + block_length;
            end
        end
    end
    assign move_done = pkt_move_done;

    always @(posedge clk) begin
        if (!rstn) begin
            move_err <= 1'b0;
        end else begin
            if (sts_err | (sts_tready & sts_tvalid & (sts_tdata != 8'h80))) begin
                move_err <= 1'b1;
            end else begin
                move_err <= 1'b0;
            end
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
