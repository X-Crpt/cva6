///////////////////////////////////////////////////////////////////////
// File: crypto_sm3.sv
// Date: 2024-04-02
// Author: Behnam Farnaghinejad <behnam.farnaghinejad@polito.it>
// 
///////////////////////////////////////////////////////////////////////


//------------------------------- Sail model -------------------------------------------
/*
function clause execute (SM3P0(rs1, rd)) = {
  let r1 : bits(32) = X(rs1)[31..0];
  let result : bits(32) = r1 ^ rol32(r1, 9) ^ rol32(r1, 17);
  X(rd) = EXTS(result);
  RETIRE_SUCCESS
}

function clause execute (SM3P1(rs1, rd)) = {
  let r1 : bits(32) = X(rs1)[31..0];
  let result : bits(32) = r1 ^ rol32(r1, 15) ^ rol32(r1, 23);
  X(rd) = EXTS(result);
  RETIRE_SUCCESS
}

*/
//-------------------------------------------------------------------------------------
module crypto_sm3
  import crypto_instr_pkg::*;
(
    input  logic                    sm3_op_i,
    input  logic [XLEN-1:0]  sm3_rs1_i,
    output logic [XLEN-1:0]  sm3_result_o
);
    `define ROL32(a,b) ((a << b) | (a >> 32-b))

    logic [31:0] r1;
    assign r1 = sm3_rs1_i[31:0];

    logic [31:0] sm3_outpt;

    always_comb
    begin
        if (sm3_op_i==0) begin   //P0
            sm3_outpt       = r1 ^ `ROL32(r1,  9) ^ `ROL32(r1,  17);
            sm3_result_o    = XLEN ==64 ? {{32{sm3_outpt[31]}}, sm3_outpt} : sm3_outpt;   
        end 
        else begin              //P1
            sm3_outpt       = r1 ^ `ROL32(r1,  15) ^ `ROL32(r1,  23);
            sm3_result_o    = XLEN ==64 ? {{32{sm3_outpt[31]}}, sm3_outpt} : sm3_outpt;
        end

    end

    `undef ROL32
endmodule