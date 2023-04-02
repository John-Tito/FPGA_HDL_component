// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module HDLC_RECEIVE #(
    parameter TAIL_AS_HEAD = "false"
) (
    input  wire        Clk,             // clock
    input  wire        Rstn,            // acvtive low reset
    input  wire        RxEnable,        // rx enable
    input  wire        KeepFlag,        //
    input  wire        SRX,             // serial data input
    output reg  [ 8:0] PData,           //
    output reg         PDataValid,      //
    output wire        FrameReceiving,  //
    output reg         FrameStart,      //
    output reg         FrameAbort,      //
    output reg         FrameEnd,        //
    output reg         FrameError,      //
    output reg  [31:0] FrameByteLen,    //
    output reg  [31:0] FrameBitLen      //
);

    localparam FSM_IDLE = 4'b0000;
    localparam FSM_HEAD = 4'b0001;
    localparam FSM_DATA = 4'b0010;
    localparam FSM_TAIL = 4'b0100;
    localparam FSM_ERR = 4'b1000;

    reg  [3:0]  RxState;
    reg         RxEnable_d;
    reg         InFrame;
    reg         InFrameD;
    wire        ShiftEn;
    wire        r_F_flag;
    wire        r_E_flag;
    wire        r_s_valid;
    wire [ 7:0] r_pdata;
    wire        r_p_valid;

    wire        CRCEn;
    wire [15:0] r_PCRC;
    reg  [15:0] CRCLatch;
    wire [15:0] CRCCheck;

    HDLC_RX_FLAG_CHECKER HDLC_RX_FLAG_CHECKER_inst (
        .Clk  (Clk),
        .Rstn (Rstn),
        .En   (RxEnable),
        .SRX  (SRX),
        .SRXD (),
        .FFlag(r_F_flag),
        .EFlag(r_E_flag)
    );

    HDLC_RX_ZREO_DELETE HDLC_RX_ZREO_DELETE_inst (
        .Clk  (Clk),
        .Rstn (Rstn),
        .En   (RxEnable),
        .SRX  (SRX),
        .Valid(r_s_valid)
    );

    HDLC_RX_SHIFT HDLC_RX_SHIFT_inst (
        .Clk       (Clk),
        .Rstn      (Rstn),
        .En        (ShiftEn),
        .Clr       (r_F_flag),
        .SData     (SRX),
        .PData     (r_pdata),
        .PDataValid(r_p_valid)
    );

    HDLC_SERIAL_CRC #(
        .INIT(16'hFFFF)
    ) HDLC_SERIAL_CRC_inst (
        .Clk      (Clk),
        .Rstn     (Rstn),
        .En       (CRCEn),
        .Clr      (r_F_flag),
        .SData    (SRX),
        .PCRC     (r_PCRC),
        .SCRC     (),
        .SCRCValid(),
        .CRCCkeck (CRCCheck)
    );

    assign CRCEn   = (r_s_valid | r_F_flag) & RxEnable_d;
    assign ShiftEn = (r_s_valid | r_F_flag) & RxEnable_d;

    always @(posedge Clk) begin
        if (!Rstn) begin
            RxEnable_d <= 1'b0;
        end else begin
            RxEnable_d <= RxEnable;
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            RxState <= FSM_IDLE;
        end else begin
            case (RxState)
                FSM_IDLE: begin
                    if (r_E_flag) begin
                        RxState <= FSM_ERR;
                    end else if (r_F_flag) begin
                        RxState <= FSM_HEAD;
                    end
                end
                FSM_HEAD: begin
                    if (r_E_flag) begin
                        RxState <= FSM_ERR;
                    end else if (r_p_valid & !r_F_flag) begin
                        RxState <= FSM_DATA;
                    end
                end
                FSM_DATA: begin
                    if (r_E_flag) begin
                        RxState <= FSM_ERR;
                    end else if (r_F_flag) begin
                        if (TAIL_AS_HEAD == "true") begin
                            RxState <= FSM_HEAD;
                        end else begin
                            RxState <= FSM_TAIL;
                        end
                    end
                end
                FSM_TAIL: begin
                    if (r_E_flag) begin
                        RxState <= FSM_ERR;
                    end else if (r_F_flag) begin
                        RxState <= FSM_HEAD;
                    end else begin
                        RxState <= FSM_IDLE;
                    end
                end
                FSM_ERR: begin
                    if (r_E_flag) begin
                        RxState <= FSM_ERR;
                    end else if (r_F_flag) begin
                        RxState <= FSM_HEAD;
                    end
                end
                default: RxState <= FSM_IDLE;
            endcase
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            InFrame <= 1'b0;
        end else begin
            case (RxState)
                FSM_IDLE: InFrame <= 1'b0;
                FSM_HEAD: InFrame <= 1'b1;
                FSM_DATA: InFrame <= 1'b1;
                FSM_ERR:  InFrame <= 1'b0;
                default:  InFrame <= 1'b0;
            endcase
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            InFrameD <= 1'b0;
        end else begin
            case (RxState)
                FSM_IDLE: InFrameD <= 1'b0;
                FSM_HEAD: InFrameD <= 1'b0;
                FSM_DATA: InFrameD <= 1'b1;
                FSM_ERR:  InFrameD <= 1'b0;
                default:  InFrameD <= 1'b0;
            endcase
        end
    end
    assign FrameReceiving = InFrameD;

    always @(posedge Clk) begin
        if (!Rstn) begin
            CRCLatch <= 16'h0000;
        end else begin
            if (InFrame && r_p_valid) begin
                CRCLatch <= r_PCRC;
            end
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            FrameError <= 1'b0;
        end else begin
            if ((3'b010 == RxState) && r_F_flag && (!r_E_flag)) begin
                FrameError <= (CRCCheck == CRCLatch) ? 1'b0 : 1'b1;
            end else FrameError <= 1'b0;
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) FrameStart <= 1'b0;
        else if ((FSM_HEAD == RxState) && r_p_valid && (!r_E_flag)) FrameStart <= 1'b1;
        else FrameStart <= 1'b0;
    end

    always @(posedge Clk) begin
        if (!Rstn) FrameEnd <= 1'b0;
        else if ((FSM_DATA == RxState) && r_F_flag && (!r_E_flag)) FrameEnd <= 1'b1;
        else FrameEnd <= 1'b0;
    end


    always @(posedge Clk) begin
        if (!Rstn) FrameAbort <= 1'b0;
        else begin
            case (RxState)
                FSM_IDLE, FSM_HEAD, FSM_DATA: begin
                    FrameAbort <= r_E_flag;
                end
                FSM_ERR: begin
                    if (r_F_flag && (!r_E_flag)) FrameAbort <= 1'b0;
                    else FrameAbort <= 1'b1;
                end
                default: FrameAbort <= 1'b0;
            endcase
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            PData <= {1'b0, 8'h00};
        end else begin
            if (KeepFlag) begin
                if (InFrame) begin
                    if (r_p_valid) begin
                        PData <= {1'b0, r_pdata};
                    end else if (r_F_flag) begin
                        PData <= {1'b1, 8'h7e};
                    end
                end else if (r_F_flag) begin
                    PData <= {1'b1, 8'h7e};
                end
            end else begin
                if (!InFrame) begin
                    PData <= {1'b0, 8'h00};
                end else if (InFrame && r_p_valid) begin
                    PData <= {1'b0, r_pdata};
                end
            end
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            PDataValid <= 1'b0;
        end else begin
            if (KeepFlag) begin
                if (InFrame) begin
                    PDataValid <= r_p_valid | r_F_flag;
                end else begin
                    PDataValid <= r_F_flag;
                end
            end else begin
                if (InFrame) begin
                    PDataValid <= r_p_valid;
                end else begin
                    PDataValid <= 1'b0;
                end
            end
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            FrameByteLen <= 0;
        end else begin
            if (InFrameD) begin
                if (r_p_valid) begin
                    FrameByteLen <= FrameByteLen + 1;
                end
            end else if (InFrame) begin
                if (r_p_valid) begin
                    FrameByteLen <= 1;
                end
            end else begin
                FrameByteLen <= 0;
            end
        end
    end

    always @(posedge Clk) begin
        if (!Rstn) begin
            FrameBitLen <= 0;
        end else begin
            if (FrameEnd) begin
                FrameBitLen <= 0;
            end else begin
                if (InFrameD) begin
                    if (ShiftEn) begin
                        FrameBitLen <= FrameBitLen + 1;
                    end
                end else begin
                    FrameBitLen <= 0;
                end
            end
        end
    end

    // for test only
    always @(posedge Clk) begin
        if (Rstn) begin
            // if (r_F_flag) $display("frame div");

            if (r_p_valid) $display("receive data:%2x", r_pdata);
            if (r_E_flag) $display("abort");
        end
    end


endmodule

// verilog_format: off
`resetall
// verilog_format: on
