//==============================================================================
// bfv_keygen.v
// BFV Key Generation
//==============================================================================
`timescale 1ns/1ps

module bfv_keygen #(
    parameter W = 14,
    parameter Q = 12289
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [W-1:0] sk,
    input  wire [W-1:0] a,
    input  wire [W-1:0] e,
    output wire [W-1:0] pk1,
    output wire [W-1:0] pk2
);
    // Step 1: a * SK mod Q (Pipelined, takes 2 cycles)
    wire [W-1:0] a_times_sk;
    bfv_mod_mult #(.W(W), .Q(Q)) u_mult_ask (
        .clk(clk), .rst_n(rst_n),
        .a(a), .b(sk), .result(a_times_sk)
    );

    // Step 2: (a*SK + e) mod Q
    wire [W-1:0] ask_plus_e;
    bfv_mod_adder #(.W(W), .Q(Q)) u_add_e (
        .a(a_times_sk), .b(e), .result(ask_plus_e)
    );

    // Step 3: PK1 = -(a*SK + e) mod Q
    localparam [W-1:0] Q_W = Q;
    assign pk1 = (ask_plus_e == {W{1'b0}}) ? {W{1'b0}} : (Q_W - ask_plus_e);

    // PK2 = a
    assign pk2 = a;

endmodule