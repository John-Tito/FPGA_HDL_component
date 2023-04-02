// verilog_format: off
`resetall
`timescale 1ns / 1ps
`default_nettype none
// verilog_format: on

module HDLC_SERIAL_CRC #(
    parameter integer WIDTH = 16,
    parameter POLY = 17'h11021,
    parameter INIT = 16'hFFFF
) (
    input  wire                Clk,        // clock
    input  wire                Rstn,       // low active reset
    input  wire                En,         // high cative enable
    input  wire                Clr,        // high active clear
    input  wire                SData,      // serial data input
    output wire [(WIDTH -1):0] PCRC,
    output wire                SCRC,
    output reg                 SCRCValid,
    output wire [(WIDTH -1):0] CRCCkeck
);  // crc out put

    reg [(WIDTH -1):0] CRCReg;

    reg [(WIDTH -1):0] ii;

    assign PCRC = CRCReg;
    assign SCRC = CRCReg[(WIDTH-1)];

    always @(posedge Clk) begin
        if (!Rstn || Clr) begin
            CRCReg <= INIT;  //clear crc register when reset or clear is valid
        end else if (En) begin
            CRCReg[0] <= CRCReg[(WIDTH-1)] ^ SData;
            for (ii = 1; ii < WIDTH; ii = ii + 1) begin
                CRCReg[ii] <= (POLY[ii]) ? (CRCReg[(WIDTH-1)] ^ SData ^ CRCReg[ii-1]) : CRCReg[ii-1];
            end
        end else begin
            CRCReg <= CRCReg;  // keep the crc value if En is invalid
        end
    end

    always @(posedge Clk) begin
        if (!Rstn || Clr) begin
            SCRCValid <= 1'b0;
        end else if (En) begin
            SCRCValid <= 1'b1;
        end else begin
            SCRCValid <= 1'b0;
        end
    end

    // function [(WIDTH -1):0] CRC_Remainder;
    //     input integer width;
    //     integer kk;
    //     reg     tmp;
    //     begin
    //         CRC_Remainder = INIT;
    //         for (ii = 0; ii < width; ii = ii + 1) begin
    //             tmp = CRC_Remainder[width-1];
    //             for (kk = width - 1; kk >= 1; kk = kk - 1) begin
    //                 CRC_Remainder[kk] = (POLY[kk]) ? (CRC_Remainder[(kk-1)] ^ tmp) : CRC_Remainder[kk-1];
    //             end
    //             CRC_Remainder[0] = tmp;
    //         end
    //     end
    // endfunction

    // assign CRCCkeck = CRC_Remainder(WIDTH);
    assign CRCCkeck = 16'h1d0f;
endmodule

// verilog_format: off
`resetall
// verilog_format: on
