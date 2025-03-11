///////////////////////////////////////////////////////////////////////
// File: crypto_xperm.sv
// Date: 2024-04-02
// Author: Behnam Farnaghinejad <behnam.farnaghinejad@polito.it>
// 
///////////////////////////////////////////////////////////////////////

//------------------------------- Sail model -------------------------------------------
/*
val xperm8_lookup : (bits(8), xlenbits) -> bits(8)
function xperm8_lookup (idx, lut) = {
  (lut >> (idx @ 0b000))[7..0]
}
function clause execute ( XPERM_8 (rs2,rs1,rd)) = {
  result : xlenbits = EXTZ(0b0);
  foreach(i from 0 to xlen by 8) {
  result[i+7..i] = xperm8_lookup(X(rs2)[i+7..i], X(rs1));
  };
  X(rd) = result;
  RETIRE_SUCCESS
}


val xperm4_lookup : (bits(4), xlenbits) -> bits(4)
function xperm4_lookup (idx, lut) = {
  (lut >> (idx @ 0b00))[3..0]
}
function clause execute ( XPERM_4 (rs2,rs1,rd)) = {
  result : xlenbits = EXTZ(0b0);
  foreach(i from 0 to xlen by 4) {
  result[i+3..i] = xperm4_lookup(X(rs2)[i+3..i], X(rs1));
  };
  X(rd) = result;
  RETIRE_SUCCESS
}
*/
//-------------------------------------------------------------------------------------
module crypto_xperm
  import crypto_instr_pkg::*;
(
    input  logic                    xperm_op_i,
    input  logic [XLEN-1:0]  xperm_rs1_i,
    input  logic [XLEN-1:0]  xperm_rs2_i,
    output logic [XLEN-1:0]  xperm_result_o
);

    logic [7:0] temp_value_8;
    logic [3:0] temp_value_4;
    logic [XLEN-1:0]  xperm_result_xperm8;
    logic [XLEN-1:0]  xperm_result_xperm4;

    genvar i;
    generate
        if (XLEN == 64) begin : gen_64bit_xperm
            for (i = 0; i < 64; i += 8) begin
                assign temp_value_8 = {xperm_rs1_i >> {xperm_rs2_i[i+8 : i], 3'b0}};
                assign xperm_result_xperm8[i+8 : i] = temp_value_8[7:0];
            end

            for (i = 0; i < 64; i += 4) begin: loop_xperm4
                assign temp_value_4 = {xperm_rs1_i >> {xperm_rs2_i[i+3 : i], 2'b0}};
                assign xperm_result_xperm4[i+3 : i] = temp_value_4[3:0];
            end
        end else if (XLEN == 32) begin : gen_32bit_xperm
            for (i = 0; i < 32; i += 8) begin
                assign temp_value_8 = {xperm_rs1_i >> {xperm_rs2_i[i+8 : i], 3'b0}};
                assign xperm_result_xperm8[i+8 : i] = temp_value_8[7:0];
            end

            for (i = 0; i < 32; i += 4) begin
                assign temp_value_4 = {xperm_rs1_i >> {xperm_rs2_i[i+3 : i], 2'b0}};
                assign xperm_result_xperm4[i+3 : i] = temp_value_4[3:0];
            end
        end
    endgenerate

    assign xperm_result_o = xperm_op_i ? xperm_result_xperm8 : xperm_result_xperm4;
    
endmodule