///////////////////////////////////////////////////////////////////////
// File: crypto_aes64.sv
// Date: 2024-04-02
// Author: Behnam Farnaghinejad <behnam.farnaghinejad@polito.it>
// This file contains a converted version of the original 
// file from the riscv-crypto repository.
///////////////////////////////////////////////////////////////////////

//------------------------------- Sail model -------------------------------------------
/*
function clause execute (AES64DS(rs2, rs1, rd)) = {
  let sr : bits(64) = aes_rv64_shiftrows_inv(X(rs2)[63..0], X(rs1)[63..0]);
  let wd : bits(64) = sr[63..0];
  X(rd) = aes_apply_inv_sbox_to_each_byte(wd);
  RETIRE_SUCCESS
}

function clause execute (AES64DSM(rs2, rs1, rd)) = {
  let sr : bits(64) = aes_rv64_shiftrows_inv(X(rs2)[63..0], X(rs1)[63..0]);
  let wd : bits(64) = sr[63..0];
  let sb : bits(64) = aes_apply_inv_sbox_to_each_byte(wd);
  X(rd) = aes_mixcolumn_inv(sb[63..32]) @ aes_mixcolumn_inv(sb[31..0]);
  RETIRE_SUCCESS
}

function clause execute (AES64ES(rs2, rs1, rd)) = {
  let sr : bits(64) = aes_rv64_shiftrows_fwd(X(rs2)[63..0], X(rs1)[63..0]);
  let wd : bits(64) = sr[63..0];
  X(rd) = aes_apply_fwd_sbox_to_each_byte(wd);
  RETIRE_SUCCESS
}

function clause execute (AES64ESM(rs2, rs1, rd)) = {
  let sr : bits(64) = aes_rv64_shiftrows_fwd(X(rs2)[63..0], X(rs1)[63..0]);
  let wd : bits(64) = sr[63..0];
  let sb : bits(64) = aes_apply_fwd_sbox_to_each_byte(wd);
  X(rd) = aes_mixcolumn_fwd(sb[63..32]) @ aes_mixcolumn_fwd(sb[31..0]);
  RETIRE_SUCCESS
}

function clause execute (AES64IM(rs1, rd)) = {
  let w0 : bits(32) = aes_mixcolumn_inv(X(rs1)[31.. 0]);
  let w1 : bits(32) = aes_mixcolumn_inv(X(rs1)[63..32]);
  X(rd) = w1 @ w0;
  RETIRE_SUCCESS
}

function clause execute (AES64KS1I(rnum, rs1, rd)) = {
  if(unsigned(rnum) > 10) then {
  handle_illegal(); RETIRE_SUCCESS
  } else {
  let tmp1 : bits(32) = X(rs1)[63..32];
  let rc : bits(32) = aes_decode_rcon(rnum); // round number -> round constant

  let tmp2 : bits(32) = if (rnum ==0xA) then tmp1 else ror32(tmp1, 8);
  let tmp3 : bits(32) = aes_subword_fwd(tmp2);
  let result : bits(64) = (tmp3 ^ rc) @ (tmp3 ^ rc);
  X(rd) = EXTZ(result);
  RETIRE_SUCCESS
  }
}

function clause execute (AES64KS2(rs2, rs1, rd)) = {
  let w0 : bits(32) = X(rs1)[63..32] ^ X(rs2)[31..0];
  let w1 : bits(32) = X(rs1)[63..32] ^ X(rs2)[31..0] ^ X(rs2)[63..32];
  X(rd) = w1 @ w0;
  RETIRE_SUCCESS
}

*/
//-------------------------------------------------------------------------------------
module crypto_aes64
  import crypto_instr_pkg::*;

(
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             aes64_en_i,
    input  aes64_t           aes64_op_i,
    input  logic [XLEN-1:0]  aes64_rs1_i,
    input  logic [XLEN-1:0]  aes64_rs2_i,
    input  logic [XLEN-1:0]  aes64_rs3_i,
    input  logic [XLEN-1:0]  aes64_rs4_i,
    input logic              valid_i,
    input  logic [3:0]       aes64_rnum_i,
    input  logic [17:0]      randombits_i [7:0],
    output logic [XLEN-1:0]  aes64_result_share0_o, 
    output logic [XLEN-1:0]  aes64_result_share1_o
);

    // Select I'th byte of X.
    `define BY(X,I) X[7+8*I:8*I]

    logic ready_for_sbox_i;
    logic valid_o_sbox [7:0];
    logic ready_for_sbox_o [7:0];

    assign ready_for_sbox_i = 1'b1;



    logic [XLEN-1:0] input0_share0, input0_share1, input1_share0, input1_share1;

    assign input0_share0 = aes64_rs1_i;
    assign input0_share1 = aes64_rs3_i;
    assign input1_share0 = aes64_rs2_i;
    assign input1_share1 = aes64_rs4_i;

    // --------------------------------------- Key Schedule ---------------------------------------

    logic [7:0] ks1_sb3, ks1_sb3_share0, ks1_sb3_share1;
    logic [7:0] ks1_sb2, ks1_sb2_share0, ks1_sb2_share1;
    logic [7:0] ks1_sb1, ks1_sb1_share0, ks1_sb1_share1;
    logic [7:0] ks1_sb0, ks1_sb0_share0, ks1_sb0_share1;

    //Round Constants
    localparam logic [7:0] rcon [0:15] = '{8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80, 8'h1b, 8'h36, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};

    logic [3:0] enc_rcon;
    logic rcon_rot;
    logic [7:0] rconst;
    logic [7:0] rconst_q1, rconst_q2, rconst_q3, rconst_q4, rconst_q5;

    logic [31:0] ks1_sbout_share0, ks1_sbout_share1;

    assign enc_rcon = aes64_rnum_i;
    assign rcon_rot = enc_rcon != 4'hA;
    assign rconst = rcon_rot ? rcon[enc_rcon] : 8'b0;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            rconst_q1 = '0;
        end
        else begin
            rconst_q1  <= rconst;
            rconst_q2  <= rconst_q1;
            rconst_q3  <= rconst_q2;
            rconst_q4  <= rconst_q3;
            rconst_q5  <= rconst_q4;

        end
    end


    assign ks1_sb3_share0 = input0_share0[39:32];
    assign ks1_sb3_share1 = input0_share1[39:32];

    assign ks1_sb2_share0 = input0_share0[63:56];
    assign ks1_sb2_share1 = input0_share1[63:56];

    assign ks1_sb1_share0 = input0_share0[55:48];
    assign ks1_sb1_share1 = input0_share1[55:48];

    assign ks1_sb0_share0 = input0_share0[47:40];
    assign ks1_sb0_share1 = input0_share1[47:40];

    assign ks1_sbout_share0 = e_sbout_share0[31:0]^{24'b0, rconst_q5};
    assign ks1_sbout_share1 = e_sbout_share1[31:0];

    // --------------------------- Constructing rows from input registers ----------------------------

    logic [31:0] row_0_share0, row_0_share1;
    logic [31:0] row_1_share0, row_1_share1;
    logic [31:0] row_2_share0, row_2_share1;
    logic [31:0] row_3_share0, row_3_share1;


    assign  row_0_share0   = {`BY(input0_share0,0),`BY(input0_share0,4),`BY(input1_share0,0),`BY(input1_share0,4)};
    assign  row_1_share0   = {`BY(input0_share0,1),`BY(input0_share0,5),`BY(input1_share0,1),`BY(input1_share0,5)};
    assign  row_2_share0   = {`BY(input0_share0,2),`BY(input0_share0,6),`BY(input1_share0,2),`BY(input1_share0,6)};
    assign  row_3_share0   = {`BY(input0_share0,3),`BY(input0_share0,7),`BY(input1_share0,3),`BY(input1_share0,7)};

    assign  row_0_share1   = {`BY(input0_share1,0),`BY(input0_share1,4),`BY(input1_share1,0),`BY(input1_share1,4)};
    assign  row_1_share1   = {`BY(input0_share1,1),`BY(input0_share1,5),`BY(input1_share1,1),`BY(input1_share1,5)};
    assign  row_2_share1   = {`BY(input0_share1,2),`BY(input0_share1,6),`BY(input1_share1,2),`BY(input1_share1,6)};
    assign  row_3_share1   = {`BY(input0_share1,3),`BY(input0_share1,7),`BY(input1_share1,3),`BY(input1_share1,7)};

    // --------------------------------------- Encryption Phase ---------------------------------------
    //Shift rows
    logic [31:0] fsh_0_share0, fsh_0_share1;                      
    logic [31:0] fsh_1_share0, fsh_1_share1;
    logic [31:0] fsh_2_share0, fsh_2_share1;
    logic [31:0] fsh_3_share0, fsh_3_share1;

    assign  fsh_0_share0   =  row_0_share0;                      
    assign  fsh_1_share0   = {row_1_share0[23: 0], row_1_share0[31:24]};
    assign  fsh_2_share0   = {row_2_share0[15: 0], row_2_share0[31:16]};
    assign  fsh_3_share0   = {row_3_share0[ 7: 0], row_3_share0[31: 8]};

    assign  fsh_0_share1   =  row_0_share1;                      
    assign  fsh_1_share1   = {row_1_share1[23: 0], row_1_share1[31:24]};
    assign  fsh_2_share1   = {row_2_share1[15: 0], row_2_share1[31:16]};
    assign  fsh_3_share1   = {row_3_share1[ 7: 0], row_3_share1[31: 8]};

    //Re-construct columns from rows
    logic [31:0] f_col_1_share0, f_col_1_share1;
    logic [31:0] f_col_0_share0, f_col_0_share1;

    assign  f_col_1_share0 = {`BY(fsh_3_share0,2),`BY(fsh_2_share0,2),`BY(fsh_1_share0,2),`BY(fsh_0_share0,2)};
    assign  f_col_0_share0 = {`BY(fsh_3_share0,3),`BY(fsh_2_share0,3),`BY(fsh_1_share0,3),`BY(fsh_0_share0,3)};
    
    assign  f_col_1_share1 = {`BY(fsh_3_share1,2),`BY(fsh_2_share1,2),`BY(fsh_1_share1,2),`BY(fsh_0_share1,2)};
    assign  f_col_0_share1 = {`BY(fsh_3_share1,3),`BY(fsh_2_share1,3),`BY(fsh_1_share1,3),`BY(fsh_0_share1,3)};


    logic [63:0] shiftrows_enc_share0, shiftrows_enc_share1 ;

    assign  shiftrows_enc_share0 = {f_col_1_share0, f_col_0_share0};
    assign  shiftrows_enc_share1 = {f_col_1_share1, f_col_0_share1};

    //SBox input/output
    logic [ 7:0] sb_fwd_in_share0  [7:0];
    logic [ 7:0] sb_fwd_out_share0 [7:0];
    logic [ 7:0] sb_fwd_in_share1  [7:0];
    logic [ 7:0] sb_fwd_out_share1 [7:0];

    assign      sb_fwd_in_share0[0]= (aes64_op_i == aes64_ks1i) ? ks1_sb0_share0 : `BY(shiftrows_enc_share0, 0);
    assign      sb_fwd_in_share1[0]= (aes64_op_i == aes64_ks1i) ? ks1_sb0_share1 : `BY(shiftrows_enc_share1, 0);

    assign      sb_fwd_in_share0[1]= (aes64_op_i == aes64_ks1i) ? ks1_sb1_share0 : `BY(shiftrows_enc_share0, 1);
    assign      sb_fwd_in_share1[1]= (aes64_op_i == aes64_ks1i) ? ks1_sb1_share1 : `BY(shiftrows_enc_share1, 1);

    assign      sb_fwd_in_share0[2]= (aes64_op_i == aes64_ks1i) ? ks1_sb2_share0 : `BY(shiftrows_enc_share0, 2);
    assign      sb_fwd_in_share1[2]= (aes64_op_i == aes64_ks1i) ? ks1_sb2_share1 : `BY(shiftrows_enc_share1, 2);

    assign      sb_fwd_in_share0[3]= (aes64_op_i == aes64_ks1i) ? ks1_sb3_share0 : `BY(shiftrows_enc_share0, 3);
    assign      sb_fwd_in_share1[3]= (aes64_op_i == aes64_ks1i) ? ks1_sb3_share1 : `BY(shiftrows_enc_share1, 3);

    assign      sb_fwd_in_share0[4]=                                        `BY(shiftrows_enc_share0, 4);
    assign      sb_fwd_in_share1[4]=                                        `BY(shiftrows_enc_share1, 4);
    assign      sb_fwd_in_share0[5]=                                        `BY(shiftrows_enc_share0, 5);
    assign      sb_fwd_in_share1[5]=                                        `BY(shiftrows_enc_share1, 5);
    assign      sb_fwd_in_share0[6]=                                        `BY(shiftrows_enc_share0, 6);
    assign      sb_fwd_in_share1[6]=                                        `BY(shiftrows_enc_share1, 6);
    assign      sb_fwd_in_share0[7]=                                        `BY(shiftrows_enc_share0, 7);
    assign      sb_fwd_in_share1[7]=                                        `BY(shiftrows_enc_share1, 7);

    dom_sbox i_fwd_dom_sbox0 (
        .clk_i            (clk_i),
        .rst_n            (rst_ni),
        .valid_i          (valid_i),
        .ready_for_sbox_i (ready_for_sbox_i),
        .shareA_in        (sb_fwd_in_share0[0]),
        .shareB_in        (sb_fwd_in_share1[0]),
        .randombits_i     (randombits_i[0]),
        .valid_o          (valid_o_sbox[0]),
        .ready_for_sbox_o (aes64_en_q4),
        .shareA_out       (sb_fwd_out_share0[0]),
        .shareB_out       (sb_fwd_out_share1[0])
      );

    dom_sbox i_fwd_dom_sbox1 (
        .clk_i            (clk_i),
        .rst_n            (rst_ni),
        .valid_i          (valid_i),
        .ready_for_sbox_i (ready_for_sbox_i),
        .shareA_in        (sb_fwd_in_share0[1]),
        .shareB_in        (sb_fwd_in_share1[1]),
        .randombits_i     (randombits_i[1]),
        .valid_o          (valid_o_sbox[1]),
        .ready_for_sbox_o (aes64_en_q4),
        .shareA_out       (sb_fwd_out_share0[1]),
        .shareB_out       (sb_fwd_out_share1[1])
      );

    dom_sbox i_fwd_dom_sbox2 (
        .clk_i            (clk_i),
        .rst_n            (rst_ni),
        .valid_i          (valid_i),
        .ready_for_sbox_i (ready_for_sbox_i),
        .shareA_in        (sb_fwd_in_share0[2]),
        .shareB_in        (sb_fwd_in_share1[2]),
        .randombits_i     (randombits_i[2]),
        .valid_o          (valid_o_sbox[2]),
        .ready_for_sbox_o (aes64_en_q4),
        .shareA_out       (sb_fwd_out_share0[2]),
        .shareB_out       (sb_fwd_out_share1[2])
      );


    dom_sbox i_fwd_dom_sbox3 (
        .clk_i            (clk_i),
        .rst_n            (rst_ni),
        .valid_i          (valid_i),
        .ready_for_sbox_i (ready_for_sbox_i),
        .shareA_in        (sb_fwd_in_share0[3]),
        .shareB_in        (sb_fwd_in_share1[3]),
        .randombits_i     (randombits_i[3]),
        .valid_o          (valid_o_sbox[3]),
        .ready_for_sbox_o (aes64_en_q4),
        .shareA_out       (sb_fwd_out_share0[3]),
        .shareB_out       (sb_fwd_out_share1[3])
      );

    dom_sbox i_fwd_dom_sbox4 (
        .clk_i            (clk_i),
        .rst_n            (rst_ni),
        .valid_i          (valid_i),
        .ready_for_sbox_i (ready_for_sbox_i),
        .shareA_in        (sb_fwd_in_share0[4]),
        .shareB_in        (sb_fwd_in_share1[4]),
        .randombits_i     (randombits_i[4]),
        .valid_o          (valid_o_sbox[4]),
        .ready_for_sbox_o (aes64_en_q4),
        .shareA_out       (sb_fwd_out_share0[4]),
        .shareB_out       (sb_fwd_out_share1[4])
      );

    dom_sbox i_fwd_dom_sbox5 (
        .clk_i            (clk_i),
        .rst_n            (rst_ni),
        .valid_i          (valid_i),
        .ready_for_sbox_i (ready_for_sbox_i),
        .shareA_in        (sb_fwd_in_share0[5]),
        .shareB_in        (sb_fwd_in_share1[5]),
        .randombits_i     (randombits_i[5]),
        .valid_o          (valid_o_sbox[5]),
        .ready_for_sbox_o (aes64_en_q4),
        .shareA_out       (sb_fwd_out_share0[5]),
        .shareB_out       (sb_fwd_out_share1[5])
      );

    dom_sbox i_fwd_dom_sbox6 (
        .clk_i            (clk_i),
        .rst_n            (rst_ni),
        .valid_i          (valid_i),
        .ready_for_sbox_i (ready_for_sbox_i),
        .shareA_in        (sb_fwd_in_share0[6]),
        .shareB_in        (sb_fwd_in_share1[6]),
        .randombits_i     (randombits_i[6]),
        .valid_o          (valid_o_sbox[6]),
        .ready_for_sbox_o (aes64_en_q4),
        .shareA_out       (sb_fwd_out_share0[6]),
        .shareB_out       (sb_fwd_out_share1[6])
      );


    dom_sbox i_fwd_dom_sbox7 (
        .clk_i            (clk_i),
        .rst_n            (rst_ni),
        .valid_i          (valid_i),
        .ready_for_sbox_i (ready_for_sbox_i),
        .shareA_in        (sb_fwd_in_share0[7]),
        .shareB_in        (sb_fwd_in_share1[7]),
        .randombits_i     (randombits_i[7]),
        .valid_o          (valid_o_sbox[7]),
        .ready_for_sbox_o (aes64_en_q4),
        .shareA_out       (sb_fwd_out_share0[7]),
        .shareB_out       (sb_fwd_out_share1[7])
      );


    logic [63:0] e_sbout_share0, e_sbout_share1;

    assign e_sbout_share0 = {
        sb_fwd_out_share0[7], sb_fwd_out_share0[6], sb_fwd_out_share0[5], sb_fwd_out_share0[4],
        sb_fwd_out_share0[3], sb_fwd_out_share0[2], sb_fwd_out_share0[1], sb_fwd_out_share0[0] 
    };
    assign e_sbout_share1 = {
        sb_fwd_out_share1[7], sb_fwd_out_share1[6], sb_fwd_out_share1[5], sb_fwd_out_share1[4],
        sb_fwd_out_share1[3], sb_fwd_out_share1[2], sb_fwd_out_share1[1], sb_fwd_out_share1[0] 
    };
    //MixColumns 
    logic [31:0] mix_enc_i0_share0, mix_enc_i0_share1;
    logic [31:0] mix_enc_i1_share0, mix_enc_i1_share1;


    assign  mix_enc_i0_share0  =   e_sbout_share0[31: 0];
    assign  mix_enc_i0_share1  =   e_sbout_share0[63: 32];

    assign  mix_enc_i1_share0  =   e_sbout_share1[31:0];
    assign  mix_enc_i1_share1  =   e_sbout_share1[63:32];

    logic [31:0] mix_enc_o0_share0, mix_enc_o0_share1;
    logic [31:0] mix_enc_o1_share0, mix_enc_o1_share1;

    crypto_aes_mixcolumn_enc i_mix_e0_share0(
        .column_in (mix_enc_i0_share0),
        .column_out(mix_enc_o0_share0)
    );
    crypto_aes_mixcolumn_enc i_mix_e0_share1(
        .column_in (mix_enc_i0_share1),
        .column_out(mix_enc_o0_share1)
    );

    crypto_aes_mixcolumn_enc i_mix_e1_share0(
        .column_in (mix_enc_i1_share0),
        .column_out(mix_enc_o1_share0)
    );
    crypto_aes_mixcolumn_enc i_mix_e1_share1(
        .column_in (mix_enc_i1_share1),
        .column_out(mix_enc_o1_share1)
    );


    // --------------------------------------- Result gathering ---------------------------------------

    logic [63:0] result_ks1_share0, result_ks1_share1;

    assign result_ks1_share0 = {ks1_sbout_share0, ks1_sbout_share0};
    assign result_ks1_share1 = {ks1_sbout_share1, ks1_sbout_share1};

    logic [63:0] result_ks2_share0, result_ks2_share1;

    assign result_ks2_share0 = {
        input0_share0[63:32] ^ input1_share0[63:32] ^ input1_share0[31:0],
        input0_share0[63:32] ^ input1_share0[31:0]
    };

    assign result_ks2_share1 = {
        input0_share1[63:32] ^ input1_share1[63:32] ^ input1_share1[31:0],
        input0_share1[63:32] ^ input1_share1[31:0]
    };

    logic [63:0] result_enc_share0, result_enc_share1;

    assign result_enc_share0 = { mix_enc_o0_share1, mix_enc_o0_share0 };
    assign result_enc_share1 = { mix_enc_o1_share1, mix_enc_o1_share0 };

    logic [5:0] aes64_op_q1, aes64_op_q2, aes64_op_q3, aes64_op_q4, aes64_op_q5;
    logic aes64_en_q1, aes64_en_q2, aes64_en_q3, aes64_en_q4, aes64_en_q5;
  
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            aes64_op_q1 <= '0;   aes64_op_q2 <= '0; aes64_op_q3 <= '0; aes64_op_q4 <= '0;
            aes64_op_q5 <= '0;   aes64_en_q1 <= '0; aes64_en_q2 <= '0; aes64_en_q3 <= '0;
            aes64_en_q4 <= '0;   aes64_en_q5 <= '0; 
        end
        else begin
            aes64_op_q1 <= aes64_op_i;
            aes64_en_q1 <= aes64_en_i;

            aes64_op_q2 <= aes64_op_q1;
            aes64_en_q2 <= aes64_en_q1;

            aes64_op_q3 <= aes64_op_q2;
            aes64_en_q3 <= aes64_en_q2;

            aes64_op_q4 <= aes64_op_q3;
            aes64_en_q4 <= aes64_en_q3;

            aes64_op_q5 <= aes64_op_q4;
            aes64_en_q5 <= aes64_en_q4;
        end
    end
    
    
    always_comb begin
    aes64_result_share0_o = '0;
    aes64_result_share1_o = '0;

    // 1) If we are currently doing a KS2 instruction, use aes64_en_i / aes64_op_i
    if (aes64_en_i && (aes64_op_i == aes64_ks2)) begin
        aes64_result_share0_o = result_ks2_share0;
        aes64_result_share1_o = result_ks2_share1;
    end 
    // 2) Otherwise, use the 5-cycle-delayed signals
    else if (aes64_en_q5) begin
        case (aes64_op_q5)
        aes64_ks1i: begin 
            aes64_result_share0_o = result_ks1_share0;
            aes64_result_share1_o = result_ks1_share1;
        end
        aes64_es: begin
            aes64_result_share0_o = e_sbout_share0;
            aes64_result_share1_o = e_sbout_share1;           
        end
        aes64_esm: begin 
            aes64_result_share0_o = result_enc_share0;
            aes64_result_share1_o = result_enc_share1;
        end
        default: begin
            aes64_result_share0_o = '0;
            aes64_result_share1_o = '0;
        end
        endcase
    end
    // 3) If neither condition is met, outputs remain zero
    end

    `undef BY

endmodule