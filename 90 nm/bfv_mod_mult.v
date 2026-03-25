//==============================================================================
// bfv_mod_mult.v
// Modular Multiplier: result = (a * b) mod Q
// Pipelined to 2 stages to resolve 180nm setup timing violations.
//==============================================================================
`timescale 1ns/1ps

module bfv_mod_mult #(
    parameter W = 14,
    parameter Q = 12289
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [W-1:0]     a,
    input  wire [W-1:0]     b,
    output reg  [W-1:0]     result
);
    // Pipeline register for the 28-bit product
    reg [2*W-1:0] product_pipe;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product_pipe <= 0;
            result       <= 0;
        end else begin
            // Stage 1: Multiplication
            product_pipe <= a * b;
            // Stage 2: Modulo Reduction
            result       <= product_pipe % Q;
        end
    end

endmodule