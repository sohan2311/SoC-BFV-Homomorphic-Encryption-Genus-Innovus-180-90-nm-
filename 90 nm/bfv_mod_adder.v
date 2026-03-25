//==============================================================================
// bfv_mod_adder.v
// Modular Adder: result = (a + b) mod Q
// Used in KeyGen and Encrypt operations.
//==============================================================================
`timescale 1ns/1ps

module bfv_mod_adder #(
    parameter W = 14,
    parameter Q = 12289
)(
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output wire [W-1:0] result
);
    localparam [W:0] Q_EXT = Q;

    wire [W:0] sum;
    wire [W:0] sum_minus_q;

    assign sum         = {1'b0, a} + {1'b0, b};
    assign sum_minus_q = sum - Q_EXT;

    assign result = (sum >= Q_EXT) ? sum_minus_q[W-1:0] : sum[W-1:0];

endmodule