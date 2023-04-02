
// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on
module sc_hdlc_v1_0_M_AXIS_tb;

    // Parameters
    localparam integer C_M_START_COUNT = 8;
    localparam real TIMEPERIOD = 5;

    // Ports
    reg          Clk = 0;
    reg          Rstn = 0;

    // Ports
    wire         M_AXIS_ACLK;
    wire         M_AXIS_ARESETN;
    wire         M_AXIS_TVALID;
    wire [7 : 0] M_AXIS_TDATA;
    wire [0 : 0] M_AXIS_TSTRB;
    wire         M_AXIS_TLAST;
    reg          M_AXIS_TREADY = 0;
    reg          AXISWrReq = 0;
    reg  [ 31:0] AXISWrNum;
    wire         AXISWrBusy;
    wire         AXISWrDone;
    wire         FIFOEmpty;
    wire         FIFOAEmpty;
    reg  [  7:0] FIFORdData;
    wire         FIFORdEn;

    sc_hdlc_v1_0_M_AXIS #(
        .C_M_START_COUNT(C_M_START_COUNT)
    ) sc_hdlc_v1_0_M_AXIS_dut (
        .M_AXIS_ACLK(M_AXIS_ACLK),
        .M_AXIS_ARESETN(M_AXIS_ARESETN),
        .M_AXIS_TVALID(M_AXIS_TVALID),
        .M_AXIS_TDATA(M_AXIS_TDATA),
        .M_AXIS_TSTRB(M_AXIS_TSTRB),
        .M_AXIS_TLAST(M_AXIS_TLAST),
        .M_AXIS_TREADY(M_AXIS_TREADY),
        .AXISWrReq(AXISWrReq),
        .AXISWrNum(AXISWrNum),
        .AXISWrBusy(AXISWrBusy),
        .AXISWrDone(AXISWrDone),
        .FIFOEmpty(FIFOEmpty),
        .FIFOAEmpty(FIFOAEmpty),
        .FIFORdData(FIFORdData),
        .FIFORdEn(FIFORdEn)
    );

    assign FIFOAEmpty     = 1'b0;
    assign FIFOEmpty      = 1'b0;
    assign M_AXIS_ACLK    = Clk;
    assign M_AXIS_ARESETN = Rstn;


    initial begin
        AXISWrReq = 1'b0;
        AXISWrNum = 0;
        #400;
        wait (M_AXIS_ARESETN);

        #TIMEPERIOD;
        #TIMEPERIOD;
        AXISWrReq = 1'b1;
        AXISWrNum = 32;
        #TIMEPERIOD;
        AXISWrReq = 1'b0;
        AXISWrNum = 0;

        wait (!AXISWrBusy);
        #400;
        $finish;
    end

    reg [7:0] cnt = 0;
    wire top;
    assign top = (cnt >= 16) ? 1'b1 : 1'b0;
    always @(posedge M_AXIS_ACLK) begin
        if (!M_AXIS_ARESETN || top) begin
            cnt <= 0;
        end else if (M_AXIS_TREADY && M_AXIS_TVALID) begin
            cnt <= cnt + 1;
        end
    end

    always @(posedge M_AXIS_ACLK) begin
        if (!M_AXIS_ARESETN || top) begin
            M_AXIS_TREADY <= 1'b0;
        end else M_AXIS_TREADY <= 1'b1;
    end


    always @(posedge M_AXIS_ACLK) begin
        if (!M_AXIS_ARESETN) begin
            FIFORdData <= 8'h00;
        end else if (!FIFOEmpty && FIFORdEn) begin
            FIFORdData <= FIFORdData + 1;
        end
    end

    // ***********************************************************************************
    // clock block
    always #(TIMEPERIOD / 2) Clk = !Clk;

    // reset block
    initial begin
        begin
            Rstn = 1'b0;
            #(TIMEPERIOD * 2);
            Rstn = 1'b1;
        end
    end

    // record block
    initial begin
        begin
            $dumpfile("sim/test_tb.lxt");
            $dumpvars(0, sc_hdlc_v1_0_M_AXIS_tb);
        end
    end
endmodule

// verilog_format: off
`resetall
// verilog_format: on
