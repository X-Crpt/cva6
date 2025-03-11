///////////////////////////////////////////////////////////////////////
// File: crypto_sm4.sv
// Date: 2024-04-02
// Author: Behnam Farnaghinejad <behnam.farnaghinejad@polito.it>
// 
///////////////////////////////////////////////////////////////////////


//------------------------------- Sail model -------------------------------------------
/*
function clause execute (SM4ED (bs,rs2,rs1,rd)) = {
  let shamt : bits(5) = bs @ 0b000; // shamt = bs*8 //
  let sb_in : bits(8) = (X(rs2)[31..0] >> shamt)[7..0];
  let x     : bits(32) = 0x000000 @ sm4_sbox(sb_in);
  let y     : bits(32) = x ^ (x << 8) ^ ( x << 2) ^
                             (x << 18) ^ ((x & 0x0000003F) << 26) ^
                             ((x & 0x000000C0) << 10);
  let z     : bits(32) = rol32(y, unsigned(shamt));
  let result: bits(32) = z ^ X(rs1)[31..0];
  X(rd) = EXTS(result);
  RETIRE_SUCCESS
}


function clause execute (SM4KS (bs,rs2,rs1,rd)) = {
  let shamt : bits(5) = (bs @ 0b000); // shamt = bs*8 //
  let sb_in : bits(8) = (X(rs2)[31..0] >> shamt)[7..0];
  let x     : bits(32) = 0x000000 @ sm4_sbox(sb_in);
  let y     : bits(32) = x ^ ((x & 0x00000007) << 29) ^ ((x & 0x000000FE) << 7) ^
                             ((x & 0x00000001) << 23) ^ ((x & 0x000000F8) << 13) ;
  let z     : bits(32) = rol32(y, unsigned(shamt));
  let result: bits(32) = z ^ X(rs1)[31..0];
  X(rd) = EXTS(result);
  RETIRE_SUCCESS
}
*/
//-------------------------------------------------------------------------------------
module crypto_sm4
  import crypto_instr_pkg::*;
(
    input  logic                    sm4_op_i,
    input  logic [1:0]              sm4_bs_i,
    input  logic [XLEN-1:0]  sm4_rs1_i,
    input  logic [XLEN-1:0]  sm4_rs2_i,
    output logic [XLEN-1:0]  sm4_result_o
);

    logic [31:0] result ;

    logic [7:0] in_bytes [3:0];

    assign in_bytes[0]  = sm4_rs2_i[ 7: 0];
    assign in_bytes[1]  = sm4_rs2_i[15: 8];
    assign in_bytes[2]  = sm4_rs2_i[23:16];
    assign in_bytes[3]  = sm4_rs2_i[31:24];

    logic [ 7:0] sbox_in;
    assign sbox_in = in_bytes[sm4_bs_i];

    logic [ 7:0] sbox_out;
    // Submodule - SBox
    riscv_crypto_sm4_sbox i_sm4_sbox (
        .in (sbox_in ),
        .out(sbox_out)
    );

    logic [31:0] x;
    assign x       = {24'b0, sbox_out};

    // ed Instruction
    logic [31:0] y1 ;
    assign y1  = x  ^  (x            <<  8) ^  (x            << 2) ^  
                       (x            << 18) ^ ((x & 32'h3F) << 26) ^ 
                      ((x  & 32'hC0) << 10);

    // ks Instruction
    logic [31:0] y2 ;
    assign y2  = x  ^ ((x  &  32'h7) << 29) ^ ((x & 32'hFE) <<  7) ^  
                      ((x  & 32'h01) << 23) ^ ((x & 32'hF8) << 13);


    // Rotate and XOR result
    logic [31:0] rot_in ;
    assign rot_in  = sm4_op_i ? y2 : y1;

    logic [31:0] rot_out ;
    assign rot_out     =
        {32{sm4_bs_i == 2'b00}} & {rot_in                      } |
        {32{sm4_bs_i == 2'b01}} & {rot_in[23:0], rot_in[31:24] } |
        {32{sm4_bs_i == 2'b10}} & {rot_in[15:0], rot_in[31:16] } |
        {32{sm4_bs_i == 2'b11}} & {rot_in[ 7:0], rot_in[31: 8] } ;
        
    assign      result      = rot_out ^ sm4_rs1_i[31:0] ;
    assign      sm4_result_o      = XLEN ==64 ? { {32{result[31]}}, result } : result;

endmodule