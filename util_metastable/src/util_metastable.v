
`timescale 1 ns / 1 ps

module util_metastable #(
    // edge type
    parameter C_EDGE_TYPE = "rising",  // "rising","falling", "both"
    parameter integer MAINTAIN_CYCLE = 1
) (
    input  wire clk,     // input clock
    input  wire rstn,    // input reset
    input  wire din,     // input signal
    output reg  dout,
    output reg  dout_r,  // output metastable
    output reg  dout_f   // output metastable
);

    wire p_edge;
    wire n_edge;
    reg [MAINTAIN_CYCLE:0] shift_reg;

    always @(posedge clk) begin
        if (rstn == 1'b0) begin
            shift_reg <= {(MAINTAIN_CYCLE + 1) {din}};
            dout_r    <= 1'b0;
            dout_f    <= 1'b0;
        end else begin
            shift_reg <= {shift_reg[(MAINTAIN_CYCLE-1):0], din};
            dout_r    <= p_edge;
            dout_f    <= n_edge;
        end
    end

    assign p_edge = ~(shift_reg[MAINTAIN_CYCLE]) & (&shift_reg[(MAINTAIN_CYCLE-1):0]);
    assign n_edge = (&shift_reg[MAINTAIN_CYCLE : 1]) & ~shift_reg[0];

    always @(posedge clk) begin
        if (rstn == 1'b0) begin
            dout <= 1'b0;
        end else begin
            if (C_EDGE_TYPE == "rising") begin
                dout <= p_edge;
            end else if (C_EDGE_TYPE == "falling") begin
                dout <= n_edge;
            end else if (C_EDGE_TYPE == "both") begin
                dout <= p_edge | n_edge;
            end else begin
                dout <= 1'b0;
            end
        end
    end
endmodule
