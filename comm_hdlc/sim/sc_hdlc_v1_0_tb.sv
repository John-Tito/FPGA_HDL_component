// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

import axi_vip_pkg::*;
import axi4stream_vip_pkg::*;
import axi_vip_0_pkg::*;
import axi4stream_vip_0_pkg::*;
import axi4stream_vip_1_pkg::*;

module sc_hdlc_v1_0_tb ();

    // Parameters
    localparam real TIMEPERIOD = 5;
    localparam integer C_S_AXI_DATA_WIDTH = 32;
    localparam integer C_S_AXI_ADDR_WIDTH = 32;
    // Ports
    reg                             Clk = 0;
    reg                             Rstn = 0;

    wire                            RxClk;
    wire                            SRx;
    wire                            STx;
    wire                            TxClk;

    wire                            aclk_0_1;
    wire                            aresetn_0_1;

    wire [                     7:0] axi4stream_vip_0_M_AXIS_TDATA;
    wire [                     0:0] axi4stream_vip_0_M_AXIS_TLAST;
    wire                            axi4stream_vip_0_M_AXIS_TREADY;
    wire [                     0:0] axi4stream_vip_0_M_AXIS_TSTRB;
    wire [                     0:0] axi4stream_vip_0_M_AXIS_TVALID;

    wire [                     7:0] axi4stream_vip_1_S_AXIS_TDATA;
    wire                            axi4stream_vip_1_S_AXIS_TLAST;
    wire [                     0:0] axi4stream_vip_1_S_AXIS_TREADY;
    wire [                     0:0] axi4stream_vip_1_S_AXIS_TSTRB;
    wire                            axi4stream_vip_1_S_AXIS_TVALID;

    wire [(C_S_AXI_ADDR_WIDTH-1):0] axi_vip_0_M_AXI_ARADDR;
    wire [                     2:0] axi_vip_0_M_AXI_ARPROT;
    wire                            axi_vip_0_M_AXI_ARREADY;
    wire                            axi_vip_0_M_AXI_ARVALID;
    wire [(C_S_AXI_ADDR_WIDTH-1):0] axi_vip_0_M_AXI_AWADDR;
    wire [                     2:0] axi_vip_0_M_AXI_AWPROT;
    wire                            axi_vip_0_M_AXI_AWREADY;
    wire                            axi_vip_0_M_AXI_AWVALID;
    wire                            axi_vip_0_M_AXI_BREADY;
    wire [                     1:0] axi_vip_0_M_AXI_BRESP;
    wire                            axi_vip_0_M_AXI_BVALID;
    wire [(C_S_AXI_DATA_WIDTH-1):0] axi_vip_0_M_AXI_RDATA;
    wire                            axi_vip_0_M_AXI_RREADY;
    wire [                     1:0] axi_vip_0_M_AXI_RRESP;
    wire                            axi_vip_0_M_AXI_RVALID;
    wire [(C_S_AXI_DATA_WIDTH-1):0] axi_vip_0_M_AXI_WDATA;
    wire                            axi_vip_0_M_AXI_WREADY;
    wire [                     7:0] axi_vip_0_M_AXI_WSTRB;
    wire                            axi_vip_0_M_AXI_WVALID;

    axi4stream_vip_0 axi4stream_vip_0_dut (
        .aclk         (aclk_0_1),
        .aresetn      (aresetn_0_1),
        .m_axis_tdata (axi4stream_vip_0_M_AXIS_TDATA),
        .m_axis_tlast (axi4stream_vip_0_M_AXIS_TLAST),
        .m_axis_tready(axi4stream_vip_0_M_AXIS_TREADY),
        .m_axis_tstrb (axi4stream_vip_0_M_AXIS_TSTRB),
        .m_axis_tvalid(axi4stream_vip_0_M_AXIS_TVALID)
    );

    axi4stream_vip_1 axi4stream_vip_1_dut (
        .aclk         (aclk_0_1),
        .aresetn      (aresetn_0_1),
        .s_axis_tdata (axi4stream_vip_1_S_AXIS_TDATA),
        .s_axis_tlast (axi4stream_vip_1_S_AXIS_TLAST),
        .s_axis_tready(axi4stream_vip_1_S_AXIS_TREADY),
        .s_axis_tstrb (axi4stream_vip_1_S_AXIS_TSTRB),
        .s_axis_tvalid(axi4stream_vip_1_S_AXIS_TVALID)
    );

    axi_vip_0 axi_vip_0_dut (
        .aclk         (aclk_0_1),
        .aresetn      (aresetn_0_1),
        .m_axi_araddr (axi_vip_0_M_AXI_ARADDR),
        .m_axi_arprot (axi_vip_0_M_AXI_ARPROT),
        .m_axi_arready(axi_vip_0_M_AXI_ARREADY),
        .m_axi_arvalid(axi_vip_0_M_AXI_ARVALID),
        .m_axi_awaddr (axi_vip_0_M_AXI_AWADDR),
        .m_axi_awprot (axi_vip_0_M_AXI_AWPROT),
        .m_axi_awready(axi_vip_0_M_AXI_AWREADY),
        .m_axi_awvalid(axi_vip_0_M_AXI_AWVALID),
        .m_axi_bready (axi_vip_0_M_AXI_BREADY),
        .m_axi_bresp  (axi_vip_0_M_AXI_BRESP),
        .m_axi_bvalid (axi_vip_0_M_AXI_BVALID),
        .m_axi_rdata  (axi_vip_0_M_AXI_RDATA),
        .m_axi_rready (axi_vip_0_M_AXI_RREADY),
        .m_axi_rresp  (axi_vip_0_M_AXI_RRESP),
        .m_axi_rvalid (axi_vip_0_M_AXI_RVALID),
        .m_axi_wdata  (axi_vip_0_M_AXI_WDATA),
        .m_axi_wready (axi_vip_0_M_AXI_WREADY),
        .m_axi_wstrb  (axi_vip_0_M_AXI_WSTRB),
        .m_axi_wvalid (axi_vip_0_M_AXI_WVALID)
    );

    sc_hdlc_v1_0 #(
        .IN_SIM(1),
        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
        .C_M_AXIS_START_COUNT(32)
    ) sc_hdlc_0 (
        .RxClk         (RxClk),
        .SRx           (SRx),
        .STx           (STx),
        .TxClk         (TxClk),
        .m_axis_aclk   (aclk_0_1),
        .m_axis_aresetn(aresetn_0_1),
        .m_axis_tdata  (axi4stream_vip_1_S_AXIS_TDATA),
        .m_axis_tlast  (axi4stream_vip_1_S_AXIS_TLAST),
        .m_axis_tready (axi4stream_vip_1_S_AXIS_TREADY),
        .m_axis_tstrb  (axi4stream_vip_1_S_AXIS_TSTRB),
        .m_axis_tvalid (axi4stream_vip_1_S_AXIS_TVALID),
        .s_axi_aclk    (aclk_0_1),
        .s_axi_araddr  (axi_vip_0_M_AXI_ARADDR),
        .s_axi_aresetn (aresetn_0_1),
        .s_axi_arprot  (axi_vip_0_M_AXI_ARPROT),
        .s_axi_arready (axi_vip_0_M_AXI_ARREADY),
        .s_axi_arvalid (axi_vip_0_M_AXI_ARVALID),
        .s_axi_awaddr  (axi_vip_0_M_AXI_AWADDR),
        .s_axi_awprot  (axi_vip_0_M_AXI_AWPROT),
        .s_axi_awready (axi_vip_0_M_AXI_AWREADY),
        .s_axi_awvalid (axi_vip_0_M_AXI_AWVALID),
        .s_axi_bready  (axi_vip_0_M_AXI_BREADY),
        .s_axi_bresp   (axi_vip_0_M_AXI_BRESP),
        .s_axi_bvalid  (axi_vip_0_M_AXI_BVALID),
        .s_axi_rdata   (axi_vip_0_M_AXI_RDATA),
        .s_axi_rready  (axi_vip_0_M_AXI_RREADY),
        .s_axi_rresp   (axi_vip_0_M_AXI_RRESP),
        .s_axi_rvalid  (axi_vip_0_M_AXI_RVALID),
        .s_axi_wdata   (axi_vip_0_M_AXI_WDATA),
        .s_axi_wready  (axi_vip_0_M_AXI_WREADY),
        .s_axi_wstrb   (axi_vip_0_M_AXI_WSTRB),
        .s_axi_wvalid  (axi_vip_0_M_AXI_WVALID),
        .s_axis_aclk   (aclk_0_1),
        .s_axis_aresetn(aresetn_0_1),
        .s_axis_tdata  (axi4stream_vip_0_M_AXIS_TDATA),
        .s_axis_tlast  (axi4stream_vip_0_M_AXIS_TLAST),
        .s_axis_tready (axi4stream_vip_0_M_AXIS_TREADY),
        .s_axis_tstrb  (axi4stream_vip_0_M_AXIS_TSTRB),
        .s_axis_tvalid (axi4stream_vip_0_M_AXIS_TVALID)
    );

    assign aresetn_0_1 = Rstn;
    assign aclk_0_1    = Clk;
    assign RxClk       = TxClk;
    assign SRx         = STx;

    xil_axi4stream_uint                               mst_agent_verbosity = 0;  // Master VIP agent verbosity level
    xil_axi4stream_uint                               slv_agent_verbosity = 0;  // Slave VIP agent verbosity level
    xil_axi_resp_t                                    resp;
    axi_vip_0_mst_t                                   axi_m_agent;
    axi4stream_vip_0_mst_t                            axis_m_agent;
    axi4stream_vip_1_slv_t                            axis_s_agent;

    reg                    [(C_S_AXI_DATA_WIDTH-1):0] wr_data = {C_S_AXI_DATA_WIDTH{1'b0}};
    reg                    [(C_S_AXI_ADDR_WIDTH-1):0] wr_addr = {C_S_AXI_ADDR_WIDTH{1'b0}};

    reg                    [(C_S_AXI_DATA_WIDTH-1):0] rd_data = {C_S_AXI_DATA_WIDTH{1'b0}};
    reg                    [(C_S_AXI_ADDR_WIDTH-1):0] rd_addr = {C_S_AXI_ADDR_WIDTH{1'b0}};

    reg                    [                     7:0] ii;
    initial begin
        begin
            axi_m_agent  = new("axi_lite_agent", axi_vip_0_dut.inst.IF);
            axis_m_agent = new("axi_stream_master_agent", axi4stream_vip_0_dut.inst.IF);
            axis_s_agent = new("axi_stream_slave_agent", axi4stream_vip_1_dut.inst.IF);

            axi_m_agent.start_master();
            axis_m_agent.start_master();
            axis_s_agent.start_slave();

            axis_m_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);
            axis_s_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);

            axis_m_agent.set_verbosity(mst_agent_verbosity);
            axis_s_agent.set_verbosity(slv_agent_verbosity);


            wait (aresetn_0_1);
            #100ns;
            wr_addr = 0;
            wr_data = 32'h00000309;
            axi_m_agent.AXI4LITE_WRITE_BURST(wr_addr, 0, wr_data, resp);
            rd_addr = 0;
            rd_data = 0;
            axi_m_agent.AXI4LITE_READ_BURST(rd_addr, 0, rd_data, resp);
            $display("read back,%8x", rd_data);

            #40ns;
            wr_addr = 4;
            wr_data = 32'h00000008;
            axi_m_agent.AXI4LITE_WRITE_BURST(wr_addr, 0, wr_data, resp);
            rd_addr = 4;
            rd_data = 0;
            axi_m_agent.AXI4LITE_READ_BURST(rd_addr, 0, rd_data, resp);
            $display("read back,%8x", rd_data);

            #100ns;
            wr_addr = 8;
            wr_data = 32'h0000030D;
            axi_m_agent.AXI4LITE_WRITE_BURST(wr_addr, 0, wr_data, resp);
            rd_addr = 8;
            rd_data = 0;
            axi_m_agent.AXI4LITE_READ_BURST(rd_addr, 0, rd_data, resp);
            $display("read back,%8x", rd_data);

            #40ns;
            rd_addr = 12;
            rd_data = 0;
            axi_m_agent.AXI4LITE_READ_BURST(rd_addr, 0, rd_data, resp);
            $display("read back,%8x", rd_data);


            #100ns;
            wr_addr = 0;
            wr_data = 32'h00001009;
            axi_m_agent.AXI4LITE_WRITE_BURST(wr_addr, 0, wr_data, resp);
            $display("request read a pack");
            rd_addr = 0;
            rd_data = 0;
            axi_m_agent.AXI4LITE_READ_BURST(rd_addr, 0, rd_data, resp);
            $display("read back,%8x", rd_data);


            #200ns;
            mst_gen_transaction(2);
            $display("master write pack");


            #4000ns;

            rd_addr = 8;
            rd_data = 0;
            axi_m_agent.AXI4LITE_READ_BURST(rd_addr, 0, rd_data, resp);
            $display("read back,%8x", rd_data);

            rd_addr = 12;
            rd_data = 0;
            axi_m_agent.AXI4LITE_READ_BURST(rd_addr, 0, rd_data, resp);
            $display("read length,%8x", rd_data);

            #100ns;
            wr_addr = 8;
            wr_data = 32'h0000040D;
            axi_m_agent.AXI4LITE_WRITE_BURST(wr_addr, 0, wr_data, resp);
            $display("request upload");
        end
    end

    /*************************************************************************************************************
  * Master VIP generates transaction:
  * Driver in master agent creates transaction
  * Randomized the transaction
  * Driver in master agent sends the transaction
  *************************************************************************************************************/
    task mst_gen_transaction(input int NUM);
        int                    ii;
        axi4stream_transaction wr_transaction;
        wr_transaction = axis_m_agent.driver.create_transaction("Master VIP write transaction");
        wr_transaction.set_xfer_alignment(XIL_AXI4STREAM_XFER_RANDOM);
        for (ii = 0; ii < NUM; ii = ii + 1) begin
            // if (ii == (NUM - 1)) wr_transaction.set_last(1'b1);
            WR_TRANSACTION_FAIL : assert (wr_transaction.randomize());
            axis_m_agent.driver.send(wr_transaction);
        end
        wait (wr_transaction.get_last());
    endtask



    // ***********************************************************************************
    // clock block
    always #(TIMEPERIOD / 2) Clk = !Clk;

    // reset block
    initial begin
        begin
            Rstn = 1'b0;
            #(TIMEPERIOD * 20);
            Rstn = 1'b1;
        end
    end

    // record block
    initial begin
        begin
            $dumpfile("test_tb.lxt");
            $dumpvars(0, sc_hdlc_v1_0_tb);
        end
    end

endmodule
