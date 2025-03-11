///////////////////////////////////////////////////////////////////////
// File: crypto_sha512.sv
// Date: 2024-04-02
// Author: Behnam Farnaghinejad <behnam.farnaghinejad@polito.it>
// 
///////////////////////////////////////////////////////////////////////


//------------------------------- Sail model -------------------------------------------
/*
function clause execute (SHA512SIG0H(rs2, rs1, rd)) = {
  X(rd) = EXTS((X(rs1) >> 1) ^ (X(rs1) >> 7) ^ (X(rs1) >> 8) ^
  (X(rs2) << 31) ^ (X(rs2) << 24) );
  RETIRE_SUCCESS
}

function clause execute (SHA512SIG0L(rs2, rs1, rd)) = {
  X(rd) = EXTS((X(rs1) >> 1) ^ (X(rs1) >> 7) ^ (X(rs1) >> 8) ^
  (X(rs2) << 31) ^ (X(rs2) << 25) ^ (X(rs2) << 24) );
  RETIRE_SUCCESS
}

function clause execute (SHA512SIG1H(rs2, rs1, rd)) = {
  X(rd) = EXTS((X(rs1) << 3) ^ (X(rs1) >> 6) ^ (X(rs1) >> 19) ^
  (X(rs2) >> 29) ^ (X(rs2) << 13) );
  RETIRE_SUCCESS
}

function clause execute (SHA512SIG1L(rs2, rs1, rd)) = {
  X(rd) = EXTS((X(rs1) << 3) ^ (X(rs1) >> 6) ^ (X(rs1) >> 19) ^
  (X(rs2) >> 29) ^ (X(rs2) << 26) ^ (X(rs2) << 13) );
  RETIRE_SUCCESS
}

function clause execute (SHA512SUM0R(rs2, rs1, rd)) = {
  X(rd) = EXTS((X(rs1) << 25) ^ (X(rs1) << 30) ^ (X(rs1) >> 28) ^
  (X(rs2) >> 7) ^ (X(rs2) >> 2) ^ (X(rs2) << 4) );
  RETIRE_SUCCESS
}

function clause execute (SHA512SUM1R(rs2, rs1, rd)) = {
  X(rd) = EXTS((X(rs1) << 23) ^ (X(rs1) >> 14) ^ (X(rs1) >> 18) ^
  (X(rs2) >> 9) ^ (X(rs2) << 18) ^ (X(rs2) << 14) );
  RETIRE_SUCCESS
}

function clause execute (SHA512SIG0(rs1, rd)) = {
  X(rd) = ror64(X(rs1), 1) ^ ror64(X(rs1), 8) ^ (X(rs1) >> 7);
  RETIRE_SUCCESS
}

function clause execute (SHA512SIG1(rs1, rd)) = {
  X(rd) = ror64(X(rs1), 19) ^ ror64(X(rs1), 61) ^ (X(rs1) >> 6);
  RETIRE_SUCCESS
}

function clause execute (SHA512SUM0(rs1, rd)) = {
  X(rd) = ror64(X(rs1), 28) ^ ror64(X(rs1), 34) ^ ror64(X(rs1) ,39);
  RETIRE_SUCCESS
}

function clause execute (SHA512SUM1(rs1, rd)) = {
  X(rd) = ror64(X(rs1), 14) ^ ror64(X(rs1), 18) ^ ror64(X(rs1) ,41);
  RETIRE_SUCCESS
}

*/
//-------------------------------------------------------------------------------------
module crypto_sha512
  import crypto_instr_pkg::*;
(
    input  sha512_t                 sha512_op_i,
    input  logic [XLEN-1:0]  sha512_rs1_i,
    input  logic [XLEN-1:0]  sha512_rs2_i,
    output logic [XLEN-1:0]  sha512_result_o
);
    `define ROR(a,b) ((a >> b) | (a << XLEN-b))
    `define SRL(a,b) ((a >> b))
    `define SLL(a,b) ((a << b))

    logic [63:0] res_sha512_sig0 ;
    logic [63:0] res_sha512_sig1 ;
    logic [63:0] res_sha512_sum0 ;
    logic [63:0] res_sha512_sum1 ;

    
    logic [31:0] res_sha512_sum0r ; 
    logic [31:0] res_sha512_sum1r ;                  
    logic [31:0] res_sha512_sig0l ;          
    logic [31:0] res_sha512_sig0h ;         
    logic [31:0] res_sha512_sig1l ;          
    logic [31:0] res_sha512_sig1h ;
    


    generate
        if (XLEN ==64) begin

            always_comb 
            begin
                 res_sha512_sig0 = `ROR(sha512_rs1_i, 1) ^ `ROR(sha512_rs1_i, 8) ^`SRL(sha512_rs1_i, 7);
                 res_sha512_sig1 = `ROR(sha512_rs1_i,19) ^ `ROR(sha512_rs1_i,61) ^`SRL(sha512_rs1_i, 6);
                 res_sha512_sum0 = `ROR(sha512_rs1_i,28) ^ `ROR(sha512_rs1_i,34) ^`ROR(sha512_rs1_i,39);
                 res_sha512_sum1 = `ROR(sha512_rs1_i,14) ^ `ROR(sha512_rs1_i,18) ^`ROR(sha512_rs1_i,41);

                if (sha512_op_i==sha512_SUM0) begin
                    sha512_result_o    = res_sha512_sum0;
                end
                else if (sha512_op_i==sha512_SUM1) begin
                    sha512_result_o    = res_sha512_sum1;
                end
                else if (sha512_op_i==sha512_SIG0) begin
                    sha512_result_o    = res_sha512_sig0;
                end
                else if (sha512_op_i==sha512_SIG1) begin
                    sha512_result_o    = res_sha512_sig1;
                end
            end
        end

        else begin
            always_comb 
            begin
                 res_sha512_sum0r = `SLL(sha512_rs1_i,25)^`SLL(sha512_rs1_i,30)^`SRL(sha512_rs1_i,28)^`SRL(sha512_rs2_i, 7)^`SRL(sha512_rs2_i, 2)^`SLL(sha512_rs2_i, 4);
                 res_sha512_sum1r = `SLL(sha512_rs1_i,23)^`SRL(sha512_rs1_i,14)^`SRL(sha512_rs1_i,18)^`SRL(sha512_rs2_i, 9)^`SLL(sha512_rs2_i,18)^`SLL(sha512_rs2_i,14);  
                        
                 res_sha512_sig0l = `SRL(sha512_rs1_i, 1)^`SRL(sha512_rs1_i, 7)^`SRL(sha512_rs1_i, 8)^`SLL(sha512_rs2_i,31)^`SLL(sha512_rs2_i,25)^`SLL(sha512_rs2_i,24);           
                 res_sha512_sig0h = `SRL(sha512_rs1_i, 1)^`SRL(sha512_rs1_i, 7)^`SRL(sha512_rs1_i, 8)^`SLL(sha512_rs2_i,31)                      ^`SLL(sha512_rs2_i,24);           
                 res_sha512_sig1l = `SLL(sha512_rs1_i, 3)^`SRL(sha512_rs1_i, 6)^`SRL(sha512_rs1_i,19)^`SRL(sha512_rs2_i,29)^`SLL(sha512_rs2_i,26)^`SLL(sha512_rs2_i,13);           
                 res_sha512_sig1h = `SLL(sha512_rs1_i, 3)^`SRL(sha512_rs1_i, 6)^`SRL(sha512_rs1_i,19)^`SRL(sha512_rs2_i,29)                      ^`SLL(sha512_rs2_i,13);

                if (sha512_op_i==sha512_SUM0) begin //SUM0R
                    sha512_result_o    = res_sha512_sum0r;
                end
                else if (sha512_op_i==sha512_SUM1) begin //SUM1R
                    sha512_result_o    = res_sha512_sum1r;
                end
                else if (sha512_op_i==sha512_SIG0H) begin
                    sha512_result_o    = res_sha512_sig0h;
                end
                else if (sha512_op_i==sha512_SIG1H) begin
                    sha512_result_o    = res_sha512_sig1h;
                end
                else if (sha512_op_i==sha512_SIG0L) begin
                    sha512_result_o    = res_sha512_sig0l;
                end
                else if (sha512_op_i==sha512_SIG1L) begin
                    sha512_result_o    = res_sha512_sig1l;
                end
            end
        end

    endgenerate

    `undef SRL
    `undef SLL
    `undef ROR

endmodule