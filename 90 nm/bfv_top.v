//==============================================================================
// bfv_top.v 
// BFV Top Level with Pipelined FSM 
//==============================================================================
`timescale 1ns/1ps

module bfv_top #(
    parameter W      = 14,
    parameter Q      = 12289,
    parameter MSG_W  = 8,
    parameter T      = 256,
    parameter N_PIX  = 4096,
    parameter ADDR_W = 12
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,
    input  wire [W-1:0]  sk,       
    input  wire [W-1:0]  a_key,    
    input  wire [W-1:0]  e_key,    
    output reg           done,
    output reg  [3:0]    state_out, // Expanded to 4 bits
    output reg  [W-1:0]  dbg_pk1,
    output reg  [W-1:0]  dbg_pk2,
    output reg  [ADDR_W-1:0] dbg_pix_cnt
);
    // Memories
    (* ram_style = "block" *) reg [MSG_W-1:0]  pixel_mem    [0:N_PIX-1];
    (* ram_style = "block" *) reg [W-1:0]      enc_c1       [0:N_PIX-1];
    (* ram_style = "block" *) reg [W-1:0]      enc_c2       [0:N_PIX-1];
    (* ram_style = "block" *) reg [2*W-1:0]    enc_combined [0:N_PIX-1];

    // FSM States (Expanded)
    localparam [3:0]
        S_IDLE      = 4'd0,
        S_KEYGEN_W1 = 4'd1,
        S_KEYGEN_W2 = 4'd2,
        S_KEYGEN    = 4'd3,
        S_LOAD_PIX  = 4'd4,
        S_COMPUTE_1 = 4'd5,
        S_COMPUTE_2 = 4'd6,
        S_COMPUTE_3 = 4'd7,
        S_STORE_CT  = 4'd8,
        S_NEXT_PIX  = 4'd9,
        S_DONE      = 4'd10;

    reg [3:0]         state;
    reg [ADDR_W-1:0]  pix_cnt;
    localparam [ADDR_W-1:0] LAST_PIX = N_PIX - 1;

    // KeyGen
    reg  [W-1:0] pk1_r, pk2_r;
    wire [W-1:0] pk1_comb, pk2_comb;

    bfv_keygen #(.W(W), .Q(Q)) u_keygen (
        .clk(clk), .rst_n(rst_n),
        .sk(sk), .a(a_key), .e(e_key),
        .pk1(pk1_comb), .pk2(pk2_comb)
    );

    // LFSR
    reg  [15:0] lfsr;
    wire        lfsr_fb = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
    always @(posedge clk)
        if (!rst_n) lfsr <= 16'hACE1;
        else        lfsr <= {lfsr[14:0], lfsr_fb};

    wire [1:0]   u_sel = lfsr[1:0];
    wire [W-1:0] u_val = (u_sel == 2'b01) ? {{W-1{1'b0}}, 1'b1} : 
                         (u_sel == 2'b10) ? 14'd12288 : {W{1'b0}};

    wire [W-1:0] e1_raw = {{W-5{1'b0}}, lfsr[4:0]};
    wire [W-1:0] e2_raw = {{W-5{1'b0}}, lfsr[9:5]};
    wire [W-1:0] e1_val = (e1_raw > 10) ? 14'd10 : e1_raw;
    wire [W-1:0] e2_val = (e2_raw > 10) ? 14'd10 : e2_raw;

    // Encrypt Core
    reg  [MSG_W-1:0] cur_msg;
    wire [W-1:0]     c1_w, c2_w;

    bfv_encrypt_core #(
        .W(W), .Q(Q), .MSG_W(MSG_W), .T(T)
    ) u_enc (
        .clk(clk), .rst_n(rst_n),
        .pk1(pk1_r), .pk2(pk2_r),
        .u(u_val), .e1(e1_val), .e2(e2_val),
        .msg(cur_msg), .c1(c1_w), .c2(c2_w)
    );

    // FSM
    always @(posedge clk) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            pix_cnt     <= 0;
            done        <= 0;
            pk1_r       <= 0;
            pk2_r       <= 0;
            cur_msg     <= 0;
            dbg_pk1     <= 0;
            dbg_pk2     <= 0;
            dbg_pix_cnt <= 0;
            state_out   <= S_IDLE;
        end else begin
            state_out <= state;
            case (state)
                S_IDLE: begin
                    if (start) begin
                        done  <= 1'b0;
                        state <= S_KEYGEN_W1;
                    end
                end

                // Wait for the KeyGen pipeline to flush valid data
                S_KEYGEN_W1: state <= S_KEYGEN_W2;
                S_KEYGEN_W2: state <= S_KEYGEN;

                S_KEYGEN: begin
                    pk1_r       <= pk1_comb;
                    pk2_r       <= pk2_comb;
                    dbg_pk1     <= pk1_comb;
                    dbg_pk2     <= pk2_comb;
                    pix_cnt     <= 0;
                    state       <= S_LOAD_PIX;
                end

                S_LOAD_PIX: begin
                    cur_msg     <= pixel_mem[pix_cnt];
                    dbg_pix_cnt <= pix_cnt;
                    state       <= S_COMPUTE_1;
                end

                // Wait for pipelined multiplier to process
                S_COMPUTE_1: state <= S_COMPUTE_2;
                S_COMPUTE_2: state <= S_COMPUTE_3;
                
                // Final combinational addition settles here
                S_COMPUTE_3: state <= S_STORE_CT;

                S_STORE_CT: begin
                    enc_c1      [pix_cnt] <= c1_w;
                    enc_c2      [pix_cnt] <= c2_w;
                    enc_combined[pix_cnt] <= {c1_w, c2_w};
                    state                 <= S_NEXT_PIX;
                end

                S_NEXT_PIX: begin
                    if (pix_cnt == LAST_PIX) state <= S_DONE;
                    else begin
                        pix_cnt <= pix_cnt + 1'b1;
                        state   <= S_LOAD_PIX;
                    end
                end

                S_DONE: begin
                    done <= 1'b1;
                    if (start) begin
                        done  <= 1'b0;
                        state <= S_KEYGEN_W1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule