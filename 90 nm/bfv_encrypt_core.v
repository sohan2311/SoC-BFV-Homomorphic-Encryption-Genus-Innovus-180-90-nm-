//==============================================================================
// bfv_encrypt_core.v
// BFV Encryption Core
//==============================================================================
`timescale 1ns/1ps

module bfv_encrypt_core #(
    parameter W     = 14,
    parameter Q     = 12289,
    parameter MSG_W = 8,
    parameter T     = 256
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [W-1:0]     pk1,
    input  wire [W-1:0]     pk2,
    input  wire [W-1:0]     u,
    input  wire [W-1:0]     e1,
    input  wire [W-1:0]     e2,
    input  wire [MSG_W-1:0] msg,
    output wire [W-1:0]     c1,
    output wire [W-1:0]     c2
);
    localparam [W-1:0] DELTA = Q / T;
    wire [W-1:0] msg_w = {{(W-MSG_W){1'b0}}, msg};

    // PK1 * u mod Q (Pipelined)
    wire [W-1:0] pk1_u;
    bfv_mod_mult #(.W(W), .Q(Q)) u_mult_pk1u (
        .clk(clk), .rst_n(rst_n),
        .a(pk1), .b(u), .result(pk1_u)
    );

    // Delta * M mod Q (Pipelined)
    wire [W-1:0] delta_m;
    bfv_mod_mult #(.W(W), .Q(Q)) u_mult_dm (
        .clk(clk), .rst_n(rst_n),
        .a(DELTA), .b(msg_w), .result(delta_m)
    );

    // PK1*u + e1 mod Q
    wire [W-1:0] pk1u_e1;
    bfv_mod_adder #(.W(W), .Q(Q)) u_add_e1 (
        .a(pk1_u), .b(e1), .result(pk1u_e1)
    );

    // (PK1*u + e1) + Delta*M mod Q = C1
    bfv_mod_adder #(.W(W), .Q(Q)) u_add_dm (
        .a(pk1u_e1), .b(delta_m), .result(c1)
    );

    // PK2 * u mod Q (Pipelined)
    wire [W-1:0] pk2_u;
    bfv_mod_mult #(.W(W), .Q(Q)) u_mult_pk2u (
        .clk(clk), .rst_n(rst_n),
        .a(pk2), .b(u), .result(pk2_u)
    );

    // PK2*u + e2 mod Q = C2
    bfv_mod_adder #(.W(W), .Q(Q)) u_add_e2 (
        .a(pk2_u), .b(e2), .result(c2)
    );

endmodule