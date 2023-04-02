// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module sample_core #(
    parameter integer BIT_WIDTH = 64,
    parameter integer BLOCK_SIZE = 512,
    parameter IN_SIM = "false",
    parameter ENABLE_DEBUG = "false"
) (
    input  wire                       clk,
    input  wire                       rstn,
    // config
    input  wire [               63:0] config_start_addr,      // 起始地址,对齐到increment
    input  wire [               63:0] config_end_addr,        // 终止地址,对齐到increment
    input  wire [               31:0] config_sample_num,      // 总采样点数
    input  wire [               31:0] config_pre_sample_num,  // 预采样点数
    input  wire                       update_config,          // 更新参数配置
    // sample control and trig
    input  wire                       sample_start,           //
    input  wire                       sample_trig,            // 触发信号
    output reg                        sample_busy,            //
    output reg                        sample_done,            //
    output reg                        sample_err,             //
    output reg                        trig_out,
    // sample data
    input  wire [    (BIT_WIDTH-1):0] data,                   // 采样数据
    input  wire                       data_valid,             // 采样数据有效
    // axi-stream master
    output wire                       m_axis_tvalid,
    output wire [  (BIT_WIDTH-1) : 0] m_axis_tdata,
    output wire [(BIT_WIDTH/8-1) : 0] m_axis_tkeep,
    output wire                       m_axis_tlast,
    input  wire                       m_axis_tready,
    //
    output reg                        pkt_info_wr,            //
    output wire [               95:0] pkt_info_data,          //
    //
    output reg  [               63:0] rec_trig_addr,
    output reg  [               63:0] rec_start_addr,
    output reg  [               63:0] rec_end_addr
);

    localparam integer BYTE_WIDTH = BIT_WIDTH / 8;
    reg                       axis_tvalid;
    reg  [(BYTE_WIDTH-1) : 0] axis_tkeep;
    wire                      axis_tlast;
    reg  [ (BIT_WIDTH-1) : 0] axis_tdata;
    wire                      active;

    assign m_axis_tvalid = axis_tvalid;
    assign m_axis_tdata  = axis_tdata;
    assign m_axis_tkeep  = axis_tkeep;
    assign m_axis_tlast  = axis_tlast;
    assign active        = axis_tvalid && m_axis_tready;

    //
    localparam FSM_IDLE = 8'h01;
    localparam FSM_SAMPLE_START = 8'h02;
    localparam FSM_SAMPLE_PRE = 8'h04;
    localparam FSM_SAMPLE_WAIT = 8'h08;
    localparam FSM_SAMPLE_POST = 8'h10;
    localparam FSM_SAMPLE_END = 8'h20;
    localparam FSM_SAMPLE_ERR = 8'h40;

    reg  [ 7:0] c_state;  // 状态机初态
    reg  [ 7:0] n_state;  // 状态机次态

    reg  [31:0] sample_cnt;

    reg  [31:0] sample_num;
    reg  [31:0] pre_sample_num;
    reg  [63:0] start_addr;
    reg  [63:0] end_addr;

    wire        pre_sample_done;
    wire        post_sample_done;

    reg  [63:0] pkt_info_addr;
    reg  [31:0] pkt_info_length;

    reg  [31:0] byte_cnt;
    wire [31:0] next_cnt;
    reg  [63:0] block_addr;
    reg  [63:0] byte_addr;
    wire [63:0] next_addr;

    wire        clr;
    wire        no_space;
    wire        data_pack;
    wire        will_push;
    wire        data_push;

    // input config check
    always @(posedge clk) begin : config_update
        if (!rstn) begin
            sample_num     <= 1024;
            pre_sample_num <= 512;
            start_addr     <= 0;
            end_addr       <= 32'hFFFFFFFF;
        end else if (update_config) begin
            if (config_pre_sample_num <= config_sample_num) begin
                sample_num <= config_sample_num;
            end
            if (config_pre_sample_num <= config_sample_num) begin
                pre_sample_num <= config_pre_sample_num;
            end
            if (config_start_addr < config_end_addr) begin
                start_addr <= config_start_addr;
            end
            if ((config_start_addr < config_end_addr)) begin
                end_addr <= config_end_addr;
            end
        end
    end

    // state_update
    always @(posedge clk) begin : fsm_sync
        if (!rstn) begin
            c_state <= FSM_IDLE;
        end else begin
            c_state <= n_state;
        end
    end

    // state_change
    always @(*) begin : fsm_update
        if (!rstn) begin
            n_state = FSM_IDLE;
        end else begin
            case (c_state)
                FSM_IDLE: begin
                    if (sample_start) begin
                        n_state = FSM_SAMPLE_START;
                    end else begin
                        n_state = FSM_IDLE;
                    end
                end
                FSM_SAMPLE_START: begin
                    if ((sample_num > 0) && (pre_sample_num <= sample_num) && (start_addr + sample_num*BYTE_WIDTH <= end_addr)) begin
                        if (pre_sample_num > 0) begin
                            n_state = FSM_SAMPLE_PRE;
                        end else begin
                            n_state = FSM_SAMPLE_WAIT;
                        end
                    end else begin
                        n_state = FSM_SAMPLE_ERR;
                    end
                end
                FSM_SAMPLE_PRE: begin
                    if (post_sample_done & active & sample_trig) begin
                        n_state = FSM_SAMPLE_END;
                    end else if (pre_sample_done & active) begin
                        n_state = FSM_SAMPLE_POST;
                    end else begin
                        n_state = FSM_SAMPLE_PRE;
                    end
                end
                FSM_SAMPLE_WAIT: begin
                    if (sample_trig) begin
                        n_state = FSM_SAMPLE_POST;
                    end else begin
                        n_state = FSM_SAMPLE_WAIT;
                    end
                end
                FSM_SAMPLE_POST: begin
                    if (post_sample_done & active) begin
                        n_state = FSM_SAMPLE_END;
                    end else begin
                        n_state = FSM_SAMPLE_POST;
                    end
                end
                default: n_state = FSM_IDLE;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            trig_out <= 1'b0;
        end else begin
            case (c_state)
                FSM_SAMPLE_PRE: begin
                    if ((post_sample_done | pre_sample_done) & data_valid & sample_trig) begin
                        trig_out <= 1'b1;
                    end else begin
                        trig_out <= 1'b0;
                    end
                end
                FSM_SAMPLE_WAIT: begin
                    if (sample_trig) begin
                        trig_out <= 1'b1;
                    end else begin
                        trig_out <= 1'b0;
                    end
                end
                default: trig_out <= 1'b0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            sample_cnt <= 0;
        end else begin
            case (n_state)
                FSM_SAMPLE_PRE: begin
                    if (((pre_sample_num - 1 > sample_cnt) || pre_sample_done) && active) begin
                        sample_cnt <= sample_cnt + 1;
                    end
                end
                FSM_SAMPLE_POST: begin
                    if (active) begin
                        sample_cnt <= sample_cnt + 1;
                    end
                end
                default: sample_cnt <= 0;
            endcase
        end
    end

    assign pre_sample_done = (pre_sample_num - 1 <= sample_cnt) && sample_trig;
    assign post_sample_done =  (pre_sample_num != sample_num) ? ((sample_num - 1 <= sample_cnt) ) :(pre_sample_done) ;

    always @(posedge clk) begin
        if (!rstn) begin
            sample_busy <= 1'b1;
        end else begin
            case (n_state)
                FSM_IDLE: sample_busy <= 1'b0;
                default:  sample_busy <= 1'b1;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            sample_done <= 1'b0;
        end else begin
            case (n_state)
                FSM_SAMPLE_END: sample_done <= 1'b1;
                default: sample_done <= 1'b0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            sample_err <= 1'b0;
        end else begin
            case (n_state)
                FSM_SAMPLE_ERR: sample_err <= 1'b1;
                default: sample_err <= 1'b0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            axis_tvalid <= 1'b0;
        end else begin
            case (n_state)
                FSM_SAMPLE_PRE, FSM_SAMPLE_POST: begin
                    if (data_valid) begin
                        axis_tvalid <= 1'b1;
                    end else if (active) begin
                        axis_tvalid <= 1'b0;
                    end
                end
                default: begin
                    axis_tvalid <= 1'b0;
                end
            endcase
        end
    end

    assign axis_tlast = will_push;
    // always @(posedge clk) begin
    //     if (!rstn) begin
    //         axis_tlast <= 1'b0;
    //     end else begin
    //         case (n_state)
    //             FSM_SAMPLE_PRE, FSM_SAMPLE_POST: begin
    //                 if (data_valid) begin
    //                     if ((byte_cnt == BLOCK_SIZE - (2 * BYTE_WIDTH))) begin
    //                         axis_tlast <= 1'b1;
    //                     end else begin
    //                         if (pre_sample_num != sample_num) begin
    //                             if (sample_num - 2 <= sample_cnt) begin
    //                                 axis_tlast <= 1'b1;
    //                             end
    //                         end else begin
    //                             if ((sample_num - 2 <= sample_cnt) && sample_trig) begin
    //                                 axis_tlast <= 1'b1;
    //                             end
    //                         end
    //                     end
    //                 end else if (active) begin
    //                     axis_tvalid <= 1'b0;
    //                 end
    //             end
    //             default: begin
    //                 axis_tlast <= 1'b0;
    //             end
    //         endcase
    //     end
    // end

    always @(posedge clk) begin
        if (!rstn) begin
            axis_tdata <= 0;
            axis_tkeep <= 0;
        end else begin
            case (n_state)
                FSM_SAMPLE_PRE, FSM_SAMPLE_POST: begin
                    if (data_valid) begin
                        axis_tdata <= data;
                        axis_tkeep <= {BYTE_WIDTH{1'b1}};
                    end
                end
                default: begin
                    axis_tdata <= 0;
                    axis_tkeep <= 0;
                end
            endcase
        end
    end

    // ***********************************************************************************
    // pack data
    // ***********************************************************************************

    assign clr           = (~rstn) | sample_start | sample_done | sample_err;

    assign data_pack     = (next_cnt == BLOCK_SIZE);
    assign no_space      = (end_addr <= block_addr + next_cnt);

    assign will_push     = data_pack | no_space | post_sample_done;
    assign data_push     = active & will_push;

    assign next_cnt      = byte_cnt + BYTE_WIDTH;
    assign next_addr     = byte_addr + BYTE_WIDTH;
    assign pkt_info_data = {pkt_info_addr, pkt_info_length};

    always @(posedge clk) begin
        if (clr || data_push) begin
            byte_cnt <= 0;
        end else if (active) begin
            byte_cnt <= next_cnt;
        end else begin
            byte_cnt <= byte_cnt;
        end
    end

    always @(posedge clk) begin
        if (clr) begin
            byte_addr <= start_addr;
        end else if (active) begin
            if (no_space) byte_addr <= start_addr;
            else byte_addr <= next_addr;
        end else begin
            byte_addr <= byte_addr;
        end
    end

    always @(posedge clk) begin
        if (clr) begin
            block_addr <= start_addr;
        end else if (data_push) begin
            if (no_space) block_addr <= start_addr;
            else block_addr <= next_addr;
        end else begin
            block_addr <= block_addr;
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            pkt_info_wr     <= 1'b0;
            pkt_info_addr   <= 0;
            pkt_info_length <= 0;
        end else if (data_push) begin
            pkt_info_wr     <= 1'b1;
            pkt_info_addr   <= block_addr;
            pkt_info_length <= next_cnt;
        end else begin
            pkt_info_wr     <= 1'b0;
            pkt_info_addr   <= 0;
            pkt_info_length <= 0;
        end
    end

    // for sim only
    always @(posedge clk) begin
        if (!rstn) begin
            rec_trig_addr  <= 0;
            rec_start_addr <= 0;
            rec_end_addr   <= 0;
        end

        if (data_push) begin
            if (next_addr > start_addr) begin
                $display("write length:%d,from:%x,to:%x", next_cnt, block_addr, next_addr - 1);
            end else begin
                $display("write length:%d,from:%x,to:%x", next_cnt, block_addr, end_addr);
            end
        end

        if (no_space & active) begin
            if (next_addr > start_addr) begin
                $display("turn back at,%x", next_addr - 1);
            end else begin
                $display("turn back at,%x", end_addr);
            end
        end

        if (post_sample_done && active) begin
            if (next_addr < (sample_num * BYTE_WIDTH + start_addr)) begin
                rec_start_addr <= next_addr + (end_addr - start_addr) - sample_num * BYTE_WIDTH;
                $display("start at,%x ",
                         next_addr + (end_addr - start_addr) - sample_num * BYTE_WIDTH);
            end else begin
                rec_start_addr <= next_addr - sample_num * BYTE_WIDTH;
                $display("start at,%x ", next_addr - sample_num * BYTE_WIDTH);
            end

            if (next_addr > start_addr) begin
                rec_end_addr <= next_addr - 1;
                $display("end at,%x ", next_addr - 1);
            end else begin
                rec_end_addr <= end_addr;
                $display("end at,%x ", end_addr);
            end
        end

        if (trig_out) begin
            if (next_addr > start_addr) begin
                rec_trig_addr <= next_addr - 1;
                $display("trig at,%x ", next_addr - 1);
            end else begin
                rec_trig_addr <= end_addr;
                $display("trig at,%x ", end_addr);
            end
        end
    end

    generate
        if ((IN_SIM == "false") && (ENABLE_DEBUG == "true")) begin : g_ila
            sample_ila_0 ila_0_inst (
                .clk   (clk),           // clk
                .probe0(sample_start),  // [0:0]
                .probe1(sample_trig),   // [0:0]
                .probe2(sample_busy),   // [0:0]
                .probe3(sample_done),   // [0:0]
                .probe4(sample_err),    // [0:0]
                .probe5(trig_out),      // [0:0]

                .probe6(pkt_info_wr),     // [0:0]
                .probe7(pkt_info_addr),   // [31:0]
                .probe8(pkt_info_length), // [31:0]

                .probe9 (c_state),           // [7:0]
                .probe10(n_state),           // [7:0]
                .probe11(pre_sample_done),   // [0:0]
                .probe12(post_sample_done),  // [0:0]
                .probe13(sample_cnt),        // [31:0]
                .probe14(active),            // [0:0]
                .probe15(no_space),          // [0:0]
                .probe16(data_pack),         // [0:0]
                .probe17(will_push),         // [0:0]
                .probe18(data_push),         // [0:0]

                .probe19(m_axis_tvalid),       // [0:0]
                .probe20(m_axis_tready),       // [0:0]
                .probe21(m_axis_tdata[15:0]),  // [15:0]
                .probe22(m_axis_tlast),        // [0:0]
                .probe23(m_axis_tkeep)         // [15:0]
            );
        end
        //m_axis_tvalid
    endgenerate

endmodule

// verilog_format: off
`resetall
// verilog_format: on
