///////////////////////////////////////////////////////////////////////
// File: crypto_sha256.sv
// Date: 2024-04-02
// Author: Behnam Farnaghinejad <behnam.farnaghinejad@polito.it>
// 
///////////////////////////////////////////////////////////////////////

//------------------------------- Sail model -------------------------------------------
/*
function clause execute (SHA256SIG0(rs1,rd)) = {
  let inb : bits(32) = X(rs1)[31..0];
  let result : bits(32) = ror32(inb, 7) ^ ror32(inb, 18) ^ (inb >> 3);
  X(rd) = EXTS(result);
  RETIRE_SUCCESS
}

function clause execute (SHA256SIG1(rs1,rd)) = {
  let inb : bits(32) = X(rs1)[31..0];
  let result : bits(32) = ror32(inb, 17) ^ ror32(inb, 19) ^ (inb >> 10);
  X(rd) = EXTS(result);
  RETIRE_SUCCESS
}

function clause execute (SHA256SUM0(rs1,rd)) = {
  let inb : bits(32) = X(rs1)[31..0];
  let result : bits(32) = ror32(inb, 2) ^ ror32(inb, 13) ^ ror32(inb, 22);
  X(rd) = EXTS(result);
  RETIRE_SUCCESS
}

function clause execute (SHA256SUM1(rs1,rd)) = {
  let inb : bits(32) = X(rs1)[31..0];
  let result : bits(32) = ror32(inb, 6) ^ ror32(inb, 11) ^ ror32(inb, 25);
  X(rd) = EXTS(result);
  RETIRE_SUCCESS
}
*/
//-------------------------------------------------------------------------------------
module crypto_sha256
  import crypto_instr_pkg::*;
(
    input  logic [1:0]              sha256_op_i,
    input  logic [XLEN-1:0]  sha256_rs1_i,
    output logic [XLEN-1:0]  sha256_result_o
);
    `define ROR32(a,b) ((a >> b) | (a << 32-b))
    `define SRL32(a,b) ((a >> b))

    logic [31:0] res_sha256_sum0;
    logic [31:0] res_sha256_sum1;
    logic [31:0] res_sha256_sig0;
    logic [31:0] res_sha256_sig1;

    assign res_sha256_sum0 = `ROR32(sha256_rs1_i[31:0], 2) ^ `ROR32(sha256_rs1_i[31:0],13) ^ `ROR32(sha256_rs1_i[31:0],22);
    assign res_sha256_sum1 = `ROR32(sha256_rs1_i[31:0], 6) ^ `ROR32(sha256_rs1_i[31:0],11) ^ `ROR32(sha256_rs1_i[31:0],25);
    assign res_sha256_sig0 = `ROR32(sha256_rs1_i[31:0], 7) ^ `ROR32(sha256_rs1_i[31:0],18) ^ `SRL32(sha256_rs1_i[31:0], 3);
    assign res_sha256_sig1 = `ROR32(sha256_rs1_i[31:0],17) ^ `ROR32(sha256_rs1_i[31:0],19) ^ `SRL32(sha256_rs1_i[31:0],10);

    always_comb

    begin

        if (sha256_op_i==0) begin
            sha256_result_o    = XLEN ==64 ? { {32{res_sha256_sum0[31]}}, res_sha256_sum0 } : res_sha256_sum0;
        end
        else if (sha256_op_i==1) begin
            sha256_result_o    = XLEN ==64 ? { {32{res_sha256_sum1[31]}}, res_sha256_sum1 } : res_sha256_sum1;
        end
        else if (sha256_op_i==2) begin
            sha256_result_o    = XLEN ==64 ? { {32{res_sha256_sig0[31]}}, res_sha256_sig0 } : res_sha256_sig0;
        end
        else if (sha256_op_i==3) begin
            sha256_result_o    = XLEN ==64 ? { {32{res_sha256_sig1[31]}}, res_sha256_sig1 } : res_sha256_sig1;
        end

    end
    
    `undef ROR32
    `undef SRL32

endmodule