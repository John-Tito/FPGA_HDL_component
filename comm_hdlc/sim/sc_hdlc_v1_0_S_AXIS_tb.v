
// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on
module sc_hdlc_v1_0_S_AXIS_tb;

    // Parameters
    localparam integer C_M_START_COUNT = 8;
    localparam real TIMEPERIOD = 5;

    // Ports
    reg          Clk = 0;
    reg          Rstn = 0;

    // Ports
    wire         S_AXIS_ACLK;
    wire         S_AXIS_ARESETN;

    wire         S_AXIS_TREADY;
    reg  [7 : 0] S_AXIS_TDATA;
    reg  [0 : 0] S_AXIS_TSTRB;
    reg          S_AXIS_TLAST = 0;
    reg          S_AXIS_TVALID = 0;
    reg          AXISRdReq = 0;
    wire         AXISRdBusy;
    wire         AXISRdDone;
    wire         FIFOFull;
    wire         FIFOAFull;
    wire [  7:0] FIFOWrData;
    wire         FIFOWrEn;

    sc_hdlc_v1_0_S_AXIS sc_hdlc_v1_0_S_AXIS_dut (
        .S_AXIS_ACLK(S_AXIS_ACLK),
        .S_AXIS_ARESETN(S_AXIS_ARESETN),
        .S_AXIS_TREADY(S_AXIS_TREADY),
        .S_AXIS_TDATA(S_AXIS_TDATA),
        .S_AXIS_TSTRB(S_AXIS_TSTRB),
        .S_AXIS_TLAST(S_AXIS_TLAST),
        .S_AXIS_TVALID(S_AXIS_TVALID),
        .AXISRdReq(AXISRdReq),
        .AXISRdBusy(AXISRdBusy),
        .AXISRdDone(AXISRdDone),
        .FIFOFull(FIFOFull),
        .FIFOAFull(FIFOAFull),
        .FIFOWrData(FIFOWrData),
        .FIFOWrEn(FIFOWrEn)
    );

    assign FIFOAFull      = 1'b0;
    assign FIFOFull       = 1'b0;

    assign S_AXIS_ACLK    = Clk;
    assign S_AXIS_ARESETN = Rstn;

    initial begin
        AXISRdReq = 1'b0;
        #400;
        wait (S_AXIS_ARESETN);

        #TIMEPERIOD;
        #TIMEPERIOD;
        AXISRdReq = 1'b1;
        #TIMEPERIOD;
        AXISRdReq = 1'b0;

        wait (!AXISRdBusy);
        #400;
        $finish;
    end

    reg [7:0] cnt = 0;
    wire top;
    assign top = (cnt >= 16) ? 1'b1 : 1'b0;

    always @(posedge S_AXIS_ACLK) begin
        if (!S_AXIS_ARESETN) begin
            cnt <= 0;
        end else if (S_AXIS_TREADY && S_AXIS_TVALID) begin
            if (top) begin
                cnt <= 0;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end

    always @(posedge S_AXIS_ACLK) begin
        if (!S_AXIS_ARESETN) begin
            S_AXIS_TVALID <= 1'b0;
        end else begin
            if (S_AXIS_TLAST || (5 == cnt && S_AXIS_TVALID)) begin
                S_AXIS_TVALID <= 1'b0;
            end else begin
                S_AXIS_TVALID <= 1'b1;
            end
        end
    end

    always @(posedge S_AXIS_ACLK) begin
        if (!S_AXIS_ARESETN) begin
            S_AXIS_TLAST <= 1'b0;
        end else if (top) begin
            S_AXIS_TLAST <= 1'b1;
        end else begin
            S_AXIS_TLAST <= 1'b0;
        end
    end

    always @(posedge S_AXIS_ACLK) begin
        if (!S_AXIS_ARESETN) begin
            S_AXIS_TDATA <= 0;
        end else if (S_AXIS_TREADY && S_AXIS_TVALID) begin
            S_AXIS_TDATA <= S_AXIS_TDATA + 1;
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
            $dumpvars(0, sc_hdlc_v1_0_S_AXIS_tb);
        end
    end
endmodule

// verilog_format: off
`resetall
// verilog_format: on
