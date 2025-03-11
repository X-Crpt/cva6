///////////////////////////////////////////////////////////////////////
// File: crypto_aes32.sv
// Date: 2024-04-02
// Author: Behnam Farnaghinejad <behnam.farnaghinejad@polito.it>
// This file contains a converted version of the original 
// file from the riscv-crypto repository.
///////////////////////////////////////////////////////////////////////

//------------------------------- Sail model -------------------------------------------
/*
function clause execute (AES32DSI (bs,rs2,rs1,rd)) = {
  let shamt : bits( 5) = bs @ 0b000; // shamt = bs*8 
  let si : bits( 8) = (X(rs2)[31..0] >> shamt)[7..0]; // SBox Input 
  let so : bits(32) = 0x000000 @ aes_sbox_inv(si);
  let result : bits(32) = X(rs1)[31..0] ^ rol32(so, unsigned(shamt));
  X(rd) = EXTS(result); RETIRE_SUCCESS
}

function clause execute (AES32DSMI (bs,rs2,rs1,rd)) = {
  let shamt : bits( 5) = bs @ 0b000; // shamt = bs*8 
  let si : bits( 8) = (X(rs2)[31..0] >> shamt)[7..0]; // SBox Input 
  let so : bits( 8) = aes_sbox_inv(si);
  let mixed : bits(32) = aes_mixcolumn_byte_inv(so);
  let result : bits(32) = X(rs1)[31..0] ^ rol32(mixed, unsigned(shamt));
  X(rd) = EXTS(result); RETIRE_SUCCESS
}

function clause execute (AES32ESI (bs,rs2,rs1,rd)) = {
  let shamt : bits( 5) = bs @ 0b000; // shamt = bs*8 
  let si : bits( 8) = (X(rs2)[31..0] >> shamt)[7..0]; // SBox Input 
  let so : bits(32) = 0x000000 @ aes_sbox_fwd(si);
  let result : bits(32) = X(rs1)[31..0] ^ rol32(so, unsigned(shamt));
  X(rd) = EXTS(result); RETIRE_SUCCESS
}

function clause execute (AES32ESMI (bs,rs2,rs1,rd)) = {
  let shamt : bits( 5) = bs @ 0b000; // shamt = bs*8 
  let si : bits( 8) = (X(rs2)[31..0] >> shamt)[7..0]; // SBox Input 
  let so : bits( 8) = aes_sbox_fwd(si);
  let mixed : bits(32) = aes_mixcolumn_byte_fwd(so);
  let result : bits(32) = X(rs1)[31..0] ^ rol32(mixed, unsigned(shamt));
  X(rd) = EXTS(result); RETIRE_SUCCESS
}
*/
//-------------------------------------------------------------------------------------
module crypto_aes32
  import crypto_instr_pkg::*;
(
    input  logic [2:0]              aes32_op_i,
    input  logic [1:0]              aes32_bs_i,
    input  logic [XLEN-1:0]  aes32_rs1_i,
    input  logic [XLEN-1:0]  aes32_rs2_i,
    output logic [XLEN-1:0]  aes32_result_o
);

  logic [7:0] bytes_in [3:0];

  assign     bytes_in [0] =  aes32_rs2_i[ 7: 0];
  assign     bytes_in [1] =  aes32_rs2_i[15: 8];
  assign     bytes_in [2] =  aes32_rs2_i[23:16];
  assign     bytes_in [3] =  aes32_rs2_i[31:24];

  logic [7:0] sel_byte;
  assign sel_byte     = bytes_in[aes32_bs_i];

  logic [7:0] sbox_fwd_out;
  logic [7:0] sbox_inv_out;
  logic [7:0] sbox_out;

  riscv_crypto_aes_fwd_sbox i_aes_sbox_fwd (
  .in (sel_byte    ),
  .fx (sbox_fwd_out)
  );

  riscv_crypto_aes_inv_sbox i_aes_sbox_inv (
  .in (sel_byte    ),
  .fx (sbox_inv_out)
  );

  // Multiply by 2 in GF(2^8) modulo 8'h1b
  function [7:0] xtime2;
      input [7:0] a;

      xtime2  = {a[6:0],1'b0} ^ (a[7] ? 8'h1b : 8'b0 );

  endfunction

  // Paired down multiply by X in GF(2^8)
  function [7:0] xtimeN;
      input[7:0] a;
      input[3:0] b;

      xtimeN = 
          (b[0] ?                         a   : 0) ^
          (b[1] ? xtime2(                 a)  : 0) ^
          (b[2] ? xtime2(xtime2(          a)) : 0) ^
          (b[3] ? xtime2(xtime2(xtime2(   a))): 0) ;

  endfunction

  logic [ 7:0] mix_b3 ;
  logic [ 7:0] mix_b2 ;
  logic [ 7:0] mix_b1 ;
  logic [ 7:0] mix_b0 ;
  assign mix_b3 =                 xtimeN(sbox_out, (aes32_op_i[2] ? 11  : 3));
  assign mix_b2 = aes32_op_i[2] ? xtimeN(sbox_out, (           13)) : sbox_out ;
  assign mix_b1 = aes32_op_i[2] ? xtimeN(sbox_out, (            9)) : sbox_out ;
  assign mix_b0 =                 xtimeN(sbox_out, (aes32_op_i[2] ? 14  : 2));

  logic [31:0] result_mix;
  assign result_mix  = {mix_b3, mix_b2, mix_b1, mix_b0};

  logic [31:0] result;

  logic [31:0] rotated;
  assign rotated     =
      {32{aes32_bs_i == 2'b00}} & {result                      } |
      {32{aes32_bs_i == 2'b01}} & {result[23:0], result[31:24] } |
      {32{aes32_bs_i == 2'b10}} & {result[15:0], result[31:16] } |
      {32{aes32_bs_i == 2'b11}} & {result[ 7:0], result[31: 8] } ;

  always_comb begin
      if (aes32_op_i==5) begin                //DSI
          sbox_out = sbox_inv_out;
          result   = {24'b0, sbox_out};
          aes32_result_o = rotated ^ aes32_rs1_i;

      end else if (aes32_op_i==7) begin       //DSMI
          sbox_out = sbox_inv_out;
          result   = result_mix;
          aes32_result_o = rotated ^ aes32_rs1_i;

      end else if (aes32_op_i==1) begin       //ESI
          sbox_out = sbox_fwd_out;
          result   = {24'b0, sbox_out};
          aes32_result_o = rotated ^ aes32_rs1_i;

      end else if (aes32_op_i==3) begin       //ESMI
          sbox_out = sbox_fwd_out;
          result   = result_mix;
          aes32_result_o = rotated ^ aes32_rs1_i;

      end else begin                              //Wrong Instruction
          sbox_out = 8'b0;
          aes32_result_o = 32'b0;
      end   
  end

endmodule