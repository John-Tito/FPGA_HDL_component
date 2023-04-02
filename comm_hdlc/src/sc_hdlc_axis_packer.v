// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module sc_hdlc_axis_packer (
    input wire clk,
    input wire rstn, //

    input  wire upload_req,   //
    output reg  upload_busy,  //
    output reg  upload_done,  //
    output wire skip_arb,

    input  wire m_axis_tvalid,
    input  wire m_axis_tready,
    output wire m_axis_tvalid1,
    output wire m_axis_tready1,
    input  wire m_axis_tlast
);

    always @(posedge clk) begin
        if (!rstn) begin
            upload_busy <= 1'b0;
        end else begin
            if (upload_req) begin
                upload_busy <= 1'b1;
            end else if (m_axis_tlast & m_axis_tvalid & m_axis_tready1) begin
                upload_busy <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (!rstn) begin
            upload_done <= 1'b0;
        end else begin
            if (m_axis_tlast & m_axis_tvalid & m_axis_tready1) begin
                upload_done <= 1'b1;
            end else begin
                upload_done <= 1'b0;
            end
        end
    end

    assign skip_arb       = ~upload_busy;
    assign m_axis_tready1 = upload_busy & m_axis_tready;
    assign m_axis_tvalid1 = upload_busy & m_axis_tvalid;
endmodule

// verilog_format: off
`resetall
// verilog_format: on
