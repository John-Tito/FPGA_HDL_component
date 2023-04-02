// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module native2stream #(
    parameter integer WIDTH = 16
) (
    input  wire                 clk,            //
    input  wire                 rstn,           //
    //
    input  wire [      WIDTH:0] fifo_data,      //
    input  wire                 fifo_empty,     //
    output wire                 fifo_rd,        //
    //
    input  wire                 m_axis_tready,  //
    output reg                  m_axis_tvalid,  //
    output wire [  (WIDTH-1):0] m_axis_tdata,   //
    output wire [(WIDTH/8-1):0] m_axis_tkeep,   //
    output wire                 m_axis_tlast    //
);

    wire data_read_out;
    assign data_read_out = m_axis_tvalid & m_axis_tready;
    assign m_axis_tkeep  = {(WIDTH / 8) {1'b1}};
    assign m_axis_tdata  = fifo_data[(WIDTH-1):0];
    assign m_axis_tlast  = fifo_data[WIDTH];

    assign fifo_rd       = ~fifo_empty & ((!m_axis_tvalid) | (data_read_out));
    always @(posedge clk) begin
        if (!rstn) begin
            m_axis_tvalid <= 1'b0;
        end else begin
            if (fifo_rd) begin
                m_axis_tvalid <= 1'b1;
            end else if (data_read_out && !fifo_rd) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

endmodule

// verilog_format: off
`resetall
// verilog_format: on
