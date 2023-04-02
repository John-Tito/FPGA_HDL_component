// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module ad574_timing #(
    parameter integer IN_CLK_FREQ = 100_000_000
) (
    input  wire        clk,         //
    input  wire        rstn,        //
    //
    input  wire        op_req,      //
    input  wire        op,          //
    input  wire [ 1:0] addr,        //
    output reg         busy,        //
    output reg  [11:0] data,
    output reg         data_valid,
    // to ad574
    output wire        AO,          //
    output wire        S12_8n,      //
    output reg         CE,          //
    output reg         RCn,         //
    input  wire        STS,         //
    input  wire [11:0] DB           //
);

    // r_cn = 0b, init convert
    // AO = 0 Initiate 12-Bit Conversion
    // AO = 1 Initiate 12-Bit Conversion

    // r_cn = 1b, read
    // {S12_8n,AO} = 00b DB[11:4]
    // {S12_8n,AO} = 01b DB[3:0] ,4'b0
    // {S12_8n,AO} = 1Xb DB[11:0]

    localparam FSM_IDLE = 3'h0;
    localparam FSM_PRE_ASSERT_OP = 3'h1;  // hold for 300ns before ASSERT_CE
    localparam FSM_ASSERT_CE = 3'h2;  // hold for 300ns before DEASSERT_CE
    localparam FSM_POST_ASSERT_OP = 3'h4;  // hold for 300ns
    localparam FSM_WAIT_STS = 3'h5;
    localparam FSM_SAMPLE = 3'h6;
    localparam FSM_PAD = 3'h7;  // hold for 300ns

    localparam integer DIVIDE_FACT = 400 / (1000_000_000 / IN_CLK_FREQ);

    reg [ 2:0] c_state;
    reg [ 2:0] n_state;

    reg [31:0] cnt1;
    reg        cnt_done;
    reg [ 1:0] reg_select;

    assign {S12_8n, AO} = reg_select;

    always @(posedge clk) begin
        if (!rstn) begin
            cnt1 <= 0;
        end else begin
            case (n_state)
                FSM_PRE_ASSERT_OP, FSM_ASSERT_CE, FSM_POST_ASSERT_OP, FSM_WAIT_STS, FSM_SAMPLE, FSM_PAD: begin
                    if (cnt1 < DIVIDE_FACT) begin
                        cnt1 <= cnt1 + 1;
                    end else begin
                        cnt1 <= 0;
                    end
                end
                default: begin
                    cnt1 <= 0;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            cnt_done <= 1'b0;
        end else begin
            if (cnt1 < DIVIDE_FACT) begin
                cnt_done <= 1'b0;
            end else begin
                cnt_done <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            c_state <= 0;
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
                    if (op_req) begin
                        n_state = FSM_PRE_ASSERT_OP;
                    end else begin
                        n_state = FSM_IDLE;
                    end
                end
                FSM_PRE_ASSERT_OP: begin
                    if (cnt_done) begin
                        n_state = FSM_ASSERT_CE;
                    end else begin
                        n_state = FSM_PRE_ASSERT_OP;
                    end
                end
                FSM_ASSERT_CE: begin
                    if (cnt_done) begin
                        if (op) begin
                            n_state = FSM_SAMPLE;
                        end else begin
                            n_state = FSM_POST_ASSERT_OP;
                        end
                    end else begin
                        n_state = FSM_ASSERT_CE;
                    end
                end
                FSM_SAMPLE: begin
                    n_state = FSM_POST_ASSERT_OP;
                end
                FSM_POST_ASSERT_OP: begin
                    if (cnt_done) begin
                        if (!op) begin
                            n_state = FSM_WAIT_STS;
                        end else begin
                            n_state = FSM_PAD;
                        end
                    end else begin
                        n_state = FSM_POST_ASSERT_OP;
                    end
                end
                FSM_PAD: begin
                    if (cnt_done) begin
                        n_state = FSM_IDLE;
                    end else begin
                        n_state = FSM_PAD;
                    end
                end
                FSM_WAIT_STS: begin
                    if (!STS) begin
                        n_state = FSM_IDLE;
                    end else begin
                        n_state = FSM_WAIT_STS;
                    end
                end
                default: n_state = FSM_IDLE;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            reg_select <= 2'b10;
            RCn        <= 1'b0;
        end else begin
            case (c_state)
                FSM_PRE_ASSERT_OP, FSM_ASSERT_CE, FSM_SAMPLE, FSM_POST_ASSERT_OP: begin
                    reg_select <= addr;
                    RCn        <= op;
                end
                default: begin
                    reg_select <= 2'b10;
                    RCn        <= 1'b0;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            CE <= 1'b0;
        end else begin
            case (c_state)
                FSM_IDLE: begin
                    CE <= 1'b0;
                end
                FSM_ASSERT_CE: begin
                    CE <= 1'b1;
                end
                default: CE <= 1'b0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            data <= 0;
        end else begin
            case (c_state)
                FSM_SAMPLE: begin
                    data <= DB;
                end
                default: data <= data;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            data_valid <= 1'b0;
        end else begin
            case (c_state)
                FSM_SAMPLE: begin
                    data_valid <= 1'b1;
                end
                default: data_valid <= 1'b0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            busy <= 1'b1;
        end else begin
            case (c_state)
                FSM_IDLE: begin
                    busy <= op_req;
                end
                default: busy <= 1'b1;
            endcase
        end
    end
endmodule

// verilog_format: off
`resetall
// verilog_format: on
